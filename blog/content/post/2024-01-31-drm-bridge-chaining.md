---
title: Diving deep into Linux DRM bridge chaining.
abstract: 'The post describes the story of implementing bridge-chaining using
           the DRM/KMS Linux Kernel system on an embedded device with i.mx8mmini
           SoC.'
cover: /covers/drm-kms.png
author: daniil.klimuk
layout: post
published: true
date: 2024-01-30
archives: "2024"

tags:
  - linux
  - i.mx8
  - open-source
  - DRM
  - KMS
  - graphics
categories:
  - Firmware
  - Miscellaneous

---

## Introduction

Here are very popular schematics:

![old-new-linux-graphics-stack](/img/old-new-linux-graphics-stack.png)

It shows in a simple and clear way the Linux Kernel Graphics Stack structure
before and after September 2009 when the DRM system was introduced. From then,
many drivers were rewritten to match the new environment and use the full
potential of newly added functionalities.

But plenty of drivers still need to be ported for DRM system or have some key
functionalities missing. This post describes a story of implementing a feature
called `bridge chaining`.

## DRM bridges chaining implementation process

One of the key features of the DRM system is the possibility to integrate
several `bridges` into one video chain to convert from one video format to
another. This feature is described in [Linux Kernel
documentation][kms-linux-docs] as `still in-flux and not really fully sorted out
yet`, so, problems with implementation were expected. But nobody said it is
going to be easy!

### Structure

Hardware used:

* `i.mx8mmini` SoC;
* `sn65dsi84` MIPI DSI to LVDS bridge;
* `it6263` LVDS to HDMI bridge.
* HDMI panel.

The plan was to generate DSI video signal from SoC, convert it to LVDS, then
convert it to HDMI, and, finally, feed the HDMI panel. The entire operation was
being controlled by the system via the I2C interface to which all bridges were
connected. So, the hardware structure is following:

![bridge-chaining-hardware](/img/bridge-chaining-hardware.png)

Software used:

* GNU/Linux v5.15;
* Weston (the reference implementation of a Wayland server).

Responsibilities for generating graphics among software were split into two
parts; both use DRM system:

* kernel space: responsible for generating graphics during boot (logo, console,
etc.), is directly driven by Linux Kernel;
* userspace: responsible for generating graphics after boot, is driven by
several userspace clients and graphic server (Weston in this case).

The switch is performed when Weston is being loaded by `systemd`.

### Implementation process

#### Hardware setup and devicetree

Hardware setup was rather easy:

1) Connect all the needed wires;
2) Do not miss any data and clock I2C wires.

So as devicetree configuration:

1) Enable needed subsystems (LCDIF, MIPI DSI, etc.);
2) Register bridges under chosen I2C buses and configure them, here is for
example `it6263` and `sn65dsi84` configurations:

    ```dts
    &i2c3 {
        lvds-to-hdmi-bridge@4c {
            compatible = "ite,it6263";
            reg = <0x4c>;
            pinctrl-names = "default";
            pinctrl-0 = <&pinctrl_it6263_en>;
            reset-gpios = <&gpio5 2 GPIO_ACTIVE_LOW>;
            status = "okay";

            port {
                it6263_in: endpoint {
                    remote-endpoint = <&lvds_out>;
                };
            };
        };

    mipi_to_lvds: sn65dsi84@2c {
        compatible = "ti,sn65dsi83";
        reg = <0x2c>;
        enable-gpios = <&gpio1 6 GPIO_ACTIVE_HIGH>;
        interrupts-extended = <&gpio1 5 GPIO_ACTIVE_HIGH>;
        clocks = <&mipi_dsi 0>, <&clk IMX8MM_CLK_LCDIF_PIXEL>;
        clock-names = "mipi_clk", "pixel_clock";
        display = <&display_subsystem>;
        pinctrl-names = "default";
        pinctrl-0 = <&pinctrl_i2c1_sn65dsi84>;
        sync-delay = <512>;
        dsi-lanes = <4>;
        status = "okay";

        lvds_ports: ports {
            #address-cells = <1>;
            #size-cells = <0>;

            port@0 {
                reg = <0>;
                lvds_in: endpoint {
                    remote-endpoint = <&mipi_out>;
                    data-lanes = <1 2 3 4>;
                };
            };

            port@2 {
                reg = <2>;
                lvds_out: endpoint {
                    remote-endpoint = <&it6263_in>;
                    attach-bridge;
            };
        };
    };
    ```

