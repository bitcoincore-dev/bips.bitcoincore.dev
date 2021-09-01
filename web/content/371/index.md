+++
title = "Taproot Fields for PSBT"
date = 2021-06-21
weight = 371
in_search_index = true

[taxonomies]
authors = ["Andrew Chow"]
status = ["Draft"]

[extra]
bip = 371
status = ["Draft"]
github = "https://github.com/bitcoin/bips/blob/master/bip-0371.mediawiki"
+++

``` 
  BIP: 371
  Layer: Applications
  Title: Taproot Fields for PSBT
  Author: Andrew Chow <andrew@achow101.com>
  Comments-Summary: No comments yet.
  Comments-URI: https://github.com/bitcoin/bips/wiki/Comments:BIP-0371
  Status: Draft
  Type: Standards Track
  Created: 2021-06-21
  License: BSD-2-Clause
```

## Introduction

### Abstract

This document proposes additional fields for BIP 174 PSBTv0 and BIP 370
PSBTv2 that allow for BIP 340/341/342 Taproot data to be included in a
PSBT of any version. These will be fields for signatures and scripts
that are relevant to the creation of Taproot inputs.

### Copyright

This BIP is licensed under the 2-clause BSD license.

### Motivation

BIPs 340, 341, and 342 specify Taproot which provides a wholly new way
to create and spend Bitcoin outputs. The existing PSBT fields are unable
to support Taproot due to the new signature algorithm and the method by
which scripts are embedded inside of a Taproot output. Therefore new
fields must be defined to allow PSBTs to carry the information necessary
for signing Taproot inputs.

## Specification

The new per-input types are defined as follows:

<table>
<thead>
<tr class="header">
<th><p>Name</p></th>
<th><p><keytype></p></th>
<th><p><keydata></p></th>
<th><p><keydata> Description</p></th>
<th><p><valuedata></p></th>
<th><p><valuedata> Description</p></th>
<th><p>Versions Requiring Inclusion</p></th>
<th><p>Versions Requiring Exclusion</p></th>
<th><p>Versions Allowing Inclusion</p></th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td><p>Taproot Key Spend Signature</p></td>
<td><p><code>PSBT_IN_TAP_KEY_SIG = 0x13</code></p></td>
<td><p>None</p></td>
<td><p>No key data [1]</p></td>
<td><p><signature></p></td>
<td><p>The 64 or 65 byte Schnorr signature for key path spending a Taproot output. Finalizers should remove this field after <code>PSBT_IN_FINAL_SCRIPTWITNESS</code> is constructed.</p></td>
<td></td>
<td></td>
<td><p>0, 2</p></td>
</tr>
<tr class="even">
<td><p>Taproot Script Spend Signature</p></td>
<td><p><code>PSBT_IN_TAP_SCRIPT_SIG = 0x14</code></p></td>
<td><p><xonlypubkey><code> </code><leafhash></p></td>
<td><p>A 32 byte X-only public key involved in a leaf script concatenated with the 32 byte hash of the leaf it is part of.</p></td>
<td><p><signature></p></td>
<td><p>The 64 or 65 byte Schnorr signature for this pubkey and leaf combination. Finalizers should remove this field after <code>PSBT_IN_FINAL_SCRIPTWITNESS</code> is constructed.</p></td>
<td></td>
<td></td>
<td><p>0, 2</p></td>
</tr>
<tr class="odd">
<td><p>Taproot Leaf Script</p></td>
<td><p><code>PSBT_IN_TAP_LEAF_SCRIPT = 0x15</code></p></td>
<td><p><control block></p></td>
<td><p>The control block for this leaf as specified in BIP 341. The control block contains the merkle tree path to this leaf.</p></td>
<td><p><tt></p>
<script>
<p>&lt;8-bit uint&gt;</tt></p></td>
<td><p>The script for this leaf as would be provided in the witness stack followed by the single byte leaf version. Note that the leaves included in this field should be those that the signers of this input are expected to be able to sign for. Finalizers should remove this field after <code>PSBT_IN_FINAL_SCRIPTWITNESS</code> is constructed. Finalizers should remove this field after <code>PSBT_IN_FINAL_SCRIPTWITNESS</code> is constructed.</p></td>
<td></td>
<td></td>
<td><p>0, 2</p></td>
</tr>
<tr class="even">
<td><p>Taproot Key BIP 32 Derivation Path</p></td>
<td><p><code>PSBT_IN_TAP_BIP32_DERIVATION = 0x16</code></p></td>
<td><p><xonlypubkey></p></td>
<td><p>A 32 byte X-only public key involved in this input. It may be the internal key, or a key present in a leaf script.</p></td>
<td><p><hashes len><code> </code><leaf hash><code>* &lt;4 byte fingerprint&gt; &lt;32-bit uint&gt;*</code></p></td>
<td><p>A compact size unsigned integer representing the number of leaf hashes, followed by a list of leaf hashes, followed by the 4 byte master key fingerprint concatenated with the derivation path of the public key. The derivation path is represented as 32-bit little endian unsigned integer indexes concatenated with each other. Public keys are those needed to spend this output. The leaf hashes are of the leaves which involve this public key. The internal key does not have leaf hashes, so can be indicated with a <code>hashes len</code> of 0. Finalizers should remove this field after <code>PSBT_IN_FINAL_SCRIPTWITNESS</code> is constructed.</p></td>
<td></td>
<td></td>
<td><p>0, 2</p></td>
</tr>
<tr class="odd">
<td><p>Taproot Internal Key</p></td>
<td><p><code>PSBT_IN_TAP_INTERNAL_KEY = 0x17</code></p></td>
<td><p>None</p></td>
<td><p>No key data</p></td>
<td><p><pubkey></p></td>
<td><p>The X-only pubkey used as the internal key in this output.[2] Finalizers should remove this field after <code>PSBT_IN_FINAL_SCRIPTWITNESS</code> is constructed.</p></td>
<td></td>
<td></td>
<td><p>0, 2</p></td>
</tr>
<tr class="even">
<td><p>Taproot Merkle Root</p></td>
<td><p><code>PSBT_IN_TAP_MERKLE_ROOT = 0x18</code></p></td>
<td><p>None</p></td>
<td><p>No key data</p></td>
<td><p><pubkey></p></td>
<td><p>The 32 byte Merkle root hash. Finalizers should remove this field after <code>PSBT_IN_FINAL_SCRIPTWITNESS</code> is constructed.</p></td>
<td></td>
<td></td>
<td><p>0, 2</p></td>
</tr>
</tbody>
</table>

The new per-output types are defined as follows:

