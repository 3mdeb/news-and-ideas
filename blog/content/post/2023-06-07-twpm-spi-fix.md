---
title: Using SPI slave on STM32L476 platform.
abstract: 'Abstract first sentence.
          Abstract second sentence.
          Abstract third sentence.'
cover: /covers/image-file.png
author: artur.kowalski
layout: post
published: true
date: 2023-06-07
archives: "2023"

tags:
  - spi
categories:
  - Firmware
  - IoT
  - Miscellaneous
  - OS Dev
  - App Dev
  - Security
  - Manufacturing

---

STM32 MCUs come with various peripherals, one of them is SPI (Serial Peripheral
Interface) which is a simple serial bus interface commonly used for
short-distance communication between various devices. SPI is one of the
interfaces used by TPM chips for communication with PC motherboard. SPI uses 4
lines for communication: MOSI, MISO, SCK, SS, which are described down below.

For the device to work as a TPM module, it must implement TPM protocol. TPM
protocol works by transmitting variable-length frames over SPI, 4-byte TPM
header contains length of data payload as well transfer direction (read or
write). Another important feature of TPM protocol are the wait states - SPI
slave can hold transmittion by pulling MISO line down.

TODO: TPM header image

TPMs typically operate at frequency up to 24 MHz, this is also the maximum
frequency required by the PTP spec (TBD: link, describe what is PPT spec). Such
a high frequency as well as non-standard SPI features - wait-states and
variable-length frames pose a significant challenge, neither the platform we are
using is the easy one.

## Limitations of STM32L476

STM32L476 has SPI capable of frequencies up to a (theoretical) limit of 40 MHz
which is a half of maximum clock that can be provided to Cortex-M and AHB/APB
buses. There are other limiting factors such as maximum GPIO speed, DMA transfer
speed and performance of the firmware itself.

## Creating SPI slave on Zephyr

Zephyr provides support for SPI master, and experimental support for SPI slave.
From earlier tests which I will not describe here, I can tell that SPI slave
works at frequencies up to 100 KHz and becomes unstable at higher frequencies.

For further tests, I will a create simple application that sends some random
data:

```c
const struct device *spi_dev = NULL;
struct spi_config spi_cfg = {
	.frequency = 25000000,
	.operation = SPI_WORD_SET(8) | SPI_TRANSFER_MSB | SPI_OP_MODE_SLAVE,
};

const uint8_t testdata[32] = {
	0x3d, 0x7f, 0x85, 0xc3, 0x86, 0x2f, 0x14, 0x2a, 0xa2, 0x67, 0x1d, 0xd7, 0xfa, 0xa8, 0x3a, 0x42,
	0xf8, 0x12, 0xd2, 0xa1, 0x04, 0xcc, 0xe2, 0xc6, 0x78, 0x73, 0x09, 0xe6, 0xd8, 0xc5, 0x0e, 0xba,
};

void main(void) {
	spi_dev = device_get_binding(DEVICE_DT_NAME(DT_NODELABEL(spi2)));
	if (!device_is_ready(spi_dev)) {
		printk("SPI controller is not ready!\n");
		return;
	}

	struct spi_buf spi_tx_buf = {
		.buf = (void *)testdata,
		.len = sizeof testdata,
	};

	struct spi_buf_set spi_tx_buf_set = {
		.buffers = &spi_tx_buf,
		.count = 1,
	};

	while (true) {
		int ret = spi_write(spi_dev, &spi_cfg, &spi_tx_buf_set);
		if (ret < 0)
			printk("spi_write failed: %d\n", ret);
		else
			printk("spi transfer complete\n");
	}
}
```

We enable support SPI slave and DMA.

```shell
CONFIG_GPIO=y
CONFIG_SPI=y
CONFIG_SPI_SLAVE=y
CONFIG_SPI_STM32_DMA=y
```

And configure DMA channels:

```shell
&dma1 {
	status = "okay";
};

&spi1 {
	status = "disabled";
};

&spi2 {
	/*
	 * See https://docs.zephyrproject.org/3.0.0/reference/devicetree/bindings/dma/st%2Cstm32-dma-v2.html
	 */
	dmas = <&dma1 5 1 0x20440>,
	       <&dma1 4 1 0x20480>;
	dma-names = "tx", "rx";
};

&spi3 {
	status = "disabled";
};
```