3) Configure power controllers:

    ```dts
    &regulators {
        reg_lvds_pwr: lvds_pwr {
            compatible = "regulator-fixed";
            pinctrl-names = "default";
            regulator-name = "lvds_pwr_en";
            pinctrl-0 = <&pinctrl_lcd_3v3_enable>;
            gpio = <&gpio4 29 GPIO_ACTIVE_HIGH>;
            enable-active-high;
            regulator-boot-on;
            regulator-always-on;
        };
        reg_5v_bl: 5v_bl {
            compatible = "regulator-fixed";
            pinctrl-names = "default";
            regulator-name = "5v_bl_en";
            pinctrl-0 = <&pinctrl_lcd_5v_enable>;
            gpio = <&gpio5 5 GPIO_ACTIVE_HIGH>;
            enable-active-high;
            regulator-boot-on;
            regulator-always-on;
        };
    };
    ```

4) And `i.mx` input-output multiplexers:

    ```dts
    &iomuxc {
        pinctrl_lcd_3v3_enable: lcd_3v3_en {
            fsl,pins = <
                MX8MM_IOMUXC_SAI3_RXC_GPIO4_IO29 0x19
            >;
        };
        pinctrl_lcd_5v_enable: lcd_5v_en {
            fsl,pins = <
                MX8MM_IOMUXC_SPDIF_EXT_CLK_GPIO5_IO5 0x19
            >;
        };
        pinctrl_it6263_en: it6263_en {
            fsl,pins = <
                MX8MM_IOMUXC_SAI3_MCLK_GPIO5_IO2 0x19
            >;
        };
        pinctrl_i2c1_sn65dsi84: i2c1-sn65dsi83grp {
            fsl,pins = <
                MX8MM_IOMUXC_GPIO1_IO05_GPIO1_IO5 0x04
                MX8MM_IOMUXC_GPIO1_IO06_GPIO1_IO6 0x106
            >;
        };
    };
    ```

After above changes both chips were detected on I2C buses, here is `sn65dsi84`
on `i2c-0` under address `2c`:

```shell
# i2cdetect -y 0
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:                         UU -- -- -- -- -- -- --
10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
20: -- -- -- -- -- -- -- -- -- -- -- -- 2c -- -- --
30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
40: -- -- -- -- -- -- -- -- 48 -- -- -- -- -- -- --
50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
60: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
70: -- -- -- -- -- -- -- --
```

#### Drivers

Then, it was high time to add appropriate drivers to the image. In theory, after
adding drivers, the entire graphic chain presented in [Structure](#structure)
chapter above should work, with no need for additional kernel or Weston
configuration. Let's see then.

Following drivers were chosen to drive this chain:

* for `sn65dsi84`: driver from [`varigit/linux-imx` repository][sn65dsi84-varigit-repo]
* for `it6263`: driver from [`nxp-imx/linux-imx` repository][it6263-nxp-repo]

[it6263-nxp-repo]: https://github.com/nxp-imx/linux-imx/blob/lf-5.15.y/drivers/gpu/drm/bridge/it6263.c

#### Bridge chaining

The first boot result was not very pleasurable: several errors in `dmesg` from
`sn65dsi84` driver and no messages from `it6263` driver. No video output was
noticed as well:

```shell
# dmesg | grep it6263
# dmesg | grep sn65dsi84
[    3.575954] sn65dsi84 0-002c: even_odd_swap property not found, using default
[    3.583172] sn65dsi84 0-002c: lvds-channels property not found, using default
[    3.590351] /soc@0/bus@30800000/i2c@30a20000/sn65dsi84@2c: could not find display-timings node
[    3.598985] /soc@0/bus@30800000/i2c@30a20000/sn65dsi84@2c: no timings specified
(...)
```

Ok then, all `sn65dsi84` errors were fixed, it was a matter of devicetree
configuration. But still no video on the panel.

Several checks were done to check every part of the system separately:

1) Checking `sn65dsi84` with LVDS panel proved correct driver and hardware
configuration by showing some video output;
2) Checking communication via I2C with `it6263` proved correct connection (some
register write/read operations were done);
3) Checking the HDMI panel proved correct connection and functionality by
showing video output connected to another platform.

Still not a clue where the problem is.

While checking the code of the `sn65dsi84` driver from the `varigit/linux-imx`
repository the absence of a call to [`drm_bridge_attach()`
function][drm_bridge_attach-bootlin] in the attach function was noticed. So,
`it6263` simply was not `attached` to the chain by `sn65dsi84` as it should be.
After several experiments decision to use `sn65dsi84` [driver from
`nxp-imx/linux-imx` repository][sn65dsi84-nxp-repo] was made, here is a call to
`drm_bridge_attach()` from the repository:

```c
static int sn65dsi83_attach(struct drm_bridge *bridge,
                enum drm_bridge_attach_flags flags)
{
    struct sn65dsi83 *ctx = bridge_to_sn65dsi83(bridge);

    (...)

    return drm_bridge_attach(bridge->encoder, ctx->panel_bridge,
                &ctx->bridge, flags);
    (...)
}
```

So, after performing all operations needed to attach `sn65dsi84` to the previous
bridge or encoder in the chain this call executes the next bridge's attach
function.

After switching to another `sn65dsi84` driver, both bridges were successfully
probed and recognized by the DRM system:

```shell
# cat /sys/bus/i2c/devices/*c/name
sn65dsi84
(...)
it6263
# dmesg | grep it6263
[    3.130625] it6263_probe has been called
[    3.131740] it6263_reset has been called
(...)
[    3.694544] it6263_bridge_attach has been called
(...)
# dmesg | grep sn65dsi84
[    3.658664] sn65dsi83_probe has been called
[    3.661588] sn65dsi83_parse_dt has been called
(...)
[    3.689746] sn65dsi83_attach has been called
(...)
```

> Note: `dmesg` logs from above are provided by adding `printk()` to the drivers
source code.

After further analysis, the following problems were pointed out:

* No video output on the panel during boot as well as in userspace;
* Weston argues that one `drm_connector` does not have CRTC assigned:

    ```shell
    [11:44:08.403] weston 10.0.1
    (...)
    [11:44:09.436] Output 'DSI-1' using color profile: built-in default sRGB SDR profile
    [11:44:09.444] Output DSI-1 (crtc 33) video modes:
                   1280x720@59.9 16:9, current, 74.2 MHz
    [11:44:09.444] Output 'DSI-1' enabled with head(s) DSI-1
    [11:44:09.444] Module '/usr/lib/libgbm.so' already loaded
    [11:44:09.444] Output 'HDMI-A-1' using color profile: built-in default sRGB SDR profile
    [11:44:09.444] Output 'HDMI-A-1': No available CRTCs.
    [11:44:09.444] Enabling output "HDMI-A-1" failed.
    [11:44:09.444] Error: cannot enable output 'HDMI-A-1' without heads.
    ```

[sn65dsi84-varigit-repo]: https://github.com/varigit/linux-imx/tree/lf-5.10.y_var04/drivers/gpu/drm/bridge/sn65dsi83
[sn65dsi84-nxp-repo]: https://github.com/nxp-imx/linux-imx/blob/lf-5.15.y/drivers/gpu/drm/bridge/ti-sn65dsi83.c
[drm_bridge_attach-bootlin]: https://elixir.bootlin.com/linux/v5.15.71/source/drivers/gpu/drm/drm_bridge.c#L175

##### Weston issue

According to [Linux Kernel DRM/KMS system documentation][kms-linux-docs] the KMS
structure should be following:

![kms-structure](/img/kms-structure-bridge-chaining.png)

The red-marked `drm_connector` structure is surplus and is causing the Weston
issues.

According to [comments in `drm_bridge_connector.c`][drm-bridge-connector-com]
and to [comments in `drm_bridge.c`][drm-bridge-com] file, to create
`drm_connector` for a chain of bridges, DRM drivers should match the following
requirements:

* Encoder or display controller drivers should:
  * Create `drm_connector` structure and initialize it by using
  `drm_bridge_connector_init()` function from `drm_bridge_connector.c`;
* Bridge drivers should:
  * Export following functions via `drm_bridge_funcs` (some of them are
  optional): `drm_bridge_funcs.detect()`, `drm_bridge_funcs.get_modes()`,
  `drm_bridge_funcs.get_edid()`, `drm_bridge_funcs.get_edid()`,
  `drm_bridge_funcs.hpd_enable()` and `drm_bridge_funcs.hpd_disable().`;
  * Export its type and functionalities via flags `drm_bridge.type`and
  `drm_bridge.ops`
  * Do not create connectors by themselves or implement conditional
  connector creation.

To implement the above requirements the following files were modified:

* `sec-dsim.c` (driver for MIPI DSI transmitter) - to implement the creation of
  `drm_connector` structure for the chain of bridges:

    ```diff
    diff --git a/drivers/gpu/drm/bridge/sec-dsim.c b/drivers/gpu/drm/bridge/sec-dsim.c
    index e6038c5dd221..921b4c3a2768 100644
    --- a/drivers/gpu/drm/bridge/sec-dsim.c
    +++ b/drivers/gpu/drm/bridge/sec-dsim.c
    @@ -28,6 +28,7 @@
     #include <drm/drm_atomic_helper.h>
     #include <drm/drm_bridge.h>
     #include <drm/drm_connector.h>
    +#include <drm/drm_bridge_connector.h>
     #include <drm/drm_probe_helper.h>
     #include <drm/drm_encoder.h>
     #include <drm/drm_fourcc.h>
    @@ -294,6 +295,7 @@ struct dsim_pll_pms {
     struct sec_mipi_dsim {
            struct mipi_dsi_host dsi_host;
            struct drm_connector connector;
    +       struct drm_connector *bridge_connector;
            struct drm_encoder *encoder;
            struct drm_bridge *bridge;
            struct drm_bridge *next;
    @@ -2021,8 +2023,8 @@ int sec_mipi_dsim_bind(struct device *dev, struct device *master, void *data,
            bridge->of_node = dev->of_node;
            bridge->encoder = encoder;

    -       /* attach sec dsim bridge and its next bridge if exists */
    -       ret = drm_bridge_attach(encoder, bridge, NULL, 0);
    +       ret = drm_bridge_attach(encoder, bridge, NULL, DRM_BRIDGE_ATTACH_NO_CONNECTOR);
    +
            if (ret) {
                    dev_err(dev, "Failed to attach bridge: %s\n", dev_name(dev));

    @@ -2048,6 +2050,21 @@ int sec_mipi_dsim_bind(struct device *dev, struct device *master, void *data,
                    return ret;
            }

    +       connector = dsim->bridge_connector;
    +       connector = drm_bridge_connector_init(drm_dev, encoder);
    +
    +       if(!connector)
    +               dev_dbg(dev, "%s: bridge connector has not been allocated", __FUNCTION__ );
    +
    +       ret = drm_connector_attach_encoder(connector, encoder);
    +
    +       if(ret){
    +               dev_dbg(dev, "%s: encoder to bridge connector has not been attached", __FUNCTION__);
    +               return ret;
    +       }
    +
    +       return 0;
    +
         panel:
                if (dsim->panel) {
                        /* A panel has been attached */
    ```

* `ti-sn65dsi84.c` - to export appropriate functions via `drm_bridge_funcs` and
  to export type and functionalities via `drm_bridge.type`and `drm_bridge.ops`:

    ```diff
    diff --git a/drivers/gpu/drm/bridge/ti-sn65dsi83.c b/drivers/gpu/drm/bridge/ti-sn65dsi83.c
    index c901c0e1a3b0..d0a5c5328eae 100644
    --- a/drivers/gpu/drm/bridge/ti-sn65dsi83.c
    +++ b/drivers/gpu/drm/bridge/ti-sn65dsi83.c
    @@ -137,6 +137,8 @@ enum sn65dsi83_model {

     struct sn65dsi83 {
            struct drm_bridge               bridge;
    +       struct drm_display_mode         curr_mode;
    +       enum drm_connector_status       status;
            struct device                   *dev;
            struct regmap                   *regmap;
            struct device_node              *host_node;
    @@ -581,6 +583,48 @@ sn65dsi83_atomic_get_input_bus_fmts(struct drm_bridge *bridge,
            return input_fmts;
     }

    +static enum drm_connector_status
    +sn65dsi83_bridge_detect(struct drm_bridge *bridge)
    +{
    +       struct sn65dsi83 *sn65dsi83 = bridge_to_sn65dsi83(bridge);
    +       enum drm_connector_status status;
    +
    +       status = connector_status_connected;
    +       sn65dsi83->status = status;
    +       return status;
    +}
    +
    +static int sn65dsi83_bridge_get_modes(struct drm_bridge *bridge,
    +                                               struct drm_connector *connector)
    +{
    +       struct sn65dsi83 *sn65dsi83 = bridge_to_sn65dsi83(bridge);
    +       struct drm_display_mode *mode;
    +       u32 bus_format = MEDIA_BUS_FMT_RGB888_1X24;
    +       u32 *bus_flags = &connector->display_info.bus_flags;
    +       int ret;
    +
    +       mode = drm_mode_create(connector->dev);
    +       if (!mode)
    +               return 0;
    +
    +       *mode = sn65dsi83->curr_mode;
    +
    +       drm_mode_probed_add(connector, mode);
    +
    +       connector->display_info.width_mm = mode->width_mm;
    +       connector->display_info.height_mm = mode->height_mm;
    +
    +       *bus_flags |= DRM_BUS_FLAG_DE_LOW;
    +       *bus_flags |= DRM_BUS_FLAG_PIXDATA_DRIVE_NEGEDGE;
    +
    +       ret = drm_display_info_set_bus_formats(&connector->display_info,
    +                                                  &bus_format, 1);
    +       if (ret)
    +               return ret;
    +
    +       return 1;
    +}
    +
     static const struct drm_bridge_funcs sn65dsi83_funcs = {
            .attach                 = sn65dsi83_attach,
            .atomic_pre_enable      = sn65dsi83_atomic_pre_enable,
    @@ -593,6 +637,11 @@ static const struct drm_bridge_funcs sn65dsi83_funcs = {
            .atomic_destroy_state = drm_atomic_helper_bridge_destroy_state,
            .atomic_reset = drm_atomic_helper_bridge_reset,
            .atomic_get_input_bus_fmts = sn65dsi83_atomic_get_input_bus_fmts,
    +
    +       /*we need to exporte these functions in case we create external
    +       * drm_connector.*/
    +       .detect = sn65dsi83_bridge_detect,
    +       .get_modes = sn65dsi83_bridge_get_modes,
     };

     static int sn65dsi83_parse_dt(struct sn65dsi83 *ctx, enum sn65dsi83_model model)
    @@ -673,6 +722,7 @@ static int sn65dsi83_probe(struct i2c_client *client,
                    return -ENOMEM;

            ctx->dev = dev;
    +       ctx->status = connector_status_disconnected;

            if (dev->of_node) {
                    model = (enum sn65dsi83_model)(uintptr_t)
    @@ -701,7 +751,8 @@ static int sn65dsi83_probe(struct i2c_client *client,
            ctx->bridge.funcs = &sn65dsi83_funcs;
            ctx->bridge.of_node = dev->of_node;
            drm_bridge_add(&ctx->bridge);
    -
    +       ctx->bridge.type = DRM_MODE_CONNECTOR_DSI;
    +       ctx->bridge.ops = DRM_BRIDGE_OP_DETECT | DRM_BRIDGE_OP_MODES;
            return 0;

     err_put_node:
    ```