<table>
<thead>
<tr class="header">
<th><p>Name</p></th>
<th><p><keytype></p></th>
<th><p><keydata></p></th>
<th><p><keydata> Description</p></th>
<th><p><valuedata></p></th>
<th><p><valuedata> Description</p></th>
<th><p>Versions Requiring Inclusion</p></th>
<th><p>Versions Requiring Exclusion</p></th>
<th><p>Versions Allowing Inclusion</p></th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td><p>Taproot Internal Key</p></td>
<td><p><code>PSBT_OUT_TAP_INTERNAL_KEY = 0x05</code></p></td>
<td><p>None</p></td>
<td><p>No key data</p></td>
<td><p><pubkey></p></td>
<td><p>The X-only pubkey used as the internal key in this output.</p></td>
<td></td>
<td></td>
<td><p>0, 2</p></td>
</tr>
<tr class="even">
<td><p>Taproot Tree</p></td>
<td><p><code>PSBT_OUT_TAP_TREE = 0x06</code></p></td>
<td><p>None</p></td>
<td><p>No key data</p></td>
<td><p><tt>{&lt;8-bit uint depth&gt; &lt;8-bit uint leaf version&gt; <scriptlen></p>
<script>
<p>}*</tt></p></td>
<td><p>One or more tuples representing the depth, leaf version, and script for a leaf in the Taproot tree, allowing the entire tree to be reconstructed. The tuples must be in depth first search order so that the tree is correctly reconstructed. Each tuple is an 8-bit unsigned integer representing the depth in the Taproot tree for this script, an 8-bit unsigned integer representing the leaf version, the length of the script as a compact size unsigned integer, and the script itself.</p></td>
<td></td>
<td></td>
<td><p>0, 2</p></td>
</tr>
<tr class="odd">
<td><p>Taproot Key BIP 32 Derivation Path</p></td>
<td><p><code>PSBT_OUT_TAP_BIP32_DERIVATION = 0x07</code></p></td>
<td><p><xonlypubkey></p></td>
<td><p>A 32 byte X-only public key involved in this output. It may be the internal key, or a key present in a leaf script.</p></td>
<td><p><hashes len><code> </code><leaf hash><code>* &lt;4 byte fingerprint&gt; &lt;32-bit uint&gt;*</code></p></td>
<td><p>A compact size unsigned integer representing the number of leaf hashes, followed by a list of leaf hashes, followed by the 4 byte master key fingerprint concatenated with the derivation path of the public key. The derivation path is represented as 32-bit little endian unsigned integer indexes concatenated with each other. Public keys are those needed to spend this output. The leaf hashes are of the leaves which involve this public key. The internal key does not have leaf hashes, so can be indicated with a <code>hashes len</code> of 0. Finalizers should remove this field after <code>PSBT_IN_FINAL_SCRIPTWITNESS</code> is constructed.</p></td>
<td></td>
<td></td>
<td><p>0, 2</p></td>
</tr>
</tbody>
</table>

### UTXO Types

BIP 174 recommends using `PSBT_IN_NON_WITNESS_UTXO` for all inputs
because of potential attacks involving an updater lying about the
amounts in an output. Because a Taproot signature will commit to all of
the amounts and output scripts spent by the inputs of the transaction,
such attacks are prevented as any such lying would result in an invalid
signature. Thus Taproot inputs can use just `PSBT_IN_WITNESS_UTXO`.

## Compatibility

These are simply new fields added to the existing PSBT format. Because
PSBT is designed to be extensible, old software will ignore the new
fields.

## Test Vectors

The following are invalid PSBTs:

\* Case: PSBT With `PSBT_IN_TAP_INTERNAL_KEY` key that is too long
(incorrectly serialized as compressed DER)

\*\* Bytes in Hex:

    70736274ff010071020000000127744ababf3027fe0d6cf23a96eee2efb188ef52301954585883e69b6624b2420000000000ffffffff02787c01000000000016001483a7e34bd99ff03a4962ef8a1a101bb295461ece606b042a010000001600147ac369df1b20e033d6116623957b0ac49f3c52e8000000000001012b00f2052a010000002251205a2c2cf5b52cf31f83ad2e8da63ff03183ecd8f609c7510ae8a48e03910a075701172102fe349064c98d6e2a853fa3c9b12bd8b304a19c195c60efa7ee2393046d3fa232000000

  -   - Base64 String:
            cHNidP8BAHECAAAAASd0Srq/MCf+DWzyOpbu4u+xiO9SMBlUWFiD5ptmJLJCAAAAAAD/////Anh8AQAAAAAAFgAUg6fjS9mf8DpJYu+KGhAbspVGHs5gawQqAQAAABYAFHrDad8bIOAz1hFmI5V7CsSfPFLoAAAAAAABASsA8gUqAQAAACJRIFosLPW1LPMfg60ujaY/8DGD7Nj2CcdRCuikjgORCgdXARchAv40kGTJjW4qhT+jybEr2LMEoZwZXGDvp+4jkwRtP6IyAAAA

\* Case: PSBT With `PSBT_KEY_PATH_SIG` signature that is too short

