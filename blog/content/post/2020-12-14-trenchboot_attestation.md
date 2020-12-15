---
title: 'Proof of concept implementation of RATS attestation for the TrenchBoot'
abstract: 'This blog post will describe the concept of the IETF Remote
          Attestation Procedures (RATS) and implementation of 
          CHAllenge-Response based Remote Attestation (CHARRA) with TPM 2.0 for
          TrenchBoot.'
cover: /covers/trenchboot-logo.png
author: norbert.kaminski
layout: post
published: true
date: 2020-12-14
archives: "2020"

tags:
  - TrenchBoot
  - attestation
  - TPM2
  - firmware
categories:
  - Firmware
  - Security

---

If you haven’t read previous blog posts from the TrenchBoot series, I strongly
encourage you to catch up on them. The best way is to search under the
[TrenchBoot tag](https://blog.3mdeb.com/tags/trenchboot/). This blog post will
describe the concept of the IETF Remote Attestation Procedures (RATS) and
implementation of CHAllenge-Response based Remote Attestation (CHARRA) with TPM
2.0 for TrenchBoot.

## Remote Attestation Procedures Architecture (RATS)

The Remote Attestation Procedures (RATS) describe the methods of trustworthiness
verification of an attested device (the "attester").

![RATS_architecture](/img/RATS_architecture.png)

The verification proceeds on the basis of believable evidence. The verifier
checks the endorsement from endorsers, reference values, and the evidence
against the appraisal policy from the verifier owner.

The endorsement is a secure statement that the attester can use to sign
the evidence. For example in the TPM2 context endorsement will be the
attestation private key. It confirms the integrity of a public key, which is
used to verify the signature of the Evidence.

To generate the attestation result the verifier uses the reference values, which
determine the exact values or boundaries of the evidence data. The reference
values might be included in the appraisal policy that specifies the constraints
that must be satisfied by the evidence.

The verifier sends the attestation result to the "Relying Party", which decides
whether the attester is trustworthy.

The IETF RATS specifies also basic models for communication between an Attester,
a Verifier, and a Relying Party. The Passport Model and Background-Check Model
are described in details in the IETF
[document](https://datatracker.ietf.org/doc/draft-ietf-rats-architecture/?include_text=1).
In this blog post, I will describe the architecture and proof of concept
implementation of the CHAllenge-Response based Remote Attestation (CHARRA).

## CHAllenge-Response based Remote Attestation with TPM 2.0

The Reference Interaction Models for Remote Attestation Procedures focus
on the interaction models between the attester and verifier in order to convey
the Evidence.

![CHARRA_architecture](/img/CHARRA_architecture.png)

In the beginning, the attester generates the values about its state and creates the
claims. Claims are assertions that represent characteristics of an
attester's target environment. The attester may consist of one or more target
environments. The target environment represents the part of the attested device
that could provide claims about its state. For example, it could be read-only
memory of BIOS, an updatable bootloader or an operating system kernel, etc.

The attestation process is initiated by the verifier. It sends the remote
attestation request to the attester. The request includes a handle, a list of
authentication secrets IDs, and claim selection. The handle is composed of
strongly randomly generated data (nonce), which guarantees Evidence freshness.
Authentication Secrets IDs specify the target environment, which must provide
the evidence. Claim selection tells the attester which claims should be
included in the evidence.

In the next step, the attester collects the selected claims and on this base, it
generates the evidence. The attester sends to the verifier the message, which
consists of the evidence and the event log. The verifier appraises the evidence
and it creates the attestation result, which should be passed to the Relying
Party.

More information about the Reference Interaction Models for Remote Attestation
Procedures is presented in the IETF
[document](https://www.ietf.org/archive/id/draft-birkholz-rats-reference-interaction-model-03.txt).


## Proof of Concept Implementation of the CHARRA

The Fraunhofer SIT provides the [proof-of-concept implementation](https://github.com/Fraunhofer-SIT/charra)
for CHARRA. The Verifier and the attester are two separate instances
that provide functionalities that were described above. The
proof-of-concept implementation assumes that the verifier and the attester
are running in the same docker container. Though we cannot say that is the remote
attestation. The verifier and attester are using the TPM Simulator instead of
a physical one.

Our goal is to provide the CHARRA for physical TPM and separate the attester
and verifier.

### Separation of the attester and verifier

As I mentioned before the proof of concept (PoC) implementation of the CHARRA
uses the docker container to provide and appraise evidence. Attestation
data is obtained via a TPM Quote function. It provides the quote and signature
for the given list of PCRs. In the PoC case, the attester and verifier generate
separates keys. In that case verification of TPM quote and signature will
work only when the keys are generated by the same TPM device. Otherwise,
the evidence verification will fail due to a mismatch of the attestation
identity key. To separate the instances we need to verify the signature and
attestation data with the attestation public key.

In the PoC implementation, there is no endorser and key registration system.
Every time the verifier sends the attestation request, the attester is
generating the new attestation key based on the nonce. We need to obtain and
send to the verifier TPM public key that is used to generate the TPM quote.
TPM API (Esys) during the key creation allows obtaining the public and private
part of the attestation key. We added to the `charra_key_mgr` the additional
parameter that conveys the public key to the attester.

The communication between attester and verifier is provided by libcoap library.
It is the C implementation of the Constrained Application Protocol.
Currently, the communication between the attester and verifier is constrained by
a maximum transmission unit (~1500 bytes). The block-wise transmission is in the
development plans. Though we need to fit the public key with the TPM signature
quote and attestation data in the single transmission package. The following
snippet adds the attester public key to the attester response.

```C
	UsefulBufC Tpm2KeyPublic = {attestation_response->tpm2_public_key, attestation_response->tpm2_public_key_len};
	QCBOREncode_AddBytes(&EC, Tpm2KeyPublic);
```

Following code allows the verifier to unmarshal the public key from the attestation
response.

```C
	/* parse "tpm2_public_key (bytes)" */
	if((cborerr = charra_cbor_getnext(&DC, &item, QCBOR_TYPE_BYTE_STRING)))
		goto cbor_parse_error;
	attestation_response->tpm2_public_key_len = item.val.string.len;
	attestation_response->tpm2_public_key = (TPM2B_PUBLIC*)item.val.string.ptr;
```

The verifier must not create its key. Once it will receive the attester
public key, it must set the handle in its TPM context.

```C
CHARRA_RC charra_load_external_public_key(ESYS_CONTEXT* ctx,
	TPM2B_PUBLIC* external_public_key, ESYS_TR* key_handle) {
	TSS2_RC r = TSS2_RC_SUCCESS;
	if (external_public_key == NULL) {
		charra_log_error("External public key do not exist.");
		return CHARRA_RC_ERROR;
	}

	r = Esys_LoadExternal(ctx, ESYS_TR_NONE, ESYS_TR_NONE, ESYS_TR_NONE,
			NULL, external_public_key, TPM2_RH_OWNER, key_handle);
	if (r != TSS2_RC_SUCCESS ) {
		charra_log_error("Loading external public key failed.");
		return CHARRA_RC_ERROR;
	}

	return CHARRA_RC_SUCCESS;
}
```

The following function allows to load external key and it creates `key_handle` that
is used for the TPM signature verification.

The full scope of changes is available in the following
[pull request](https://github.com/Fraunhofer-SIT/charra/pull/16).

### Using CHARRA with TPM device

The PoC CHARRA implementation is using the TPM simulator provided in the docker
container. To use CHARRA with the physical TPM we have created the Yocto layer
- [meta-trenchboot-attestation](https://github.com/3mdeb/meta-trenchboot-attestation),
which provides the required libraries, that are used by attester and verifier.
The Yocto Project (YP) is an open source collaboration project that helps
developers create custom Linux-based systems regardless of the hardware
architecture. [meta-trenchboot](https://github.com/3mdeb/meta-trenchboot)
builds the image which contains the TrenchBoot utilities.

### Proof of concept

To proof the following concept we used the
[ASRock 4x4 Box R1000V](https://www.asrockind.com/en-gb/4X4%20BOX-R1000V)
with physical TPM as the attester and the PC with TPM simulator as the verifier.
Note that you need dTPM. Unfortunately, fTPM included in newer AMD CPUs is not
good enough. The following logs and videos show the attestation process.

**Attester**

```
01:05:37 INFO  src/attester.c:73: [attester] Starting up.
01:05:37 INFO  src/attester.c:82: [attester] Initializing CoAP endpoint.
01:05:37 INFO  src/attester.c:94: [attester] Registering CoAP resources.
01:05:37 INFO  src/util/coap_util.c:51: Adding CoAP FETCH resource 'attest'.
01:05:37 INFO  src/attester.c:101: [attester] Waiting for connections.
01:06:06 INFO  src/attester.c:129: [attester] Resource 'attest': Received message.
01:06:06 INFO  src/attester.c:140: [attester] Received data of length 63.
01:06:06 INFO  src/attester.c:145: [attester] Parsing received CBOR data.
01:06:06 INFO  src/attester.c:155: [attester] Preparing TPM quote data.
01:06:06 INFO  src/attester.c:184: [attester] Loading TPM key.
01:06:06 INFO  src/core/charra_key_mgr.c:36: Loading key "PK.RSA.default".
01:06:19 INFO  src/util/tpm2_util.c:128: Primary Key created successfully.
01:06:19 INFO  src/attester.c:193: [attester] Do TPM Quote.
01:06:19 INFO  src/attester.c:196: [attester] sig_key_handle: 0x40418487
01:06:19 INFO  src/attester.c:197: [attester] public_key: 1
01:06:19 INFO  src/attester.c:203: [attester] TPM Quote successful.
01:06:19 INFO  src/attester.c:209: [attester] Preparing response.
01:06:19 INFO  src/attester.c:218: [attester] Marshaling response.
01:06:19 INFO  src/attester.c:224: [attester] Adding marshaled data to CoAP response PDU and send it.
01:06:19 INFO  src/attester.c:101: [attester] Waiting for connections.
```

[![asciicast](https://asciinema.org/a/7wp9hEjmj8iAPN1fjVPcYwWji.svg)](https://asciinema.org/a/7wp9hEjmj8iAPN1fjVPcYwWji)

In the beginning, the attester is starting up. Then it initializes the CoAP
communication and waits for the attestation request. When the attester receives
the request, it creates the TPM attestation key and collects selected PCRs.
With this data, the attester provides the TPM Quote and signature for a given
list of PRCs. In the next step, the attester creates the response, which
includes attestation data, signature, and the public part of the attestation
key. The message is marshaled into a single package, and the attester sends it
to the verifier.

**Verifier**

```
01:06:06 INFO  src/verifier.c:84: [verifier] Starting up.
01:06:06 INFO  src/verifier.c:93: [verifier] Initializing CoAP endpoint.
01:06:06 INFO  src/verifier.c:104: [verifier] Registering CoAP resource handlers.
01:06:06 INFO  src/verifier.c:108: [verifier] Creating new attestation request.
01:06:06 INFO  src/verifier.c:131: [verifier] Marshaling attestation request data.
01:06:06 INFO  src/verifier.c:145: [verifier] Adding attestation request data to CoAP PDU.
01:06:06 INFO  src/verifier.c:153: [verifier] Sending CoAP message.
01:06:19 INFO  src/verifier.c:251: [verifier] Resource 'attest': Received message.
01:06:19 INFO  src/verifier.c:264: [verifier] Received data of length 1258.
01:06:19 INFO  src/verifier.c:268: [verifier] Parsing received CBOR data.
01:06:19 INFO  src/verifier.c:291: [verifier] Starting verification.
01:06:19 INFO  src/verifier.c:301: [verifier] Loading TPM key.
01:06:19 INFO  src/verifier.c:305: [verifier] External public key loaded.
01:06:19 INFO  src/verifier.c:313: [verifier] Preparing TPM quote verification.
01:06:19 INFO  src/verifier.c:322: [verifier] Verifying TPM Quote signature.
01:06:19 INFO  src/verifier.c:327: [verifier] TPM Quote signature valid!
01:06:19 INFO  src/verifier.c:345: [verifier] +----------------------------+
01:06:19 INFO  src/verifier.c:346: [verifier] |   ATTESTATION SUCCESSFUL   |
01:06:19 INFO  src/verifier.c:347: [verifier] +----------------------------+
```

[![asciicast](https://asciinema.org/a/8cAV0h2FTCghAEFZ09you3J0A.svg)](https://asciinema.org/a/8cAV0h2FTCghAEFZ09you3J0A)


The verifier initializes the CoAP communication and sends the attestation
request to the attester. Then it waits for the attestation response.
When the verifier receives the message, it loads the external public key.
The verifier uses the external key handler to appraise the TPM Quote signature.
If there is no error during the verification process, it shows the message that
attestation is successful.

## Next steps

Right now the verifier checks if the TPM Quote signature created by the attester
is valid. In the future, we will add the policies that will verify if 17th and
18th PCR in the SHA1 and SHA256 banks are compliant with reference values.

Also, we want to create a system of registration attestation identity keys that
will verify integrity for public keys. In the target solution attester won't
send the public key. It will be conveyed by the endorser.

The verifier should be able to start the attestation process, when device wants
to be attested as soon as it starts. This is particularly useful for a large
number of devices. It is easier to use a single known attestation server IP
than multiple attesters addressees.

Currently, we are upstreaming the changes that were made during the development
stage. Here is the list of current and merged pull requests:

* CHARRA:
  - https://github.com/Fraunhofer-SIT/charra/pull/14
  - https://github.com/Fraunhofer-SIT/charra/pull/16

* QCBOR:
  - https://github.com/laurencelundblade/QCBOR/pull/63

## Summary

If you are looking for the basic implementation of the TPM attestation with the
shell commands, I encourage you to take a look at the tpm2-software community
tutorial - [Remote Attestation With Tpm2 Tools](https://tpm2-software.github.io/2020/06/12/Remote-Attestation-With-tpm2-tools.html)
If you have any questions, suggestions, or ideas, feel free to share them in
the comment section. If you are interested in similar content, I encourage you
to [sign up for our newsletter](http://eepurl.com/doF8GX).