If we run this code we will see SPI errors running down the console:

```shell
spi_write failed: -11
spi_write failed: -11
spi_write failed: -11
spi_write failed: -11
spi_write failed: -11
```

The problem is a timeout - the driver waits 1 second for transfer to complete
and then fails. While this is a desirable behaviour for SPI master, it is not
desirable for slave. Master itself decides when data is transmitted, so when
transfer doesn't complete in reasonable time, for sure there is something wrong.
Slave must wait for master to start data transmission, which could take any
time. Right now, we are stuck in endless loop, where transfer is queued,
aborted, then queued again.

To fix the problem, we can modify `wait_dma_rx_tx_done` in `spi_ll_tm32.c`, the
origin function looks like this:

```c
static int wait_dma_rx_tx_done(const struct device *dev)
{
	struct spi_stm32_data *data = dev->data;
	int res = -1;

	while (1) {
		res = k_sem_take(&data->status_sem, K_MSEC(1000));
		if (res != 0) {
			return res;
		}
...
```

The problem lies in the call to `k_sem_take`, just replace `K_MSEC(1000)` with
`K_FOREVER`.

Now running `spitest` at 100 KHz yields the following result:

![STM32 SPI slave at 100 KHz](/img/stm32-spislave-100khz.png)

The transfer works properly at 100 KHz. At 10 MHz the transfers sometimes works,
sometimes does not:

![STM32 SPI slave at 10 MHz](/img/stm32-spislave-10mhz.png)

At 24 MHz transfer is corrupted most of the time.

## The SPE bit problem