\*\* Bytes in Hex:

    <70736274ff010071020000000127744ababf3027fe0d6cf23a96eee2efb188ef52301954585883e69b6624b2420000000000ffffffff02787c01000000000016001483a7e34bd99ff03a4962ef8a1a101bb295461ece606b042a010000001600147ac369df1b20e033d6116623957b0ac49f3c52e8000000000001012b00f2052a010000002251205a2c2cf5b52cf31f83ad2e8da63ff03183ecd8f609c7510ae8a48e03910a075701133f173bb3d36c074afb716fec6307a069a2e450b995f3c82785945ab8df0e24260dcd703b0cbf34de399184a9481ac2b3586db6601f026a77f7e4938481bc3475000000/pre>
    ** Base64 String: <pre>cHNidP8BAHECAAAAASd0Srq/MCf+DWzyOpbu4u+xiO9SMBlUWFiD5ptmJLJCAAAAAAD/////Anh8AQAAAAAAFgAUg6fjS9mf8DpJYu+KGhAbspVGHs5gawQqAQAAABYAFHrDad8bIOAz1hFmI5V7CsSfPFLoAAAAAAABASsA8gUqAQAAACJRIFosLPW1LPMfg60ujaY/8DGD7Nj2CcdRCuikjgORCgdXARM/Fzuz02wHSvtxb+xjB6BpouRQuZXzyCeFlFq43w4kJg3NcDsMvzTeOZGEqUgawrNYbbZgHwJqd/fkk4SBvDR1AAAAN/pre>
    
    * Case: PSBT With <tt>PSBT_KEY_PATH_SIG</tt> signature that is too long
    ** Bytes in Hex: <pre><70736274ff010071020000000127744ababf3027fe0d6cf23a96eee2efb188ef52301954585883e69b6624b2420000000000ffffffff02787c01000000000016001483a7e34bd99ff03a4962ef8a1a101bb295461ece606b042a010000001600147ac369df1b20e033d6116623957b0ac49f3c52e8000000000001012b00f2052a010000002251205a2c2cf5b52cf31f83ad2e8da63ff03183ecd8f609c7510ae8a48e03910a0757011342173bb3d36c074afb716fec6307a069a2e450b995f3c82785945ab8df0e24260dcd703b0cbf34de399184a9481ac2b3586db6601f026a77f7e4938481bc34751701aa000000/pre>
    ** Base64 String: <pre>cHNidP8BAHECAAAAASd0Srq/MCf+DWzyOpbu4u+xiO9SMBlUWFiD5ptmJLJCAAAAAAD/////Anh8AQAAAAAAFgAUg6fjS9mf8DpJYu+KGhAbspVGHs5gawQqAQAAABYAFHrDad8bIOAz1hFmI5V7CsSfPFLoAAAAAAABASsA8gUqAQAAACJRIFosLPW1LPMfg60ujaY/8DGD7Nj2CcdRCuikjgORCgdXARNCFzuz02wHSvtxb+xjB6BpouRQuZXzyCeFlFq43w4kJg3NcDsMvzTeOZGEqUgawrNYbbZgHwJqd/fkk4SBvDR1FwGqAAAA

  - Case: PSBT With `PSBT_IN_TAP_BIP32_DERIVATION` key that is too long
    (incorrectly serialized as compressed DER)
    \* Bytes in Hex:
        <70736274ff010071020000000127744ababf3027fe0d6cf23a96eee2efb188ef52301954585883e69b6624b2420000000000ffffffff02787c01000000000016001483a7e34bd99ff03a4962ef8a1a101bb295461ece606b042a010000001600147ac369df1b20e033d6116623957b0ac49f3c52e8000000000001012b00f2052a010000002251205a2c2cf5b52cf31f83ad2e8da63ff03183ecd8f609c7510ae8a48e03910a0757221602fe349064c98d6e2a853fa3c9b12bd8b304a19c195c60efa7ee2393046d3fa2321900772b2da75600008001000080000000800100000000000000000000/pre>
        * Base64 String: <pre>cHNidP8BAHECAAAAASd0Srq/MCf+DWzyOpbu4u+xiO9SMBlUWFiD5ptmJLJCAAAAAAD/////Anh8AQAAAAAAFgAUg6fjS9mf8DpJYu+KGhAbspVGHs5gawQqAQAAABYAFHrDad8bIOAz1hFmI5V7CsSfPFLoAAAAAAABASsA8gUqAQAAACJRIFosLPW1LPMfg60ujaY/8DGD7Nj2CcdRCuikjgORCgdXIhYC/jSQZMmNbiqFP6PJsSvYswShnBlcYO+n7iOTBG0/ojIZAHcrLadWAACAAQAAgAAAAIABAAAAAAAAAAAAAA==

<!-- end list -->

  - Case: PSBT With `PSBT_OUT_TAP_INTERNAL_KEY` key that is too long
    (incorrectly serialized as compressed DER)
      - Bytes in Hex:
            70736274ff01007d020000000127744ababf3027fe0d6cf23a96eee2efb188ef52301954585883e69b6624b2420000000000ffffffff02887b0100000000001600142382871c7e8421a00093f754d91281e675874b9f606b042a010000002251205a2c2cf5b52cf31f83ad2e8da63ff03183ecd8f609c7510ae8a48e03910a0757000000000001012b00f2052a010000002251205a2c2cf5b52cf31f83ad2e8da63ff03183ecd8f609c7510ae8a48e03910a0757000001052102fe349064c98d6e2a853fa3c9b12bd8b304a19c195c60efa7ee2393046d3fa23200
      - Base64 String:
            cHNidP8BAH0CAAAAASd0Srq/MCf+DWzyOpbu4u+xiO9SMBlUWFiD5ptmJLJCAAAAAAD/////Aoh7AQAAAAAAFgAUI4KHHH6EIaAAk/dU2RKB5nWHS59gawQqAQAAACJRIFosLPW1LPMfg60ujaY/8DGD7Nj2CcdRCuikjgORCgdXAAAAAAABASsA8gUqAQAAACJRIFosLPW1LPMfg60ujaY/8DGD7Nj2CcdRCuikjgORCgdXAAABBSEC/jSQZMmNbiqFP6PJsSvYswShnBlcYO+n7iOTBG0/ojIA

<!-- end list -->

  - Case: PSBT With `PSBT_OUT_TAP_BIP32_DERIVATION` key that is too long
    (incorrectly serialized as compressed DER)
      - Bytes in Hex:
            70736274ff01007d020000000127744ababf3027fe0d6cf23a96eee2efb188ef52301954585883e69b6624b2420000000000ffffffff02887b0100000000001600142382871c7e8421a00093f754d91281e675874b9f606b042a010000002251205a2c2cf5b52cf31f83ad2e8da63ff03183ecd8f609c7510ae8a48e03910a0757000000000001012b00f2052a010000002251205a2c2cf5b52cf31f83ad2e8da63ff03183ecd8f609c7510ae8a48e03910a07570000220702fe349064c98d6e2a853fa3c9b12bd8b304a19c195c60efa7ee2393046d3fa2321900772b2da7560000800100008000000080010000000000000000
      - Base64 String:
            cHNidP8BAH0CAAAAASd0Srq/MCf+DWzyOpbu4u+xiO9SMBlUWFiD5ptmJLJCAAAAAAD/////Aoh7AQAAAAAAFgAUI4KHHH6EIaAAk/dU2RKB5nWHS59gawQqAQAAACJRIFosLPW1LPMfg60ujaY/8DGD7Nj2CcdRCuikjgORCgdXAAAAAAABASsA8gUqAQAAACJRIFosLPW1LPMfg60ujaY/8DGD7Nj2CcdRCuikjgORCgdXAAAiBwL+NJBkyY1uKoU/o8mxK9izBKGcGVxg76fuI5MEbT+iMhkAdystp1YAAIABAACAAAAAgAEAAAAAAAAAAA==

<!-- end list -->

  - Case: PSBT With `PSBT_IN_TAP_SCRIPT_SIG` key that is too long
    (incorrectly serialized as compressed DER)
      - Bytes in Hex:
            70736274ff01005e02000000019bd48765230bf9a72e662001f972556e54f0c6f97feb56bcb5600d817f6995260100000000ffffffff0148e6052a01000000225120030da4fce4f7db28c2cb2951631e003713856597fe963882cb500e68112cca63000000000001012b00f2052a01000000225120c2247efbfd92ac47f6f40b8d42d169175a19fa9fa10e4a25d7f35eb4dd85b6924214022cb13ac68248de806aa6a3659cf3c03eb6821d09c8114a4e868febde865bb6d2cd970e15f53fc0c82f950fd560ffa919b76172be017368a89913af074f400b094089756aa3739ccc689ec0fcf3a360be32cc0b59b16e93a1e8bb4605726b2ca7a3ff706c4176649632b2cc68e1f912b8a578e3719ce7710885c7a966f49bcd43cb0000
      - Base64 String:
            cHNidP8BAF4CAAAAAZvUh2UjC/mnLmYgAflyVW5U8Mb5f+tWvLVgDYF/aZUmAQAAAAD/////AUjmBSoBAAAAIlEgAw2k/OT32yjCyylRYx4ANxOFZZf+ljiCy1AOaBEsymMAAAAAAAEBKwDyBSoBAAAAIlEgwiR++/2SrEf29AuNQtFpF1oZ+p+hDkol1/NetN2FtpJCFAIssTrGgkjegGqmo2Wc88A+toIdCcgRSk6Gj+vehlu20s2XDhX1P8DIL5UP1WD/qRm3YXK+AXNoqJkTrwdPQAsJQIl1aqNznMxonsD886NgvjLMC1mxbpOh6LtGBXJrLKej/3BsQXZkljKyzGjh+RK4pXjjcZzncQiFx6lm9JvNQ8sAAA==

