
+++
title = "Derivation Scheme for MuSig2 Aggregate Keys"
date = 2024-01-15
weight = 328

[taxonomies]
authors = ["Ava Chow"]
status = ["Draft"]

[extra]
bip = 328
status = ["Draft"]
github = "https://github.com/bitcoin/bips/blob/master/bip-0328.mediawiki"
note = "THIS FILE IS AUTOMATICALLY GENERATED - NOT MEANT FOR EDITING"
+++

```
  BIP: 328
  Layer: Applications
  Title: Derivation Scheme for MuSig2 Aggregate Keys
  Author: Ava Chow <me@achow101.com>
  Comments-Summary: No comments yet.
  Comments-URI: https://github.com/bitcoin/bips/wiki/Comments:BIP-0328
  Status: Draft
  Type: Informational
  Created: 2024-01-15
  License: CC0-1.0
```

<h2>Abstract</h2>


This document specifies how BIP 32 extended public keys can be constructed from a BIP 327 MuSig2
aggregate public key and how such keys should be used for key derivation.

<h2>Copyright</h2>


This BIP is licensed under the Creative Commons CC0 1.0 Universal license.

<h2>Motivation</h2>


Multiple signers can create a single aggregate public key with MuSig2 that is indistinguishable
from a random public key. The cosigners need a method for generating additional aggregate pubkeys
to follow the best practice of using a new address for every payment.

The obvious method is for the cosigners to generate multiple public keys and produce a
new aggregate pubkey every time one is needed. This is similar to how multisig using Bitcoin script
works where all of the cosigners share their extended public keys and do derivation to produce
the multisig script. The same could be done with MuSig2 and instead of producing a multisig script,
the result would be a MuSig2 aggregate pubkey.

However, it is much simpler to be able to derive from a single extended public key instead of having
to derive from many extended public keys and aggregate them. As MuSig2 produces a normal looking
public key, the aggregate public can be used in this way. This reduces the storage and computation
requirements for generating new aggregate pubkeys.

<h2>Specification</h2>


A synthetic xpub can be created from a BIP 327 MuSig2 plain aggregate public key by setting
the depth to 0, the child number to 0, and attaching a chaincode with the byte string
<tt>868087ca02a6f974c4598924c36b57762d32cb45717167e300622c7167e38965</tt><ref>**Where does this
constant chaincode come from?** It is the SHA256 of the text <tt>MuSig2MuSig2MuSig2</tt></ref>.
This fixed chaincode should be used by all such synthetic xpubs following this specification.
Unhardened child public keys can be derived from the synthetic xpub as with any other xpub. Since
the aggregate public key is all that is necessary to produce the synthetic xpub, any aggregate
public key that will be used in this way shares the same privacy concerns as typical xpubs.

Furthermore, as there is no aggregate private key, only unhardened derivation from the aggregate
public key is possible.

When signing, all signers must compute the tweaks used in the BIP 32 derivation for the child key
being signed for. The I<sub>L</sub> value computed in _CKDpub_ is the tweak used at each
derivation step. These are provided in the session context, each with a tweak mode of plain
(_is_xonly_t = false_). When the _Sign_ algorithm is used, the tweaks will be applied to the
partial signatures.

<h2>Test Vectors</h2>


TBD

<h2>Backwards Compatibility</h2>


Once a synthetic xpub is created, it is fully backwards compatible with BIP 32 - only unhardened
derivation can be done, and the signers will be able to produce a signature for any derived children.

<h2>Rationale</h2>


<references/>

<h2>Reference Implementation</h2>


TBD

<h2>Acknowledgements</h2>


Thanks to Pieter Wuille, Andrew Poelstra, Sanket Kanjalkar, Salvatore Ingala, and all others who
participated in discussions on this topic.