* `it6263.c` - to export appropriate functions via `drm_bridge_funcs`, implement
  conditional creation of `drm_connector` structure and to export type and
  functionalities via `drm_bridge.type`and `drm_bridge.ops`:

    ```diff
    diff --git a/drivers/gpu/drm/bridge/it6263.c b/drivers/gpu/drm/bridge/it6263.c
    index 6254b8a31538..e91aba5a17b6 100644
    --- a/drivers/gpu/drm/bridge/it6263.c
    +++ b/drivers/gpu/drm/bridge/it6263.c
    @@ -570,7 +570,7 @@ it6263_read_edid(void *data, u8 *buf, unsigned int block, size_t len)
            return 0;
     }

    -static int it6263_get_modes(struct drm_connector *connector)
    +static int it6263_connector_get_modes(struct drm_connector *connector)
     {
            struct it6263 *it6263 = connector_to_it6263(connector);
            u32 bus_format = MEDIA_BUS_FMT_RGB888_1X24;
    @@ -616,7 +616,7 @@ static enum drm_mode_status it6263_mode_valid(struct drm_connector *connector,
     }

     static const struct drm_connector_helper_funcs it6263_connector_helper_funcs = {
    -       .get_modes = it6263_get_modes,
    +       .get_modes = it6263_connector_get_modes,
            .mode_valid = it6263_mode_valid,
     };

    @@ -726,32 +726,28 @@ static int it6263_bridge_attach(struct drm_bridge *bridge,
            struct drm_device *drm = bridge->dev;
            int ret;

    -       if (flags & DRM_BRIDGE_ATTACH_NO_CONNECTOR) {
    -               DRM_ERROR("Fix bridge driver to make connector optional!");
    -               return -EINVAL;
    -       }
    -
            if (!drm_core_check_feature(drm, DRIVER_ATOMIC)) {
                    dev_err(&it6263->hdmi_i2c->dev,
                            "it6263 driver only copes with atomic updates\n");
                    return -ENOTSUPP;
            }

    -       it6263->connector.polled = DRM_CONNECTOR_POLL_CONNECT |
    -                                  DRM_CONNECTOR_POLL_DISCONNECT;
    -       ret = drm_connector_init(drm, &it6263->connector,
    -                                &it6263_connector_funcs,
    -                                DRM_MODE_CONNECTOR_HDMIA);
    -       if (ret) {
    -               dev_err(&it6263->hdmi_i2c->dev,
    -                               "Failed to initialize connector with drm\n");
    -               return ret;
    -       }
    -
    -       drm_connector_helper_add(&it6263->connector,
    -                                &it6263_connector_helper_funcs);
    -       drm_connector_attach_encoder(&it6263->connector, bridge->encoder);
    +       if(flags != DRM_BRIDGE_ATTACH_NO_CONNECTOR){
    +               it6263->connector.polled = DRM_CONNECTOR_POLL_CONNECT |
    +                                          DRM_CONNECTOR_POLL_DISCONNECT;
    +               ret = drm_connector_init(drm, &it6263->connector,
    +                                        &it6263_connector_funcs,
    +                                        DRM_MODE_CONNECTOR_HDMIA);
    +               if (ret) {
    +                       dev_err(&it6263->hdmi_i2c->dev,
    +                                       "Failed to initialize connector with drm\n");
    +                       return ret;
    +               }

    +               drm_connector_helper_add(&it6263->connector,
    +                                        &it6263_connector_helper_funcs);
    +               drm_connector_attach_encoder(&it6263->connector, bridge->encoder);
    +       }
            return ret;
     }

    @@ -794,6 +790,42 @@ static u32
            return input_fmts;
     }

    +static enum drm_connector_status
    +it6263_bridge_detect(struct drm_bridge *bridge)
    +{
    +       struct it6263 *it6263 = bridge_to_it6263(bridge);
    +
    +       if (it6263_hpd_is_connected(it6263))
    +               return connector_status_connected;
    +
    +       return connector_status_disconnected;
    +}
    +
    +static int it6263_bridge_get_modes(struct drm_bridge *bridge, struct drm_connector *connector)
    +{
    +       struct it6263 *it6263 = bridge_to_it6263(bridge);
    +       u32 bus_format = MEDIA_BUS_FMT_RGB888_1X24;
    +       struct edid *edid;
    +       int num = 0;
    +       int ret;
    +
    +       edid = drm_do_get_edid(connector, it6263_read_edid, it6263);
    +       drm_connector_update_edid_property(connector, edid);
    +       if (edid) {
    +               num = drm_add_edid_modes(connector, edid);
    +               it6263->is_hdmi = drm_detect_hdmi_monitor(edid);
    +               kfree(edid);
    +       }
    +
    +       ret = drm_display_info_set_bus_formats(&connector->display_info,
    +                                              &bus_format, 1);
    +       if (ret)
    +               dev_dbg(&it6263->hdmi_i2c->dev,
    +                       "failed to set the supported bus format %d\n", ret);
    +
    +       return num;
    +}
    +
     static const struct drm_bridge_funcs it6263_bridge_funcs = {
            .attach = it6263_bridge_attach,
            .atomic_duplicate_state = drm_atomic_helper_bridge_duplicate_state,
    @@ -804,6 +836,11 @@ static const struct drm_bridge_funcs it6263_bridge_funcs = {
            .enable = it6263_bridge_enable,
            .atomic_check = it6263_bridge_atomic_check,
            .atomic_get_input_bus_fmts = it6263_bridge_atomic_get_input_bus_fmts,
    +
    +       /*We need to export these functions in case we create external
    +        *drm_connector.*/
    +       .detect = it6263_bridge_detect,
    +       .get_modes = it6263_bridge_get_modes,
     };

     static int it6263_check_chipid(struct it6263 *it6263)
    @@ -991,6 +1028,8 @@ static int it6263_probe(struct i2c_client *client,

            it6263->bridge.funcs = &it6263_bridge_funcs;
            it6263->bridge.of_node = np;
    +       it6263->bridge.type = DRM_MODE_CONNECTOR_HDMIA;
    +       it6263->bridge.ops = DRM_BRIDGE_OP_DETECT | DRM_BRIDGE_OP_MODES;
            drm_bridge_add(&it6263->bridge);

            i2c_set_clientdata(client, it6263);
    ```