<!-- end list -->

  - Case: PSBT With `PSBT_IN_TAP_SCRIPT_SIG` signature that is too long
      - Bytes in Hex:
            <0736274ff01005e02000000019bd48765230bf9a72e662001f972556e54f0c6f97feb56bcb5600d817f6995260100000000ffffffff0148e6052a01000000225120030da4fce4f7db28c2cb2951631e003713856597fe963882cb500e68112cca63000000000001012b00f2052a01000000225120c2247efbfd92ac47f6f40b8d42d169175a19fa9fa10e4a25d7f35eb4dd85b69241142cb13ac68248de806aa6a3659cf3c03eb6821d09c8114a4e868febde865bb6d2cd970e15f53fc0c82f950fd560ffa919b76172be017368a89913af074f400b094289756aa3739ccc689ec0fcf3a360be32cc0b59b16e93a1e8bb4605726b2ca7a3ff706c4176649632b2cc68e1f912b8a578e3719ce7710885c7a966f49bcd43cb01010000
      - Base64 String:
            cHNidP8BAF4CAAAAAZvUh2UjC/mnLmYgAflyVW5U8Mb5f+tWvLVgDYF/aZUmAQAAAAD/////AUjmBSoBAAAAIlEgAw2k/OT32yjCyylRYx4ANxOFZZf+ljiCy1AOaBEsymMAAAAAAAEBKwDyBSoBAAAAIlEgwiR++/2SrEf29AuNQtFpF1oZ+p+hDkol1/NetN2FtpJBFCyxOsaCSN6AaqajZZzzwD62gh0JyBFKToaP696GW7bSzZcOFfU/wMgvlQ/VYP+pGbdhcr4Bc2iomROvB09ACwlCiXVqo3OczGiewPzzo2C+MswLWbFuk6Hou0YFcmssp6P/cGxBdmSWMrLMaOH5ErileONxnOdxCIXHqWb0m81DywEBAAA=

<!-- end list -->

  - Case: PSBT With `PSBT_IN_TAP_SCRIPT_SIG` signature that is too short
    \* Bytes in Hex:
        <70736274ff01005e02000000019bd48765230bf9a72e662001f972556e54f0c6f97feb56bcb5600d817f6995260100000000ffffffff0148e6052a01000000225120030da4fce4f7db28c2cb2951631e003713856597fe963882cb500e68112cca63000000000001012b00f2052a01000000225120c2247efbfd92ac47f6f40b8d42d169175a19fa9fa10e4a25d7f35eb4dd85b69241142cb13ac68248de806aa6a3659cf3c03eb6821d09c8114a4e868febde865bb6d2cd970e15f53fc0c82f950fd560ffa919b76172be017368a89913af074f400b093989756aa3739ccc689ec0fcf3a360be32cc0b59b16e93a1e8bb4605726b2ca7a3ff706c4176649632b2cc68e1f912b8a578e3719ce7710885c7a966f49bcd43cb0000/pre>
        * Base64 String: <pre>cHNidP8BAF4CAAAAAZvUh2UjC/mnLmYgAflyVW5U8Mb5f+tWvLVgDYF/aZUmAQAAAAD/////AUjmBSoBAAAAIlEgAw2k/OT32yjCyylRYx4ANxOFZZf+ljiCy1AOaBEsymMAAAAAAAEBKwDyBSoBAAAAIlEgwiR++/2SrEf29AuNQtFpF1oZ+p+hDkol1/NetN2FtpJBFCyxOsaCSN6AaqajZZzzwD62gh0JyBFKToaP696GW7bSzZcOFfU/wMgvlQ/VYP+pGbdhcr4Bc2iomROvB09ACwk5iXVqo3OczGiewPzzo2C+MswLWbFuk6Hou0YFcmssp6P/cGxBdmSWMrLMaOH5ErileONxnOdxCIXHqWb0m81DywAA

<!-- end list -->

  - Case: PSBT With `PSBT_IN_TAP_LEAF_SCRIPT` Control block that is too
    long
      - Bytes in Hex:
            70736274ff01005e02000000019bd48765230bf9a72e662001f972556e54f0c6f97feb56bcb5600d817f6995260100000000ffffffff0148e6052a01000000225120030da4fce4f7db28c2cb2951631e003713856597fe963882cb500e68112cca63000000000001012b00f2052a01000000225120c2247efbfd92ac47f6f40b8d42d169175a19fa9fa10e4a25d7f35eb4dd85b6926315c150929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac06f7d62059e9497a1a4a267569d9876da60101aff38e3529b9b939ce7f91ae970115f2e490af7cc45c4f78511f36057ce5c5a5c56325a29fb44dfc203f356e1f80023202cb13ac68248de806aa6a3659cf3c03eb6821d09c8114a4e868febde865bb6d2acc00000
      - Base64 String:
            cHNidP8BAF4CAAAAAZvUh2UjC/mnLmYgAflyVW5U8Mb5f+tWvLVgDYF/aZUmAQAAAAD/////AUjmBSoBAAAAIlEgAw2k/OT32yjCyylRYx4ANxOFZZf+ljiCy1AOaBEsymMAAAAAAAEBKwDyBSoBAAAAIlEgwiR++/2SrEf29AuNQtFpF1oZ+p+hDkol1/NetN2FtpJjFcFQkpt0waBJVLeLS2A16XpeB4paDyjsltVHv+6azoA6wG99YgWelJehpKJnVp2YdtpgEBr/OONSm5uTnOf5GulwEV8uSQr3zEXE94UR82BXzlxaXFYyWin7RN/CA/NW4fgAIyAssTrGgkjegGqmo2Wc88A+toIdCcgRSk6Gj+vehlu20qzAAAA=