I've been searching through STM32 documentation for information about high-speed
SPI, the most helpful were the STM32L4 series programming manual and
[AN5543](https://www.st.com/resource/en/application_note/an5543-enhanced-methods-to-handle-spi-communication-on-stm32-devices-stmicroelectronics.pdf).

SPE bit stands for SPI Enable. Without enabling SPI, no transaction will occur.
[AN5543](https://www.st.com/resource/en/application_note/an5543-enhanced-methods-to-handle-spi-communication-on-stm32-devices-stmicroelectronics.pdf)
section 4.2 describes various aspects of handling communication, most important
is the section 4.2.2 which describes what happens when SPI is disabled.

> SPI versions 1.x.x: the peripheral takes no control of the associated GPIOs
> when it is disabled. The SPI signals float if they are not supported by
> external resistor and if they are not reconfigured and they are kept at
> alternate function configuration.

> At principle, the SPI must not be disabled before the communication is fully
> completed and it should be as short as possible at slave, especially between
> sessions, to avoid missing any communication.

The main problem here is that Zephyr (as well as STM32 HAL) re-configures SPI
before each transaction, doing configure-enable-transmit-disable cycle on each
SPI session. While this is ok for master, slave must respect timings imposed
by master, so SPI disabling should be avoided if not needed.

The problem becomes even more pronounced when we want to implement TPM protocol
as we don't know size (and direction) of data payload. Each TPM frame starts
with a 4 byte header which tells us what is the size of transfer and what is the
direction (read from or write to a register). After we read the header, we
disable SPI, causing a few things:

- MISO is left floating (we have SPI v1.3 on STM32L4)
- we introduce additional delay by re-configuring SPI

## Fixing SPI

I will do initial work using HAL and STM32CubeIDE, at a later stage I will port
that to Zephyr. I create a new STM32CubeMX project the proceed to setting up
SPI2 controller through graphical configuration manager. Basic settings involve
configuring SPI as `Full-Duplex Slave`, configuring NSS (Chip Select) pin as
input, setting up DMA channels and setting SPI frame length to 8 bits (as
required by TPM spec):

![](/img/stm32cube_spi2_setup.png)

![](/img/stm32cube_spi_setup_dma.png)

STM32CubeMX generates code that performs hardware initialization, including SPI.
We are ready to do SPI transactions using `HAL_SPI_TransmitReceive_DMA`
function. Of course that would give the same result as Zephyr does, instead I'm
going to roll my own implementation.

But, first, let's look at `HAL_SPI_TransmitReceive_DMA` implementation:

```c
HAL_StatusTypeDef HAL_SPI_TransmitReceive_DMA(SPI_HandleTypeDef *hspi, uint8_t *pTxData, uint8_t *pRxData, uint16_t Size)
{
  ...

  /* Reset the threshold bit */
  CLEAR_BIT(hspi->Instance->CR2, SPI_CR2_LDMATX | SPI_CR2_LDMARX);

  /* The packing mode management is enabled by the DMA settings according the spi data size */
  if (hspi->Init.DataSize > SPI_DATASIZE_8BIT)
  {
    /* Set fiforxthreshold according the reception data length: 16bit */
    CLEAR_BIT(hspi->Instance->CR2, SPI_RXFIFO_THRESHOLD);
  }
  else
  {
    /* Set RX Fifo threshold according the reception data length: 8bit */
    SET_BIT(hspi->Instance->CR2, SPI_RXFIFO_THRESHOLD);

    if (hspi->hdmatx->Init.MemDataAlignment == DMA_MDATAALIGN_HALFWORD)
    {
      if ((hspi->TxXferSize & 0x1U) == 0x0U)
      {
        CLEAR_BIT(hspi->Instance->CR2, SPI_CR2_LDMATX);
        hspi->TxXferCount = hspi->TxXferCount >> 1U;
      }
      else
      {
        SET_BIT(hspi->Instance->CR2, SPI_CR2_LDMATX);
        hspi->TxXferCount = (hspi->TxXferCount >> 1U) + 1U;
      }
    }

    if (hspi->hdmarx->Init.MemDataAlignment == DMA_MDATAALIGN_HALFWORD)
    {
      /* Set RX Fifo threshold according the reception data length: 16bit */
      CLEAR_BIT(hspi->Instance->CR2, SPI_RXFIFO_THRESHOLD);

      if ((hspi->RxXferCount & 0x1U) == 0x0U)
      {
        CLEAR_BIT(hspi->Instance->CR2, SPI_CR2_LDMARX);
        hspi->RxXferCount = hspi->RxXferCount >> 1U;
      }
      else
      {
        SET_BIT(hspi->Instance->CR2, SPI_CR2_LDMARX);
        hspi->RxXferCount = (hspi->RxXferCount >> 1U) + 1U;
      }
    }
  }

  /* Check if we are in Rx only or in Rx/Tx Mode and configure the DMA transfer complete callback */
  if (hspi->State == HAL_SPI_STATE_BUSY_RX)
  {
    /* Set the SPI Rx DMA Half transfer complete callback */
    hspi->hdmarx->XferHalfCpltCallback = SPI_DMAHalfReceiveCplt;
    hspi->hdmarx->XferCpltCallback     = SPI_DMAReceiveCplt;
  }
  else
  {
    /* Set the SPI Tx/Rx DMA Half transfer complete callback */
    hspi->hdmarx->XferHalfCpltCallback = SPI_DMAHalfTransmitReceiveCplt;
    hspi->hdmarx->XferCpltCallback     = SPI_DMATransmitReceiveCplt;
  }

  /* Set the DMA error callback */
  hspi->hdmarx->XferErrorCallback = SPI_DMAError;

  /* Set the DMA AbortCpltCallback */
  hspi->hdmarx->XferAbortCallback = NULL;

  /* Enable the Rx DMA Stream/Channel  */
  if (HAL_OK != HAL_DMA_Start_IT(hspi->hdmarx, (uint32_t)&hspi->Instance->DR, (uint32_t)hspi->pRxBuffPtr,
                                 hspi->RxXferCount))
  {
    /* Update SPI error code */
    SET_BIT(hspi->ErrorCode, HAL_SPI_ERROR_DMA);
    errorcode = HAL_ERROR;

    hspi->State = HAL_SPI_STATE_READY;
    goto error;
  }

  /* Enable Rx DMA Request */
  SET_BIT(hspi->Instance->CR2, SPI_CR2_RXDMAEN);

  /* Set the SPI Tx DMA transfer complete callback as NULL because the communication closing
  is performed in DMA reception complete callback  */
  hspi->hdmatx->XferHalfCpltCallback = NULL;
  hspi->hdmatx->XferCpltCallback     = NULL;
  hspi->hdmatx->XferErrorCallback    = NULL;
  hspi->hdmatx->XferAbortCallback    = NULL;

  /* Enable the Tx DMA Stream/Channel  */
  if (HAL_OK != HAL_DMA_Start_IT(hspi->hdmatx, (uint32_t)hspi->pTxBuffPtr, (uint32_t)&hspi->Instance->DR,
                                 hspi->TxXferCount))
  {
    /* Update SPI error code */__HAL_SPI_ENABLE
    SET_BIT(hspi->ErrorCode, HAL_SPI_ERROR_DMA);
    errorcode = HAL_ERROR;

    hspi->State = HAL_SPI_STATE_READY;
    goto error;
  }

  /* Check if the SPI is already enabled */
  if ((hspi->Instance->CR1 & SPI_CR1_SPE) != SPI_CR1_SPE)
  {
    /* Enable SPI peripheral */
    __HAL_SPI_ENABLE(hspi);
  }
  /* Enable the SPI Error Interrupt Bit */
  __HAL_SPI_ENABLE_IT(hspi, (SPI_IT_ERR));

  /* Enable Tx DMA Request */
  SET_BIT(hspi->Instance->CR2, SPI_CR2_TXDMAEN);

  ...
}
```

What this code does:

- Initialize some callbacks (like transfer complete callbacks)
- Configure some SPI registers (note that registers are written each time, but
  some don't have to be)
- Initialize DMA channel and enables DMA on SPI controller (RXDMAEN and TXDMAEN
  bits)
- Enable SPI interrupts
- Enable SPI controller

Callbacks handle end of transaction event which involves waiting for SPI to
become idle, while generally this is a desirable behaviour, it is not in that
case. As mentioned before, we need to read 4 byte header, which contains
information such as transfer direction (read or write) and data length. Waiting
for SPI to become idle introduces additional overhead.

I created a stripped-down version of `HAL_SPI_TransmitReceive_DMA`:

```c
static uint8_t tx_buf[4] = {0xaa, 0xe0, 0xbb, 0xa5};
static uint8_t rx_buf[4] = {0};

static void rxdma_complete(DMA_HandleTypeDef *hdma)
{
	SPI_HandleTypeDef *hspi = (SPI_HandleTypeDef *)(((DMA_HandleTypeDef *)hdma)->Parent);
	HAL_DMA_Start_IT(hspi->hdmarx, (uint32_t)&hspi->Instance->DR, (uint32_t)rx_buf, 4);
}

static void txdma_complete(DMA_HandleTypeDef *hdma)
{
	SPI_HandleTypeDef *hspi = (SPI_HandleTypeDef *)(((DMA_HandleTypeDef *)hdma)->Parent);
	HAL_DMA_Start_IT(hspi->hdmatx, (uint32_t)tx_buf, (uint32_t)&hspi->Instance->DR, 4);
}

void app_main() {
	SPI_HandleTypeDef *hspi = &hspi2;

	// Initialize callbacks
	hspi->hdmatx->XferCpltCallback = txdma_complete;
	hspi->hdmarx->XferCpltCallback = rxdma_complete;

	// One-time SPI configuration
	// Clear SPI_RXFIFO_THRESHOLD to trigger DMA on each byte available.
	CLEAR_BIT(hspi->Instance->CR2, SPI_RXFIFO_THRESHOLD);

	// Start the transfer
	SET_BIT(hspi->Instance->CR2, SPI_CR2_RXDMAEN);
	HAL_DMA_Start_IT(hspi->hdmarx, (uint32_t)&hspi->Instance->DR, (uint32_t)rx_buf, 4);

	HAL_DMA_Start_IT(hspi->hdmatx, (uint32_t)tx_buf, (uint32_t)&hspi->Instance->DR, 4);
	SET_BIT(hspi->Instance->CR2, SPI_CR2_TXDMAEN);

	__HAL_SPI_ENABLE(hspi);
}
```

We reduced the code used to almost a minimum (still some optimizations could be
done in `HAL_DMA_Start_IT`). The code lacks most features, such as SPI error
detection (those will be added later on), and we transfer only a single, static
data. DMA is restarted directly from interrupt handler, we only reprogram the
channel, we don't touch any SPI registers. Please note that I'm using a bit
different initialization order than originally done by HAL. We first enable
`RXDMAEN`, then, program DMA channels, enable `TXDMAEN` and finally enable SPI.
HAL enables `RXDMAEN` after programming RX channel and `TXDMAEN` after enabling
SPI. Our code follows what has been stated in the STM32 Programming Manual
(**rm0351**):

![](/img/rm0351_spi_dma_enable_procedure.png)

For testing purposes, I am using Raspberry PI 3B as SPI host. Configuration is
pretty straightforward, you can enable `spidev` by uncommenting
`dtoverlay=spi0-1cs` in `/boot/config.txt` and rebooting. For communicating with
`spidev` I am using a custom Python script:

```python
from spidev import SpiDev

class Spi:
    def __init__(self):
        self.device = SpiDev()
        self.device.open(0, 0)
        self.device.bits_per_word = 8
        self.device.mode = 0b00
        self.device.max_speed_hz = 24000000
        self.freq = 24000000

    def get_frequency(self):
        return self.freq

    def set_frequency(self, freq):
        self.freq = freq

    def xfer(self, data: bytes) -> bytes:
        return self.device.xfer(data, self.freq)


def test(func):
    def wrapper():
        freq = spi.freq
        iteration = 0

        try:
            for i in range(10):
                iteration = i
                func()
            print(f'OK: {func.__name__} @ {freq} Hz')
        except AssertionError:
            print(f'FAIL: {func.__name__} @ {freq} Hz (iteration {iteration})')
    return wrapper


@test
def test_read_constant_4byte():
    expected_data = [0xaa, 0xe0, 0xbb, 0xa5]
    result = spi.xfer([0xff] * len(expected_data))
    print('result = {:x} {:x} {:x} {:x}'.format(result[0], result[1], result[2], result[3]))
    assert result == expected_data


def main():
    global spi

    try:
        spi = Spi()
        spi.set_frequency(24000000)
        test_read_constant_4byte()
    finally:
        spi.device.close()

if __name__ == '__main__':
    main()
```

When I ran the test code I could see through logic analyzer the transmitted data
was correct, however Raspberry PI did not receive correct data. This quickly
turned out to be a problem with connection between RPI and Nucleo. Previously
I've been using two jumper-wire cables for each pin, those cables were connected
to breadboard together with logic analyzer. Now I'm using single cable, and I
can reach stable 22 MHz (contrary to stable 18 MHz on old cables), 24 MHz is
mostly stable but sometimes problems occur, if I connect logic analyzer 24 Mhz
becomes broken completely.

## Extending tests

I could achieve 22 Mhz frequency, while this is not the target I aim for, I
deciced to continue tests on lower frequency, for now (hoping that better cables
will make the problem go away). I extended MCU code to speak over a TPM-like
protocol.

```c
#define STATE_WAIT_HEADER 0
#define STATE_WAIT_STATE 1
#define STATE_WAIT_STATE_LAST 2
#define STATE_PAYLOAD_TRANSFER 3

static uint8_t ff_buffer[64];
static uint8_t waitstate_insert[4] = {0xff, 0xff, 0xff, 0xfe};
static uint8_t waitstate_hold[1] = {0x00};

static uint8_t waitstate_cancel[1] = {0x01};
static uint8_t trash[1] = {0};
static uint8_t header[4] = {0};
static bool b_txdma_complete = false;
static bool b_rxdma_complete = false;
static uint8_t state = STATE_WAIT_HEADER;

static uint8_t scratch_buffer[64] = {0};

static uint8_t transfer_is_read = 0;
static uint32_t transfer_length = 0;

static void update_state(SPI_HandleTypeDef *hspi)
{
	b_rxdma_complete = false;
	b_txdma_complete = false;

	switch (state) {
	case STATE_WAIT_HEADER:
		// We don't care what host sends during wait state, but we start DMA anyway to avoid overrun errors.
		HAL_DMA_Start_IT(hspi->hdmarx, (uint32_t)&hspi->Instance->DR, (uint32_t)trash, sizeof trash);
		// Wait state got inserted while reading header.
		HAL_DMA_Start_IT(hspi->hdmatx, (uint32_t)waitstate_cancel, (uint32_t)&hspi->Instance->DR, sizeof waitstate_cancel);

    // This follows a real TPM protocol, except we ignore addr currently.
		transfer_is_read = !!(header[0] & (1 << 7));
		transfer_length = (header[0] & 0x3f) + 1;

		state = STATE_WAIT_STATE_LAST;
		break;

	case STATE_WAIT_STATE_LAST:
		if (transfer_is_read) {
			HAL_DMA_Start_IT(hspi->hdmatx, (uint32_t)scratch_buffer, (uint32_t)&hspi->Instance->DR, transfer_length);
			HAL_DMA_Start_IT(hspi->hdmarx, (uint32_t)&hspi->Instance->DR, (uint32_t)ff_buffer, transfer_length);
		} else {
			HAL_DMA_Start_IT(hspi->hdmatx, (uint32_t)ff_buffer, (uint32_t)&hspi->Instance->DR, transfer_length);
			HAL_DMA_Start_IT(hspi->hdmarx, (uint32_t)&hspi->Instance->DR, (uint32_t)scratch_buffer, transfer_length);
		}

		state = STATE_PAYLOAD_TRANSFER;
		break;

	case STATE_PAYLOAD_TRANSFER:
		HAL_DMA_Start_IT(hspi->hdmarx, (uint32_t)&hspi->Instance->DR, (uint32_t)header, sizeof header);
		HAL_DMA_Start_IT(hspi->hdmatx, (uint32_t)waitstate_insert, (uint32_t)&hspi->Instance->DR, sizeof waitstate_insert);

		state = STATE_WAIT_HEADER;
		break;
	}
}

static void rxdma_complete(DMA_HandleTypeDef *hdma)
{
	SPI_HandleTypeDef *hspi = (SPI_HandleTypeDef *)(((DMA_HandleTypeDef *)hdma)->Parent);
	if (b_txdma_complete)
		update_state(hspi);
	else
		b_rxdma_complete = true;
}

static void txdma_complete(DMA_HandleTypeDef *hdma)
{
	SPI_HandleTypeDef *hspi = (SPI_HandleTypeDef *)(((DMA_HandleTypeDef *)hdma)->Parent);
	if (b_rxdma_complete)
		update_state(hspi);
	else
		b_txdma_complete = true;
}
```

On Python side I introduce a new function:

```python
def tpm_read(size: int) -> bytes:
    assert size > 0 and size <= 64

    header = bytes([
        (1 << 7) | (size - 1),
        0, 0, 0
    ])

    waitstate = spi.xfer(header)
    assert waitstate == [0xff, 0xff, 0xff, 0xfe]

    while True:
        status = spi.xfer([0])
        if status[0] == 1:
            break
        assert status[0] == 0

    empty = [0] * size
    return spi.xfer(empty)
```

And update the test:

```python
@test
def test_read():
    x = tpm_read(0, 8)
    assert x == [0] * 8
```

After running the test code I immediatelly got an error, logic analyzer shows
this:

![](/img/stm32-spi-failure.png)

I can see here two problems: the first problem is that MISO goes high between
header, wait states and payload (MISO high in the middle of a transfer cancels
the transfers). The second, far worse problem, is that Nucleo transmits wrong
data (0xff) instead of (0x01).

To solve the problem I went a step back, I hardcoded a few data patterns to
replicate transfer sequence:

```c
struct pattern {
	uint8_t *data;
	uint8_t len;
};

#define ARRAY_SIZE(x) (sizeof((x)) / sizeof((x)[0]))

static uint8_t pattern_0[] = {0xff, 0xff, 0xff, 0xfe};
static uint8_t pattern_1[] = {1};
static uint8_t pattern_2[] = {
	0x3e, 0x60, 0xc3, 0x4f, 0x35, 0x2e, 0xa6, 0xaa, 0xa6, 0x61, 0x64, 0xcb,
	0x10, 0xd7, 0x45, 0x35, 0x82, 0xc9, 0x91, 0xbc, 0x35, 0x43, 0xbb, 0xe1,
	0xea, 0x08, 0xdf, 0xdd, 0x4d, 0xd8, 0xd5, 0x94, 0x71, 0x75, 0xfd, 0x23,
	0x24, 0xf8, 0x95, 0x85, 0x7b, 0x11, 0xf9, 0xdd, 0xa0, 0xaa, 0x60, 0xc5,
	0xd2, 0x07, 0x6b, 0x3a, 0xd4, 0xd2, 0xac, 0xac, 0x1b, 0x54, 0xfe, 0x2f,
	0xa2
};

static struct pattern patterns[] = {
	{ .data = pattern_0, .len = sizeof pattern_0 },
	{ .data = pattern_1, .len = sizeof pattern_1 },
	{ .data = pattern_2, .len = sizeof pattern_2 },
};
int current_pattern = 1;

static void txdma_complete(DMA_HandleTypeDef *hdma)
{
	SPI_HandleTypeDef *hspi = (SPI_HandleTypeDef *)(((DMA_HandleTypeDef *)hdma)->Parent);
	HAL_DMA_Start_IT(hspi->hdmatx, (uint32_t)patterns[current_pattern].data, (uint32_t)&hspi->Instance->DR, patterns[current_pattern].len);

	if (++current_pattern == ARRAY_SIZE(patterns))
		current_pattern = 0;
}

void app_main() {
	hspi->hdmatx->XferCpltCallback = txdma_complete;

	HAL_DMA_Start_IT(hspi->hdmatx, (uint32_t)pattern_0, (uint32_t)&hspi->Instance->DR, sizeof pattern_0);
	SET_BIT(hspi->Instance->CR2, SPI_CR2_TXDMAEN);

	__HAL_SPI_ENABLE(hspi);
}
```

And on Python side:

```python
patterns = [
    [0xff, 0xff, 0xff, 0xfe],
    [0x01],
    [
        0x3e, 0x60, 0xc3, 0x4f, 0x35, 0x2e, 0xa6, 0xaa, 0xa6, 0x61, 0x64, 0xcb,
        0x10, 0xd7, 0x45, 0x35, 0x82, 0xc9, 0x91, 0xbc, 0x35, 0x43, 0xbb, 0xe1,
        0xea, 0x08, 0xdf, 0xdd, 0x4d, 0xd8, 0xd5, 0x94, 0x71, 0x75, 0xfd, 0x23,
        0x24, 0xf8, 0x95, 0x85, 0x7b, 0x11, 0xf9, 0xdd, 0xa0, 0xaa, 0x60, 0xc5,
        0xd2, 0x07, 0x6b, 0x3a, 0xd4, 0xd2, 0xac, 0xac, 0x1b, 0x54, 0xfe, 0x2f,
        0xa2
    ]
]

spi = Spi()
spi.set_frequency(22000000)

for i in range(100000):
    for pattern in patterns:
        data = spi.xfer([0] * len(pattern))
        print(f'iter {i} test {data} == {pattern}')
        assert data == pattern
```

The code works just fine (100k iterations)

```
...
iter 99999 test [255, 255, 255, 254] == [255, 255, 255, 254]
iter 99999 test [1] == [1]
iter 99999 test [62, 96, 195, 79, 53, 46, 166, 170, 166, 97, 100, 203, 16, 215, 69, 53, 130, 201, 145, 188, 53, 67, 187, 225, 234, 8, 223, 221, 77, 216, 213, 148, 113, 117, 253, 35, 36, 248, 149, 133, 123, 17, 249, 221, 160, 170, 96, 197, 210, 7, 107, 58, 212, 210, 172, 172, 27, 84, 254, 47, 162] == [62, 96, 195, 79, 53, 46, 166, 170, 166, 97, 100, 203, 16, 215, 69, 53, 130, 201, 145, 188, 53, 67, 187, 225, 234, 8, 223, 221, 77, 216, 213, 148, 113, 117, 253, 35, 36, 248, 149, 133, 123, 17, 249, 221, 160, 170, 96, 197, 210, 7, 107, 58, 212, 210, 172, 172, 27, 84, 254, 47, 162]
```

The main difference is that the full code performs both read and write, contrary
to only writing. Currently we wait for both TX and RX DMA to complete before
re-programming DMA channels and updating state machine. TX and RX are always
the same size, so should complete with a similar time. So, instead of using
interrupts for both channels I changed the code so that interrupts are used for
TX, and polling for RX.

```c
static void txdma_complete(DMA_HandleTypeDef *hdma)
{
	SPI_HandleTypeDef *hspi = (SPI_HandleTypeDef *)(((DMA_HandleTypeDef *)hdma)->Parent);

	switch (state) {
	case STATE_WAIT_HEADER:
		// Wait state got inserted while reading header.
		HAL_DMA_Start_IT(hspi->hdmatx, (uint32_t)waitstate_cancel, (uint32_t)&hspi->Instance->DR, sizeof waitstate_cancel);

		// We don't care what host sends during wait state, but we start DMA anyway to avoid overrun errors.
		HAL_DMA_PollForTransfer(hspi->hdmarx, HAL_DMA_FULL_TRANSFER, HAL_MAX_DELAY);
		HAL_DMA_Start_IT(hspi->hdmarx, (uint32_t)&hspi->Instance->DR, (uint32_t)trash, sizeof trash);

		transfer_is_read = !!(header[0] & (1 << 7));
		transfer_length = (header[0] & 0x3f) + 1;

		state = STATE_WAIT_STATE_LAST;
		break;

	case STATE_WAIT_STATE_LAST:
		if (transfer_is_read) {
			HAL_DMA_Start_IT(hspi->hdmatx, (uint32_t)scratch_buffer, (uint32_t)&hspi->Instance->DR, transfer_length);
			HAL_DMA_PollForTransfer(hspi->hdmarx, HAL_DMA_FULL_TRANSFER, HAL_MAX_DELAY);
			HAL_DMA_Start_IT(hspi->hdmarx, (uint32_t)&hspi->Instance->DR, (uint32_t)ff_buffer, transfer_length);
		} else {
			HAL_DMA_Start_IT(hspi->hdmatx, (uint32_t)ff_buffer, (uint32_t)&hspi->Instance->DR, transfer_length);
			HAL_DMA_PollForTransfer(hspi->hdmarx, HAL_DMA_FULL_TRANSFER, HAL_MAX_DELAY);
			HAL_DMA_Start_IT(hspi->hdmarx, (uint32_t)&hspi->Instance->DR, (uint32_t)scratch_buffer, transfer_length);
		}

		state = STATE_PAYLOAD_TRANSFER;
		break;

	case STATE_PAYLOAD_TRANSFER:
		HAL_DMA_Start_IT(hspi->hdmatx, (uint32_t)waitstate_insert, (uint32_t)&hspi->Instance->DR, sizeof waitstate_insert);
		HAL_DMA_PollForTransfer(hspi->hdmarx, HAL_DMA_FULL_TRANSFER, HAL_MAX_DELAY);
		HAL_DMA_Start_IT(hspi->hdmarx, (uint32_t)&hspi->Instance->DR, (uint32_t)header, sizeof header);

		state = STATE_WAIT_HEADER;
		break;
	}
}
```

Note that I start TX transfer first, then poll for RX DMA completion before
re-programming DMA channel. Now, the test succeeds.

## Extending tests

I have basic code that can read and write data over SPI, but so far I have
tested only read of zeroed registers. Now, it is time to extends the tests, so
that we write random data of random lengths, then read the data back and check
whether it is as expected.

I started with something simple

```python
tpm_write(0, bytes([1,2,3,4,5,6,7,8]))
x = tpm_read(0, 8)
assert x == [1,2,3,4,5,6,7,8]
```

and failed:

![](/img/stm32-spi-failed-second-transfer.png)

It turned out that I incorrectly cleared `SPI_RXFIFO_THRESHOLD` bit, which
should be set for 8-bit frame length. This was causing RXDMA to not complete
under some circumstances, freezing the application.

Changing

```c
CLEAR_BIT(hspi->Instance->CR2, SPI_RXFIFO_THRESHOLD);
```

to

```c
SET_BIT(hspi->Instance->CR2, SPI_RXFIFO_THRESHOLD);
```

solved the problem, however I got another one.

![](/img/stm32-spi-readback-wrong-data.png)

Wait state is properly inserted and terminated, but payload is not valid. I
split the test into two so that I can do pause the app between write and read
from the register. Peeking at the `scratch_buffer` reveals that DMA went wrong
as first three bytes were completely lost.

![](/img/stm32-scratch-state.png)

What's more, we are once again stuck polling for DMA completion (DMA is still
waiting for remaining three bytes). The issue could possibly be caused by too
high delays between restarting of DMA transfers, so I lowered SPI frequency down
to 100 KHz, but to my surprise, the result was exactly the same. I tested
different data sizes and the result is always the same (3 bytes lost).

## Summary

That would be everything for this blogpost. I got SPI working at frequency up to
24 MHz for writes (from Nucleo) which is a great improvement compared to Zephyr
or high-level HAL implementation. Unfortunatelly, reads are currently broken
regardless of frequency due to some problems with DMA. Further work will
include:

- fixing of DMA transfer problems
- improving of transfer handling logic, error detection
- chip select status detection, error recovery
- SPI bus aborts
- porting of solution to Zephyr and possibly upstreaming it