Weston has not argued anymore about connectors:

```shell
(...)
[13:52:54.907] weston 10.0.1
(...)
[13:38:50.377] Output 'HDMI-A-1' using color profile: built-in default sRGB SDR profile
[13:38:50.386] Output HDMI-A-1 (crtc 33) video modes:
               1280x720@60.0, preferred, current, 64.0 MHz
               1280x720@60.0 16:9, 74.2 MHz
               1280x720@50.0 16:9, 74.2 MHz
               832x624@74.6, 57.3 MHz
               800x600@75.0, 49.5 MHz
               640x480@75.0, 31.5 MHz
               640x480@72.8, 31.5 MHz
               640x480@66.7, 30.2 MHz
               720x400@70.1, 28.3 MHz
[13:38:50.386] Output 'HDMI-A-1' enabled with head(s) HDMI-A-1
[13:38:50.386] Compositor capabilities:
               arbitrary surface rotation: yes
               screen capture uses y-flip: yes
               cursor planes: yes
               arbitrary resolutions: no
               view mask clipping: yes
               explicit sync: yes
               color operations: no
               presentation clock: CLOCK_MONOTONIC, id 1
               presentation clock resolution: 0.000000001 s
[13:38:50.397] Loading module '/usr/lib/weston/desktop-shell.so'
[13:38:50.413] launching '/usr/libexec/weston-keyboard'
[13:38:50.417] Warning: support for deprecated wl_shell interface is enabled. Please migrate legacy clients to xdg-shell.
[13:38:50.420] Loading module '/usr/lib/weston/screen-share.so'
[13:38:50.426] Loading module '/usr/lib/weston/systemd-notify.so'
[13:38:50.427] info: add 1 socket(s) provided by systemd
[13:38:50.427] launching '/usr/libexec/weston-desktop-shell'
(...)
```