<!-- end list -->

  - Case: PSBT With `PSBT_IN_TAP_LEAF_SCRIPT` Control block that is too
    short
      - Bytes in Hex:
            70736274ff01005e02000000019bd48765230bf9a72e662001f972556e54f0c6f97feb56bcb5600d817f6995260100000000ffffffff0148e6052a01000000225120030da4fce4f7db28c2cb2951631e003713856597fe963882cb500e68112cca63000000000001012b00f2052a01000000225120c2247efbfd92ac47f6f40b8d42d169175a19fa9fa10e4a25d7f35eb4dd85b6926115c150929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac06f7d62059e9497a1a4a267569d9876da60101aff38e3529b9b939ce7f91ae970115f2e490af7cc45c4f78511f36057ce5c5a5c56325a29fb44dfc203f356e123202cb13ac68248de806aa6a3659cf3c03eb6821d09c8114a4e868febde865bb6d2acc00000
      - Base64 String:
            cHNidP8BAF4CAAAAAZvUh2UjC/mnLmYgAflyVW5U8Mb5f+tWvLVgDYF/aZUmAQAAAAD/////AUjmBSoBAAAAIlEgAw2k/OT32yjCyylRYx4ANxOFZZf+ljiCy1AOaBEsymMAAAAAAAEBKwDyBSoBAAAAIlEgwiR++/2SrEf29AuNQtFpF1oZ+p+hDkol1/NetN2FtpJhFcFQkpt0waBJVLeLS2A16XpeB4paDyjsltVHv+6azoA6wG99YgWelJehpKJnVp2YdtpgEBr/OONSm5uTnOf5GulwEV8uSQr3zEXE94UR82BXzlxaXFYyWin7RN/CA/NW4SMgLLE6xoJI3oBqpqNlnPPAPraCHQnIEUpOho/r3oZbttKswAAA

The following are valid PSBTs:

  - Case: PSBT with one P2TR key only input with internal key and its
    derivation path
      - Bytes in Hex:
            70736274ff010052020000000127744ababf3027fe0d6cf23a96eee2efb188ef52301954585883e69b6624b2420000000000ffffffff0148e6052a01000000160014768e1eeb4cf420866033f80aceff0f9720744969000000000001012b00f2052a010000002251205a2c2cf5b52cf31f83ad2e8da63ff03183ecd8f609c7510ae8a48e03910a07572116fe349064c98d6e2a853fa3c9b12bd8b304a19c195c60efa7ee2393046d3fa2321900772b2da75600008001000080000000800100000000000000011720fe349064c98d6e2a853fa3c9b12bd8b304a19c195c60efa7ee2393046d3fa232002202036b772a6db74d8753c98a827958de6c78ab3312109f37d3e0304484242ece73d818772b2da7540000800100008000000080000000000000000000
      - Base64 String:
            cHNidP8BAFICAAAAASd0Srq/MCf+DWzyOpbu4u+xiO9SMBlUWFiD5ptmJLJCAAAAAAD/////AUjmBSoBAAAAFgAUdo4e60z0IIZgM/gKzv8PlyB0SWkAAAAAAAEBKwDyBSoBAAAAIlEgWiws9bUs8x+DrS6Npj/wMYPs2PYJx1EK6KSOA5EKB1chFv40kGTJjW4qhT+jybEr2LMEoZwZXGDvp+4jkwRtP6IyGQB3Ky2nVgAAgAEAAIAAAACAAQAAAAAAAAABFyD+NJBkyY1uKoU/o8mxK9izBKGcGVxg76fuI5MEbT+iMgAiAgNrdyptt02HU8mKgnlY3mx4qzMSEJ830+AwRIQkLs5z2Bh3Ky2nVAAAgAEAAIAAAACAAAAAAAAAAAAA

<!-- end list -->

  - Case: PSBT with one P2TR key only input with internal key, its
    derivation path, and signature
      - Bytes in Hex:
            70736274ff010052020000000127744ababf3027fe0d6cf23a96eee2efb188ef52301954585883e69b6624b2420000000000ffffffff0148e6052a01000000160014768e1eeb4cf420866033f80aceff0f9720744969000000000001012b00f2052a010000002251205a2c2cf5b52cf31f83ad2e8da63ff03183ecd8f609c7510ae8a48e03910a0757011340bb53ec917bad9d906af1ba87181c48b86ace5aae2b53605a725ca74625631476fc6f5baedaf4f2ee0f477f36f58f3970d5b8273b7e497b97af2e3f125c97af342116fe349064c98d6e2a853fa3c9b12bd8b304a19c195c60efa7ee2393046d3fa2321900772b2da75600008001000080000000800100000000000000011720fe349064c98d6e2a853fa3c9b12bd8b304a19c195c60efa7ee2393046d3fa232002202036b772a6db74d8753c98a827958de6c78ab3312109f37d3e0304484242ece73d818772b2da7540000800100008000000080000000000000000000
      - Base64 String:
            cHNidP8BAFICAAAAASd0Srq/MCf+DWzyOpbu4u+xiO9SMBlUWFiD5ptmJLJCAAAAAAD/////AUjmBSoBAAAAFgAUdo4e60z0IIZgM/gKzv8PlyB0SWkAAAAAAAEBKwDyBSoBAAAAIlEgWiws9bUs8x+DrS6Npj/wMYPs2PYJx1EK6KSOA5EKB1cBE0C7U+yRe62dkGrxuocYHEi4as5aritTYFpyXKdGJWMUdvxvW67a9PLuD0d/NvWPOXDVuCc7fkl7l68uPxJcl680IRb+NJBkyY1uKoU/o8mxK9izBKGcGVxg76fuI5MEbT+iMhkAdystp1YAAIABAACAAAAAgAEAAAAAAAAAARcg/jSQZMmNbiqFP6PJsSvYswShnBlcYO+n7iOTBG0/ojIAIgIDa3cqbbdNh1PJioJ5WN5seKszEhCfN9PgMESEJC7Oc9gYdystp1QAAIABAACAAAAAgAAAAAAAAAAAAA==

<!-- end list -->

  - Case: PSBT with one P2TR key only output with internal key and its
    derivation path
      - Bytes in Hex:
            70736274ff01005e020000000127744ababf3027fe0d6cf23a96eee2efb188ef52301954585883e69b6624b2420000000000ffffffff0148e6052a0100000022512083698e458c6664e1595d75da2597de1e22ee97d798e706c4c0a4b5a9823cd743000000000001012b00f2052a010000002251205a2c2cf5b52cf31f83ad2e8da63ff03183ecd8f609c7510ae8a48e03910a07572116fe349064c98d6e2a853fa3c9b12bd8b304a19c195c60efa7ee2393046d3fa2321900772b2da75600008001000080000000800100000000000000011720fe349064c98d6e2a853fa3c9b12bd8b304a19c195c60efa7ee2393046d3fa232000105201124da7aec92ccd06c954562647f437b138b95721a84be2bf2276bbddab3e67121071124da7aec92ccd06c954562647f437b138b95721a84be2bf2276bbddab3e6711900772b2da7560000800100008000000080000000000500000000
      - Base64 String:
            cHNidP8BAF4CAAAAASd0Srq/MCf+DWzyOpbu4u+xiO9SMBlUWFiD5ptmJLJCAAAAAAD/////AUjmBSoBAAAAIlEgg2mORYxmZOFZXXXaJZfeHiLul9eY5wbEwKS1qYI810MAAAAAAAEBKwDyBSoBAAAAIlEgWiws9bUs8x+DrS6Npj/wMYPs2PYJx1EK6KSOA5EKB1chFv40kGTJjW4qhT+jybEr2LMEoZwZXGDvp+4jkwRtP6IyGQB3Ky2nVgAAgAEAAIAAAACAAQAAAAAAAAABFyD+NJBkyY1uKoU/o8mxK9izBKGcGVxg76fuI5MEbT+iMgABBSARJNp67JLM0GyVRWJkf0N7E4uVchqEvivyJ2u92rPmcSEHESTaeuySzNBslUViZH9DexOLlXIahL4r8idrvdqz5nEZAHcrLadWAACAAQAAgAAAAIAAAAAABQAAAAA=

<!-- end list -->

  - Case: PSBT with one P2TR script path only input with dummy internal
    key, scripts, derivation paths for keys in the scripts, and merkle
    root
      - Bytes in Hex:
            70736274ff01005e02000000019bd48765230bf9a72e662001f972556e54f0c6f97feb56bcb5600d817f6995260100000000ffffffff0148e6052a0100000022512083698e458c6664e1595d75da2597de1e22ee97d798e706c4c0a4b5a9823cd743000000000001012b00f2052a01000000225120c2247efbfd92ac47f6f40b8d42d169175a19fa9fa10e4a25d7f35eb4dd85b6926215c150929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac06f7d62059e9497a1a4a267569d9876da60101aff38e3529b9b939ce7f91ae970115f2e490af7cc45c4f78511f36057ce5c5a5c56325a29fb44dfc203f356e1f823202cb13ac68248de806aa6a3659cf3c03eb6821d09c8114a4e868febde865bb6d2acc04215c150929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac097c6e6fea5ff714ff5724499990810e406e98aa10f5bf7e5f6784bc1d0a9a6ce23204320b0bf16f011b53ea7be615924aa7f27e5d29ad20ea1155d848676c3bad1b2acc06215c150929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0cd970e15f53fc0c82f950fd560ffa919b76172be017368a89913af074f400b09115f2e490af7cc45c4f78511f36057ce5c5a5c56325a29fb44dfc203f356e1f82320fa0f7a3cef3b1d0c0a6ce7d26e17ada0b2e5c92d19efad48b41859cb8a451ca9acc021162cb13ac68248de806aa6a3659cf3c03eb6821d09c8114a4e868febde865bb6d23901cd970e15f53fc0c82f950fd560ffa919b76172be017368a89913af074f400b09772b2da7560000800100008002000080000000000000000021164320b0bf16f011b53ea7be615924aa7f27e5d29ad20ea1155d848676c3bad1b23901115f2e490af7cc45c4f78511f36057ce5c5a5c56325a29fb44dfc203f356e1f8772b2da75600008001000080010000800000000000000000211650929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac005007c461e5d2116fa0f7a3cef3b1d0c0a6ce7d26e17ada0b2e5c92d19efad48b41859cb8a451ca939016f7d62059e9497a1a4a267569d9876da60101aff38e3529b9b939ce7f91ae970772b2da7560000800100008003000080000000000000000001172050929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0011820f0362e2f75a6f420a5bde3eb221d96ae6720cf25f81890c95b1d775acb515e65000105201124da7aec92ccd06c954562647f437b138b95721a84be2bf2276bbddab3e67121071124da7aec92ccd06c954562647f437b138b95721a84be2bf2276bbddab3e6711900772b2da7560000800100008000000080000000000500000000
      - Base64 String:
            cHNidP8BAF4CAAAAAZvUh2UjC/mnLmYgAflyVW5U8Mb5f+tWvLVgDYF/aZUmAQAAAAD/////AUjmBSoBAAAAIlEgg2mORYxmZOFZXXXaJZfeHiLul9eY5wbEwKS1qYI810MAAAAAAAEBKwDyBSoBAAAAIlEgwiR++/2SrEf29AuNQtFpF1oZ+p+hDkol1/NetN2FtpJiFcFQkpt0waBJVLeLS2A16XpeB4paDyjsltVHv+6azoA6wG99YgWelJehpKJnVp2YdtpgEBr/OONSm5uTnOf5GulwEV8uSQr3zEXE94UR82BXzlxaXFYyWin7RN/CA/NW4fgjICyxOsaCSN6AaqajZZzzwD62gh0JyBFKToaP696GW7bSrMBCFcFQkpt0waBJVLeLS2A16XpeB4paDyjsltVHv+6azoA6wJfG5v6l/3FP9XJEmZkIEOQG6YqhD1v35fZ4S8HQqabOIyBDILC/FvARtT6nvmFZJKp/J+XSmtIOoRVdhIZ2w7rRsqzAYhXBUJKbdMGgSVS3i0tgNel6XgeKWg8o7JbVR7/ums6AOsDNlw4V9T/AyC+VD9Vg/6kZt2FyvgFzaKiZE68HT0ALCRFfLkkK98xFxPeFEfNgV85cWlxWMlop+0TfwgPzVuH4IyD6D3o87zsdDAps59JuF62gsuXJLRnvrUi0GFnLikUcqazAIRYssTrGgkjegGqmo2Wc88A+toIdCcgRSk6Gj+vehlu20jkBzZcOFfU/wMgvlQ/VYP+pGbdhcr4Bc2iomROvB09ACwl3Ky2nVgAAgAEAAIACAACAAAAAAAAAAAAhFkMgsL8W8BG1Pqe+YVkkqn8n5dKa0g6hFV2EhnbDutGyOQERXy5JCvfMRcT3hRHzYFfOXFpcVjJaKftE38ID81bh+HcrLadWAACAAQAAgAEAAIAAAAAAAAAAACEWUJKbdMGgSVS3i0tgNel6XgeKWg8o7JbVR7/ums6AOsAFAHxGHl0hFvoPejzvOx0MCmzn0m4XraCy5cktGe+tSLQYWcuKRRypOQFvfWIFnpSXoaSiZ1admHbaYBAa/zjjUpubk5zn+RrpcHcrLadWAACAAQAAgAMAAIAAAAAAAAAAAAEXIFCSm3TBoElUt4tLYDXpel4HiloPKOyW1Ue/7prOgDrAARgg8DYuL3Wm9CClvePrIh2WrmcgzyX4GJDJWx13WstRXmUAAQUgESTaeuySzNBslUViZH9DexOLlXIahL4r8idrvdqz5nEhBxEk2nrskszQbJVFYmR/Q3sTi5VyGoS+K/Ina73as+ZxGQB3Ky2nVgAAgAEAAIAAAACAAAAAAAUAAAAA