But still no video output on the panel.

[kms-linux-docs]: https://www.kernel.org/doc/html/latest/gpu/drm-kms.html
[drm-bridge-connector-com]: https://elixir.bootlin.com/linux/v5.15.71/source/drivers/gpu/drm/drm_bridge_connector.c#L20
[drm-bridge-com]: https://elixir.bootlin.com/linux/v5.15.71/source/drivers/gpu/drm/drm_bridge.c#L260

##### No video output issue

For now, the KMS infrastructure looks like this:

```shell
# modeset
(...)
Encoders:
id      crtc    type    possible crtcs  possible clones
34      33      DSI     0x00000001      0x00000001

Connectors:
id      encoder status          name            size (mm)       modes   encoders
35      34      connected       HDMI-A-1        340x190         9       34
  modes:
        index name refresh (Hz) hdisp hss hse htot vdisp vss vse vtot
  #0 1280x720 60.00 1280 1328 1360 1440 720 727 735 741 64020 flags: phsync, pvsync; type: preferred, driver
  #1 1280x720 60.00 1280 1390 1430 1650 720 725 730 750 74250 flags: phsync, pvsync; type: driver
  #2 1280x720 50.00 1280 1720 1760 1980 720 725 730 750 74250 flags: phsync, pvsync; type: driver
  #3 832x624 74.55 832 864 928 1152 624 625 628 667 57284 flags: nhsync, nvsync; type: driver
  #4 800x600 75.00 800 816 896 1056 600 601 604 625 49500 flags: phsync, pvsync; type: driver
  #5 640x480 75.00 640 656 720 840 480 481 484 500 31500 flags: nhsync, nvsync; type: driver
  #6 640x480 72.81 640 664 704 832 480 489 492 520 31500 flags: nhsync, nvsync; type: driver
  #7 640x480 66.67 640 704 768 864 480 483 486 525 30240 flags: nhsync, nvsync; type: driver
  #8 720x400 70.08 720 738 846 900 400 412 414 449 28320 flags: nhsync, pvsync; type: driver
  props:
        1 EDID:
                flags: immutable blob
                blobs:

                value:
                        00ffffffffffff002074560100000000
                        141f010380221378fe6435a5544f9e27
                        125054bfea0061400101010101010101
                        010101010101021900a050d015203020
                        (...)

CRTCs:
id      fb      pos     size
33      40      (0,0)   (1280x720)
  #0 1280x720 60.00 1280 1328 1360 1440 720 727 735 741 64020 flags: phsync, pvsync; type: preferred, driver
(...)

Planes:
id      crtc    fb      CRTC x,y        x,y     gamma size      possible crtcs
31      33      40      0,0             0,0     0               0x00000001
  formats: XR24 AR24 RG16 XB24 AB24 RX24 RA24 AR15 XR15 AB15 XB15 BG16
(...)
```

Quick summary:

* System correctly recognizes the chain;
* EDID is being read and interpreted;
* Connector got nine modes from EDID with one set as `preferred`;
* Preferred mode is set as `current`;
* All elements of the chain are connected to each other and have expected
  information attached to it;
* No video on the HDMI panel during boot as well as in userspace.

After several days in complete darkness, a light in the tunnel was found. During
one of many experiments, penguins (Linux Kernel logo) showed up during boot.
It happened after forcing the system to use a mode with a specific pixel clock
frequency. All other modes were checked to prove that the issue was hidden in
modes. To force the kernel, `video` [command line parameter][kernel-cmd-line-param]
was used; on the other hand, to force Weston, `weston.ini` was used.