<!-- end list -->

  - Case: PSBT with one P2TR script path only output with dummy internal
    key, taproot tree, and script key derivation paths
      - Bytes in Hex:
            70736274ff01005e020000000127744ababf3027fe0d6cf23a96eee2efb188ef52301954585883e69b6624b2420000000000ffffffff0148e6052a010000002251200a8cbdc86de1ce1c0f9caeb22d6df7ced3683fe423e05d1e402a879341d6f6f5000000000001012b00f2052a010000002251205a2c2cf5b52cf31f83ad2e8da63ff03183ecd8f609c7510ae8a48e03910a07572116fe349064c98d6e2a853fa3c9b12bd8b304a19c195c60efa7ee2393046d3fa2321900772b2da75600008001000080000000800100000000000000011720fe349064c98d6e2a853fa3c9b12bd8b304a19c195c60efa7ee2393046d3fa2320001052050929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac001066f02c02220736e572900fe1252589a2143c8f3c79f71a0412d2353af755e9701c782694a02ac02c02220631c5f3b5832b8fbdebfb19704ceeb323c21f40f7a24f43d68ef0cc26b125969ac01c0222044faa49a0338de488c8dfffecdfb6f329f380bd566ef20c8df6d813eab1c4273ac210744faa49a0338de488c8dfffecdfb6f329f380bd566ef20c8df6d813eab1c42733901f06b798b92a10ed9a9d0bbfd3af173a53b1617da3a4159ca008216cd856b2e0e772b2da75600008001000080010000800000000003000000210750929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac005007c461e5d2107631c5f3b5832b8fbdebfb19704ceeb323c21f40f7a24f43d68ef0cc26b125969390118ace409889785e0ea70ceebb8e1ca892a7a78eaede0f2e296cf435961a8f4ca772b2da756000080010000800200008000000000030000002107736e572900fe1252589a2143c8f3c79f71a0412d2353af755e9701c782694a02390129a5b4915090162d759afd3fe0f93fa3326056d0b4088cb933cae7826cb8d82c772b2da7560000800100008003000080000000000300000000
      - Base64 String:
            cHNidP8BAF4CAAAAASd0Srq/MCf+DWzyOpbu4u+xiO9SMBlUWFiD5ptmJLJCAAAAAAD/////AUjmBSoBAAAAIlEgCoy9yG3hzhwPnK6yLW33ztNoP+Qj4F0eQCqHk0HW9vUAAAAAAAEBKwDyBSoBAAAAIlEgWiws9bUs8x+DrS6Npj/wMYPs2PYJx1EK6KSOA5EKB1chFv40kGTJjW4qhT+jybEr2LMEoZwZXGDvp+4jkwRtP6IyGQB3Ky2nVgAAgAEAAIAAAACAAQAAAAAAAAABFyD+NJBkyY1uKoU/o8mxK9izBKGcGVxg76fuI5MEbT+iMgABBSBQkpt0waBJVLeLS2A16XpeB4paDyjsltVHv+6azoA6wAEGbwLAIiBzblcpAP4SUliaIUPI88efcaBBLSNTr3VelwHHgmlKAqwCwCIgYxxfO1gyuPvev7GXBM7rMjwh9A96JPQ9aO8MwmsSWWmsAcAiIET6pJoDON5IjI3//s37bzKfOAvVZu8gyN9tgT6rHEJzrCEHRPqkmgM43kiMjf/+zftvMp84C9Vm7yDI322BPqscQnM5AfBreYuSoQ7ZqdC7/Trxc6U7FhfaOkFZygCCFs2Fay4Odystp1YAAIABAACAAQAAgAAAAAADAAAAIQdQkpt0waBJVLeLS2A16XpeB4paDyjsltVHv+6azoA6wAUAfEYeXSEHYxxfO1gyuPvev7GXBM7rMjwh9A96JPQ9aO8MwmsSWWk5ARis5AmIl4Xg6nDO67jhyokqenjq7eDy4pbPQ1lhqPTKdystp1YAAIABAACAAgAAgAAAAAADAAAAIQdzblcpAP4SUliaIUPI88efcaBBLSNTr3VelwHHgmlKAjkBKaW0kVCQFi11mv0/4Pk/ozJgVtC0CIy5M8rngmy42Cx3Ky2nVgAAgAEAAIADAACAAAAAAAMAAAAA

<!-- end list -->

  - Case: PSBT with one P2TR script path only input with dummy internal
    key, scripts, script key derivation paths, merkle root, and script
    path signatures
      - Bytes in Hex:
            70736274ff01005e02000000019bd48765230bf9a72e662001f972556e54f0c6f97feb56bcb5600d817f6995260100000000ffffffff0148e6052a0100000022512083698e458c6664e1595d75da2597de1e22ee97d798e706c4c0a4b5a9823cd743000000000001012b00f2052a01000000225120c2247efbfd92ac47f6f40b8d42d169175a19fa9fa10e4a25d7f35eb4dd85b69241142cb13ac68248de806aa6a3659cf3c03eb6821d09c8114a4e868febde865bb6d2cd970e15f53fc0c82f950fd560ffa919b76172be017368a89913af074f400b0940bf818d9757d6ffeb538ba057fb4c1fc4e0f5ef186e765beb564791e02af5fd3d5e2551d4e34e33d86f276b82c99c79aed3f0395a081efcd2cc2c65dd7e693d7941144320b0bf16f011b53ea7be615924aa7f27e5d29ad20ea1155d848676c3bad1b2115f2e490af7cc45c4f78511f36057ce5c5a5c56325a29fb44dfc203f356e1f840e1f1ab6fabfa26b236f21833719dc1d428ab768d80f91f9988d8abef47bfb863bb1f2a529f768c15f00ce34ec283cdc07e88f8428be28f6ef64043c32911811a4114fa0f7a3cef3b1d0c0a6ce7d26e17ada0b2e5c92d19efad48b41859cb8a451ca96f7d62059e9497a1a4a267569d9876da60101aff38e3529b9b939ce7f91ae97040ec1f0379206461c83342285423326708ab031f0da4a253ee45aafa5b8c92034d8b605490f8cd13e00f989989b97e215faa36f12dee3693d2daccf3781c1757f66215c150929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac06f7d62059e9497a1a4a267569d9876da60101aff38e3529b9b939ce7f91ae970115f2e490af7cc45c4f78511f36057ce5c5a5c56325a29fb44dfc203f356e1f823202cb13ac68248de806aa6a3659cf3c03eb6821d09c8114a4e868febde865bb6d2acc04215c150929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac097c6e6fea5ff714ff5724499990810e406e98aa10f5bf7e5f6784bc1d0a9a6ce23204320b0bf16f011b53ea7be615924aa7f27e5d29ad20ea1155d848676c3bad1b2acc06215c150929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0cd970e15f53fc0c82f950fd560ffa919b76172be017368a89913af074f400b09115f2e490af7cc45c4f78511f36057ce5c5a5c56325a29fb44dfc203f356e1f82320fa0f7a3cef3b1d0c0a6ce7d26e17ada0b2e5c92d19efad48b41859cb8a451ca9acc021162cb13ac68248de806aa6a3659cf3c03eb6821d09c8114a4e868febde865bb6d23901cd970e15f53fc0c82f950fd560ffa919b76172be017368a89913af074f400b09772b2da7560000800100008002000080000000000000000021164320b0bf16f011b53ea7be615924aa7f27e5d29ad20ea1155d848676c3bad1b23901115f2e490af7cc45c4f78511f36057ce5c5a5c56325a29fb44dfc203f356e1f8772b2da75600008001000080010000800000000000000000211650929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac005007c461e5d2116fa0f7a3cef3b1d0c0a6ce7d26e17ada0b2e5c92d19efad48b41859cb8a451ca939016f7d62059e9497a1a4a267569d9876da60101aff38e3529b9b939ce7f91ae970772b2da7560000800100008003000080000000000000000001172050929b74c1a04954b78b4b6035e97a5e078a5a0f28ec96d547bfee9ace803ac0011820f0362e2f75a6f420a5bde3eb221d96ae6720cf25f81890c95b1d775acb515e65000105201124da7aec92ccd06c954562647f437b138b95721a84be2bf2276bbddab3e67121071124da7aec92ccd06c954562647f437b138b95721a84be2bf2276bbddab3e6711900772b2da7560000800100008000000080000000000500000000
      - Base64 String:
            cHNidP8BAF4CAAAAAZvUh2UjC/mnLmYgAflyVW5U8Mb5f+tWvLVgDYF/aZUmAQAAAAD/////AUjmBSoBAAAAIlEgg2mORYxmZOFZXXXaJZfeHiLul9eY5wbEwKS1qYI810MAAAAAAAEBKwDyBSoBAAAAIlEgwiR++/2SrEf29AuNQtFpF1oZ+p+hDkol1/NetN2FtpJBFCyxOsaCSN6AaqajZZzzwD62gh0JyBFKToaP696GW7bSzZcOFfU/wMgvlQ/VYP+pGbdhcr4Bc2iomROvB09ACwlAv4GNl1fW/+tTi6BX+0wfxOD17xhudlvrVkeR4Cr1/T1eJVHU404z2G8na4LJnHmu0/A5Wgge/NLMLGXdfmk9eUEUQyCwvxbwEbU+p75hWSSqfyfl0prSDqEVXYSGdsO60bIRXy5JCvfMRcT3hRHzYFfOXFpcVjJaKftE38ID81bh+EDh8atvq/omsjbyGDNxncHUKKt2jYD5H5mI2KvvR7+4Y7sfKlKfdowV8AzjTsKDzcB+iPhCi+KPbvZAQ8MpEYEaQRT6D3o87zsdDAps59JuF62gsuXJLRnvrUi0GFnLikUcqW99YgWelJehpKJnVp2YdtpgEBr/OONSm5uTnOf5GulwQOwfA3kgZGHIM0IoVCMyZwirAx8NpKJT7kWq+luMkgNNi2BUkPjNE+APmJmJuX4hX6o28S3uNpPS2szzeBwXV/ZiFcFQkpt0waBJVLeLS2A16XpeB4paDyjsltVHv+6azoA6wG99YgWelJehpKJnVp2YdtpgEBr/OONSm5uTnOf5GulwEV8uSQr3zEXE94UR82BXzlxaXFYyWin7RN/CA/NW4fgjICyxOsaCSN6AaqajZZzzwD62gh0JyBFKToaP696GW7bSrMBCFcFQkpt0waBJVLeLS2A16XpeB4paDyjsltVHv+6azoA6wJfG5v6l/3FP9XJEmZkIEOQG6YqhD1v35fZ4S8HQqabOIyBDILC/FvARtT6nvmFZJKp/J+XSmtIOoRVdhIZ2w7rRsqzAYhXBUJKbdMGgSVS3i0tgNel6XgeKWg8o7JbVR7/ums6AOsDNlw4V9T/AyC+VD9Vg/6kZt2FyvgFzaKiZE68HT0ALCRFfLkkK98xFxPeFEfNgV85cWlxWMlop+0TfwgPzVuH4IyD6D3o87zsdDAps59JuF62gsuXJLRnvrUi0GFnLikUcqazAIRYssTrGgkjegGqmo2Wc88A+toIdCcgRSk6Gj+vehlu20jkBzZcOFfU/wMgvlQ/VYP+pGbdhcr4Bc2iomROvB09ACwl3Ky2nVgAAgAEAAIACAACAAAAAAAAAAAAhFkMgsL8W8BG1Pqe+YVkkqn8n5dKa0g6hFV2EhnbDutGyOQERXy5JCvfMRcT3hRHzYFfOXFpcVjJaKftE38ID81bh+HcrLadWAACAAQAAgAEAAIAAAAAAAAAAACEWUJKbdMGgSVS3i0tgNel6XgeKWg8o7JbVR7/ums6AOsAFAHxGHl0hFvoPejzvOx0MCmzn0m4XraCy5cktGe+tSLQYWcuKRRypOQFvfWIFnpSXoaSiZ1admHbaYBAa/zjjUpubk5zn+RrpcHcrLadWAACAAQAAgAMAAIAAAAAAAAAAAAEXIFCSm3TBoElUt4tLYDXpel4HiloPKOyW1Ue/7prOgDrAARgg8DYuL3Wm9CClvePrIh2WrmcgzyX4GJDJWx13WstRXmUAAQUgESTaeuySzNBslUViZH9DexOLlXIahL4r8idrvdqz5nEhBxEk2nrskszQbJVFYmR/Q3sTi5VyGoS+K/Ina73as+ZxGQB3Ky2nVgAAgAEAAIAAAACAAAAAAAUAAAAA

## Rationale

<references/>

## Reference implementation

The reference implementation of the PSBT format is available at
<https://github.com/achow101/bitcoin/tree/taproot-psbt>.

## Acknowledgements

TBD

1.  **Why is there no key data for `PSBT_IN_TAP_KEY_SIG`**The signature
    in a key path spend corresponds directly with the pubkey provided in
    the output script. Thus it is not necessary to provide any metadata
    that attaches the key path spend signature to a particular pubkey.
2.  **Why is the internal key provided?**The internal key is not
    necessarily the same key as in the Taproot output script. BIP 341
    recommends tweaking the key with the hash of itself. It may be
    necessary for signers to know what the internal key actually is so
    that they are able to determine whether an input can be signed by
    it.