Additionally following changes were added:

* [Commit `c35a6e6c8c59e43b5080a6c77c2866ed9e01a77b`][commit-c35a6e6] from
  `nxp-ixm/linux-imx` repository;
* Changed `sn65dsi84` configuration from `burst` video mode to `burst with sync
  pulses` video mode:

    ```diff
    diff --git a/drivers/gpu/drm/bridge/ti-sn65dsi83.c b/drivers/gpu/drm/bridge/ti-sn65dsi83.c
    index d0a5c5328eae..62058ee91b0a 100644
    --- a/drivers/gpu/drm/bridge/ti-sn65dsi83.c
    +++ b/drivers/gpu/drm/bridge/ti-sn65dsi83.c
    @@ -274,7 +274,7 @@ static int sn65dsi83_attach(struct drm_bridge *bridge,

            dsi->lanes = ctx->dsi_lanes;
            dsi->format = MIPI_DSI_FMT_RGB888;
    -       dsi->mode_flags = MIPI_DSI_MODE_VIDEO | MIPI_DSI_MODE_VIDEO_BURST;
    +       dsi->mode_flags = MIPI_DSI_MODE_VIDEO | MIPI_DSI_MODE_VIDEO_SYNC_PULSE;

            ret = mipi_dsi_attach(dsi);
            if (ret < 0) {
    ```

And... That it, the panel shown perfect picture during boot as well as in
userspace! It seems that connector had not only suitable modes for used
hardware but nonsuitable as well.

DRM system has tools to filter out inappropriate modes. Every bridge driver
should specify limitations to modes in `drm_bridge_funcs.mode_valid()` function.
After doing so, the list of modes in the connector was limited to only two modes,
so the system had only two choices:

```shell
# modetest
(...)
Connectors:
id      encoder status          name            size (mm)       modes   encoders
35      34      connected       HDMI-A-1        340x190         2       34
  modes:
        index name refresh (Hz) hdisp hss hse htot vdisp vss vse vtot
  #0 1280x720 60.00 1280 1390 1430 1650 720 725 730 750 74250 flags: phsync, pvsync; type: driver
  #1 1280x720 50.00 1280 1720 1760 1980 720 725 730 750 74250 flags: phsync, pvsync; type: driver
(...)
```

In such cases the Linux Kernel sets as `current` the mode with the bigger
resolution and frame rate. As a result, the mode with a resolution `1280x720`
and a frequency of 60 Hz was chosen:

```shell
# modetest
(...)
CRTCs:
id      fb      pos     size
33      40      (0,0)   (1280x720)
  #0 1280x720 60.00 1280 1390 1430 1650 720 725 730 750 74250 flags: phsync, pvsync; type: driver
(...)
```

[kernel-cmd-line-param]: https://www.kernel.org/doc/html/v4.14/admin-guide/kernel-parameters.html
[commit-c35a6e6]: https://github.com/nxp-imx/linux-imx/commit/c35a6e6c8c59e43b5080a6c77c2866ed9e01a77b

## Summary

The DRM system is a great step forward compared to big all-in-one graphic
servers. The idea of its abstractions presents that even such complex systems
can be built and described in a straightforward way even for newbies, it still
requires some attention and care from developers, though.

For those who want to dive deeper into the DRM system, I recommend the following
resources:

* [Latest Linux Kernel
  documentation](https://www.kernel.org/doc/html/latest/index.html)
* [The DRM/KMS subsystem from a newbie’s point of view, Boris
  Brezillon](https://bootlin.com/pub/conferences/2014/elce/brezillon-drm-kms/brezillon-drm-kms.pdf)
* [DRM KMS overview,
  wiki.st.com](https://wiki.st.com/stm32mpu/wiki/DRM_KMS_overview)
* [Anatomy of an Atomic KMS Driver, Laurent
  Pinchart](https://youtu.be/lihqR9sENpc)
* [Atomic mode setting design overview, part 1, Daniel
  Vetter](https://lwn.net/Articles/653071/)
* [Atomic mode setting design overview, part 2, Daniel
  Vetter](https://lwn.net/Articles/653466/)
* [An Overview of the Linux and Userspace Graphics Stack, Paul
  Kocialkowski](https://youtu.be/wjAJmqwg47k)
* [Standardizing Linux DRM drivers implementations by interfacing DRM Bridge as
  a single API, Jagan Teki](https://youtu.be/IVI30LzPzAA)
