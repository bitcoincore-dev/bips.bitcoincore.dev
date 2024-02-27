+++
title = "codex32: Checksummed SSSS-aware BIP32 seeds"
date = 2023-02-13
weight = 93
in_search_index = true

[taxonomies]
authors = ["Leon Olsson Curr and Pearlwort Sneed", "Andrew Poelstra"]
status = ["Draft"]

[extra]
bip = 93
status = ["Draft"]
github = "https://github.com/bitcoin/bips/blob/master/bip-0093.mediawiki"
+++

``` 
  BIP: 93
  Layer: Applications
  Title: codex32: Checksummed SSSS-aware BIP32 seeds
  Author: Leon Olsson Curr and Pearlwort Sneed <pearlwort@wpsoftware.net>
          Andrew Poelstra <andrew.poelstra@gmail.com>
  Comments-URI: https://github.com/bitcoin/bips/wiki/Comments:BIP-0093
  Status: Draft
  Type: Informational
  Created: 2023-02-13
  License: BSD-3-Clause
  Post-History: https://lists.linuxfoundation.org/pipermail/bitcoin-dev/2023-February/021469.html
```

## Introduction

### Abstract

This document describes a standard for backing up and restoring the
master seed of a
[BIP-0032](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki)
hierarchical deterministic wallet, using Shamir's secret sharing. It
includes an encoding format, a BCH error-correcting checksum, and
algorithms for share generation and secret recovery. Secret data can be
split into up to 31 shares. A minimum threshold of shares, which can be
between 1 and 9, is needed to recover the secret, whereas without
sufficient shares, no information about the secret is recoverable.

### Copyright

This document is licensed under the 3-clause BSD license.

### Motivation

BIP-0032 master seed data is the source entropy used to derive all
private keys in an HD wallet. Safely storing this secret data is the
hardest and most important part of self-custody. However, there is a
tension between security, which demands limiting the number of backups,
and resilience, which demands widely replicated backups. Encrypting the
seed does not change this fundamental tradeoff, since it leaves
essentially the same problem of how to back up the encryption key(s).

To allow users freedom to make this tradeoff, we use Shamir's secret
sharing, which guarantees that any number of shares less than the
threshold leaks no information about the secret. This approach allows
increasing safety by widely distributing the generated shares, while
also providing security against the compromise of one or more shares (as
long as fewer than the threshold have been compromised).

[SLIP-0039](https://github.com/satoshilabs/slips/blob/master/slip-0039.md)
has essentially the same motivations as this standard. However, unlike
SLIP-0039,

  - this standard aims to be simple enough for hand computation
  - we use the bech32 alphabet rather than a word list, resulting in
    fixed-length compact encodings
  - we do not support multi-level secret sharing (splitting of shares),
    although it is technically possible and may be added in a future BIP
  - because of the need to support hand computation, we **do not**
    support passphrases or key hardening

Users who demand a higher level of security for particular secrets, or
have a general distrust in digital electronic devices, have the option
of using hand computation to backup and restore secret data in an
interoperable manner. In particular, all computations can be done with
simple lookup tables. **It is therefore possible to compute and verify
checksums, and to split and recover seeds, entirely using pen and
paper.** For long-lived rarely-used seeds, the ability to hand-verify
checksums has a significant benefit even for users who do not care to do
any other part of this process by hand. It means that they can verify
the integrity (against non-malicious tampering) of their shares
regularly, say, on an annual basis, without needing to continually
expose secret data to new hardware.

The ability to compute properties by hand comes from our choice of a
small field and our use of linear error correcting codes. It does not
come with any reduction in security, as long as users use high-quality
randomness. Note that hand computation is optional, the particular
details of hand computation are outside the scope of this standard, and
implementers do not need to be concerned with this possibility.

[BIP-0039](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki)
serves the same purpose as this standard: encoding master seeds for
storage by users. However, BIP-0039 has no error-correcting ability,
cannot sensibly be extended to support secret sharing, has no support
for versioning or other metadata, and has many technical design
decisions that make implementation and interoperability difficult (for
example, the use of SHA-512 to derive seeds, or the use of 11-bit
words).

## Specification

### codex32

A codex32 string is similar to a bech32 string defined in
[BIP-0173](https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki).
It reuses the base-32 character set from BIP-0173, and consists of:

  - A human-readable part, which is the string "ms" (or "MS").
  - A separator, which is always "1".
  - A data part which is in turn subdivided into:
      - A threshold parameter, which MUST be a single digit between "2"
        and "9", or the digit "0".
          - If the threshold parameter is "0" then the share index,
            defined below, MUST have a value of "s" (or "S").
      - An identifier consisting of 4 bech32 characters.
      - A share index, which is any bech32 character. Note that a share
        index value of "s" (or "S") is special and denotes the unshared
        secret (see section "Unshared Secret").
      - A payload which is a sequence of up to 74 bech32 characters.
        (However, see **Long codex32 Strings** below for an exception to
        this limit.)
      - A checksum which consists of 13 bech32 characters as described
        below.

As with bech32 strings, a codex32 string MUST be entirely uppercase or
entirely lowercase. For presentation, lowercase is usually preferable,
but uppercase SHOULD be used for handwritten codex32 strings. If a
codex32 string is encoded in a QR code, it SHOULD use the uppercase
form, as this is encoded more compactly.

### Checksum

The last thirteen characters of the data part form a checksum and
contain no information. Valid strings MUST pass the criteria for
validity specified by the Python 3 code snippet below. The function
`ms32_verify_checksum` must return true when its argument is the data
part as a list of integers representing the characters converted using
the bech32 character table from BIP-0173.

To construct a valid checksum given the data-part characters (excluding
the checksum), the `ms32_create_checksum` function can be used.

``` python
MS32_CONST = 0x10ce0795c2fd1e62a

def ms32_polymod(values):
    GEN = [
        0x19dc500ce73fde210,
        0x1bfae00def77fe529,
        0x1fbd920fffe7bee52,
        0x1739640bdeee3fdad,
        0x07729a039cfc75f5a,
    ]
    residue = 0x23181b3
    for v in values:
        b = (residue >> 60)
        residue = (residue & 0x0fffffffffffffff) << 5 ^ v
        for i in range(5):
            residue ^= GEN[i] if ((b >> i) & 1) else 0
    return residue

def ms32_verify_checksum(data):
    if len(data) >= 96:                      # See Long codex32 Strings
        return ms32_verify_long_checksum(data)
    if len(data) <= 93:
        return ms32_polymod(data) == MS32_CONST
    return False

def ms32_create_checksum(data):
    if len(data) > 80:                       # See Long codex32 Strings
        return ms32_create_long_checksum(data)
    values = data
    polymod = ms32_polymod(values + [0] * 13) ^ MS32_CONST
    return [(polymod >> 5 * (12 - i)) & 31 for i in range(13)]
```

### Error Correction

A codex32 string without a valid checksum MUST NOT be used. The checksum
is designed to be an error correcting code that can correct up to 4
character substitutions, up to 8 unreadable characters (called
erasures), or up to 13 consecutive erasures. Implementations SHOULD
provide the user with a corrected valid codex32 string if possible.
However, implementations SHOULD NOT automatically proceed with a
corrected codex32 string without user confirmation of the corrected
string, either by prompting the user, or returning a corrected string in
an error message and allowing the user to repeat their action. We do not
specify how an implementation should implement error correction.
However, we recommend that:

  - Implementations make suggestions to substitute non-bech32 characters
    with bech32 characters in some situations, such as replacing "B"
    with "8", "O" with "0", "I" with "l", etc.
  - Implementations interpret "?" as an erasure.
  - Implementations optionally interpret other non-bech32 characters, or
    characters with incorrect case, as erasures.
  - If a string with 8 or fewer erasures can have those erasures filled
    in to make a valid codex32 string, then the implementation suggests
    such a string as a correction.
  - If a string consisting of valid bech32 characters in the proper case
    can be made valid by substituting 4 or fewer characters, then the
    implementation suggests such a string as a correction.

### Unshared Secret

When the share index of a valid codex32 string (converted to lowercase)
is the letter "s", we call the string a codex32 secret. The payload in a
codex32 secret is a direct encoding of a BIP-0032 HD master seed.

The master seed is decoded by converting the payload to bytes:

  - Translate the characters to 5 bits values using the bech32 character
    table from BIP-0173, most significant bit first.
  - Re-arrange those bits into groups of 8 bits. Any incomplete group at
    the end MUST be 4 bits or less, and is discarded.

Note that unlike the decoding process in BIP-0173, we do NOT require
that the incomplete group be all zeros.

For an unshared secret, the threshold parameter (the first character of
the data part) is ignored (beyond the fact it must be a digit for the
codex32 string to be valid). We recommend using the digit "0" for the
threshold parameter in this case. The 4 character identifier also has no
effect beyond aiding users in distinguishing between multiple different
master seeds in cases where they have more than one.

### Recovering Master Seed

When the share index of a valid codex32 string (converted to lowercase)
is not the letter "s", we call the string an codex32 share. The first
character of the data part indicates the threshold of the share, and it
is required to be a non-"0" digit.

In order to recover a master seed, one needs a set of valid codex32
shares such that:

  - All shares have the same threshold value, the same identifier, and
    the same length.
  - All of the share index values are distinct.
  - The number of codex32 shares is exactly equal to the (common)
    threshold value.

If all the above conditions are satisfied, the `ms32_recover` function
will return a codex32 secret when its argument is the list of codex32
shares with each share represented as a list of integers representing
the characters converted using the bech32 character table from BIP-0173.

``` python
bech32_inv = [
    0, 1, 20, 24, 10, 8, 12, 29, 5, 11, 4, 9, 6, 28, 26, 31,
    22, 18, 17, 23, 2, 25, 16, 19, 3, 21, 14, 30, 13, 7, 27, 15,
]

def bech32_mul(a, b):
    res = 0
    for i in range(5):
        res ^= a if ((b >> i) & 1) else 0
        a *= 2
        a ^= 41 if (32 <= a) else 0
    return res

def bech32_lagrange(l, x):
    n = 1
    c = []
    for i in l:
        n = bech32_mul(n, i ^ x)
        m = 1
        for j in l:
            m = bech32_mul(m, (x if i == j else i) ^ j)
        c.append(m)
    return [bech32_mul(n, bech32_inv[i]) for i in c]

def ms32_interpolate(l, x):
    w = bech32_lagrange([s[5] for s in l], x)
    res = []
    for i in range(len(l[0])):
        n = 0
        for j in range(len(l)):
            n ^= bech32_mul(w[j], l[j][i])
        res.append(n)
    return res

def ms32_recover(l):
    return ms32_interpolate(l, 16)
```

### Generating Shares

If we already have *t* valid codex32 strings such that:

  - All strings have the same threshold value *t*, the same identifier,
    and the same length
  - All of the share index values are distinct

Then we can derive additional shares with the `ms32_interpolate`
function by passing it a list of exactly *t* of these codex32 strings,
together with a fresh share index distinct from all of the existing
share indexes. The newly derived share will have the provided share
index.

Once a user has generated *n* codex32 shares, they may discard the
codex32 secret (if it exists). The *n* shares form a *t* of *n* Shamir's
secret sharing scheme of a codex32 secret.

There are two ways to create an initial set of *t* valid codex32
strings, depending on whether the user already has an existing master
seed to split.

#### For a fresh master seed

In the case that the user wishes to generate a fresh master seed, the
user generates random initial shares, as follows:

1.  Choose a bitsize, between 128 and 512, which must be a multiple of
    8.
2.  Choose a threshold value *t* between 2 and 9, inclusive
3.  Choose a 4 bech32 character identifier
      - We do not define how to choose the identifier, beyond noting
        that it SHOULD be distinct for every master seed the user may
        need to disambiguate.
4.  *t* many times, generate a random share by:
    1.  Take the next available letter from the bech32 alphabet, in
        alphabetical order, as `a`, `c`, `d`, ..., to be the share index
    2.  Set the first nine characters to be the prefix `ms1`, the
        threshold value *t*, the 4-character identifier, and then the
        share index
    3.  Choose the next ceil(*bitlength / 5*) characters uniformly at
        random
    4.  Generate a valid checksum in accordance with the Checksum
        section, and append this to the resulting shares

The result will be *t* distinct shares, all with the same initial 8
characters, and a distinct share index as the 9th character.

With this set of *t* codex32 shares, new shares can be derived as
discussed above. This process generates a fresh master seed, whose value
can be retrieved by running the recovery process on any *t* of these
shares.

#### For an existing master seed

Before generating shares for an existing master seed, it first must be
converted into a codex32 secret, as described above. The conversion
process consists of:

1.  Choose a threshold value *t* between 2 and 9, inclusive
2.  Choose a 4 bech32 character identifier
      - We do not define how to choose the identifier, beyond noting
        that it SHOULD be distinct for every master seed the user may
        need to disambiguate.
3.  Set the share index to `s`
4.  Set the payload to a bech32 encoding of the master seed, padded with
    arbitrary bits
5.  Generating a valid checksum in accordance with the Checksum section

Along with the codex32 secret, the user must generate *t*-1 other
codex32 shares, each with the same threshold value, the same identifier,
and a distinct share index. These shares should be generated as
described in the "fresh master seed" section.

The codex32 secret and the *t*-1 codex32 shares form a set of *t* valid
codex32 strings from which additional shares can be derived as described
above.

### Long codex32 Strings

The 13 character checksum design only supports up to 80 data characters.
Excluding the threshold, identifier and index characters, this limits
the payload to 74 characters or 46 bytes. While this is enough to
support the 32-byte advised size of BIP-0032 master seeds, BIP-0032
allows seeds to be up to 64 bytes in size. We define a long codex32
string format to support these longer seeds by defining an alternative
checksum.

``` python
MS32_LONG_CONST = 0x43381e570bf4798ab26

def ms32_long_polymod(values):
    GEN = [
        0x3d59d273535ea62d897,
        0x7a9becb6361c6c51507,
        0x543f9b7e6c38d8a2a0e,
        0x0c577eaeccf1990d13c,
        0x1887f74f8dc71b10651,
    ]
    residue = 0x23181b3
    for v in values:
        b = (residue >> 70)
        residue = (residue & 0x3fffffffffffffffff) << 5 ^ v
        for i in range(5):
            residue ^= GEN[i] if ((b >> i) & 1) else 0
    return residue

def ms32_verify_long_checksum(data):
    return ms32_long_polymod(data) == MS32_LONG_CONST

def ms32_create_long_checksum(data):
    values = data
    polymod = ms32_long_polymod(values + [0] * 15) ^ MS32_LONG_CONST
    return [(polymod >> 5 * (14 - i)) & 31 for i in range(15)]
```

A long codex32 string follows the same specification as a regular
codex32 string with the following changes.

  - The payload is a sequence of between 75 and 103 bech32 characters.
  - The checksum consists of 15 bech32 characters as defined above.

A codex32 string with a data part of 94 or 95 characters is never legal
as a regular codex32 string is limited to 93 data characters and a long
codex32 string is at least 96 characters.

Generation of long shares and recovery of the master seed from long
shares proceeds in exactly the same way as for regular shares with the
`ms32_interpolate` function.

The long checksum is designed to be an error correcting code that can
correct up to 4 character substitutions, up to 8 unreadable characters
(called erasures), or up to 15 consecutive erasures. As with regular
checksums we do not specify how an implementation should implement error
correction, and all our recommendations for error correction of regular
codex32 strings also apply to long codex32 strings.

## Rationale

This scheme is based on the observation that the Lagrange interpolation
of valid codewords in a BCH code will always be a valid codeword. This
means that derived shares will always have valid checksum, and a
sufficient threshold of shares with valid checksums will derive a secret
with a valid checksum.

The header system is also compatible with Lagrange interpolation,
meaning all derived shares will have the same identifier and will have
the appropriate share index. This fact allows the header data to be
covered by the checksum.

The checksum size and identifier size have been chosen so that the
encoding of 128-bit seeds and shares fit within 48 characters. This is a
standard size for many common seed storage formats, which has been
popularized by the 12 four-letter word format of the BIP-0039 mnemonic.

The 13 character checksum is adequate to correct 4 errors in up to 93
characters (80 characters of data and 13 characters of the checksum). We
can correct up to 8 erasures (errors with known locations), and up to 13
consecutive errors (burst errors). Beyond that, our code is guaranteed
to detect up to 8 errors. More generally, any number of random errors
will be detected with overwhelming (1 - 2^65) probability. However, the
checksum does not protect against maliciously constructed errors. These
parameters are slightly better than those of the checksum used in
SLIP-0039.

For 256-bit seeds and shares our strings are 74 characters, which fits
into the 96 character format of the 24 four-letter word format of the
BIP-0039 mnemonic, with plenty of room to spare.

A longer checksum is needed to support up to 512-bit seeds, the longest
seed length specified in BIP-0032, as the 13 character checksum isn't
adequate for more than 80 data characters. While we could use the 15
character checksum for both cases, we prefer to keep the strings as
short as possible for the more common cases of 128-bit and 256-bit
master seeds. We only guarantee to correct 4 characters no matter how
long the string is. Longer strings mean more chances for transcription
errors, so shorter strings are better.

The longest data part using the regular 13 character checksum is 93
characters and corresponds to a 400-bit secret. At this length, the
prefix `MS1` is not covered by the checksum. This is acceptable because
the checksum scheme itself requires you to know that the `MS1` prefix is
being used in the first place. If the prefix is damaged and a user is
guessing that the data might be using this scheme, then the user can
enter the available data explicitly using the suspected `MS1` prefix.

### Not BIP-0039 Entropy

Instead of encoding a BIP-0032 master seed, an alternative would be to
encode BIP-0039 entropy. However this alternative approach is fraught
with difficulties.

On approach would be to encode the BIP-0039 entropy along with the
BIP-0039 checksum data. This data can directly be recovered from the
BIP-0039 mnemonic, and the process can be reversed if one knows the
target language. However, for a 128-bit seed, there is a 4 bit checksum
yielding 132 bits of data that needs to be encoded. This exceeds the
130-bits of room that we have for storing 128 bit seeds. We would have
to compromise on the 48 character size, or the size of the headers, or
the size of the checksum in order to add room for an additional
character of data.

This approach would also eliminate our short cut generation of a fresh
master secret from generating random shares. One would be required to
first generate BIP-0039 entropy, and then add a BIP-0039 checksum,
before adding a Codex32 checksum and then generate other shares. In
particular, this process could no longer be performed by hand since it
is effectively impossible to hand compute a BIP-0039 checksum.

An alternative approach is to discard the BIP-0039 checksum, since it is
inadequate for error correction anyways, and rely on the Codex32
checksum. However, this approach ends up eliminating the benefits of
BIP-0039 compatibility. While it is now possible to hand generate fresh
shares, it is impossible to recover compatible BIP-0039 words by hand
because, again, the BIP-0039 checksum is not hand computable. The only
way of generating the compatible BIP-0039 mnemonic is to use wallet
software. But if the wallet software is need to support this approach to
decoding entropy, we may as well bypass all of the overhead of BIP-0039
and directly encode the entropy of a BIP-0032 master seed, which is what
we do in our Codex32 proposal.

Beyond the problems above, BIP-0039 does not define a single
transformation from entropy to BIP-0032 master seed. Instead every
different language has it own word list (or word lists) and each choice
of word list yields a different transformation from entropy to master
seed. We would need to encode the choice of word list in our share's
meta-data, which takes up even more room, and is difficult to specify
due to the ever-evolving choice of word lists.

Alternatively we could standardize on the choice of the English word
list, something that is nearly a de facto standard, and simply be
incompatible with BIP-0039 wallets of other languages. Such a choice
also risks users of BIP-0039 recovering their entropy from their
language, encoding it in in Codex32 and then failing to recover their
wallet because the English word lists has replaced their language's word
list.

The main advantage of this alternative approach would be that wallets
could give users an option switch between backing up their entropy as a
BIP-0039 mnemonic and in Codex32 format, but again, only if their
language choice happens to be the English word list. In practice, we do
not expect users in switch back and forth between backup formats, and
instead just generate a fresh master seed using Codex32.

Seeing little value with BIP-0039 compatibility (English-only), all the
difficulties with BIP-0039 language choice, not to mention the PBKDF2
overhead of using BIP-0039, we think it is best to abandon BIP-0039 and
encode BIP-0032 master seeds directly. Our approach is semi-convertible
with BIP-0039's 512-bit master seeds (in all languages, see Backwards
Compatibility) and fully interconvertible with SLIP-39 encoded master
seeds or any other encoding of BIP-0032 master seeds.

## Backwards Compatibility

codex32 is an alternative to BIP-0039 and SLIP-0039. It is technically
possible to derive the BIP32 master seed from seed words encoded in one
of these schemes, and then to encode this seed in codex32. For BIP-0039
this process is irreversible, since it involves hashing the original
words. Furthermore, the resulting seed will be 512 bits long, which may
be too large to be safely and conveniently handled.

SLIP-0039 seed words can be reversibly converted to master seeds, so it
is possible to interconvert between SLIP-0039 and codex32. However,
SLIP-0039 **shares** cannot be converted to codex32 shares because the
two schemes use a different underlying field.

The authors of this BIP do not recommend interconversion. Instead, users
who wish to switch to codex32 should generate a fresh seed and sweep
their coins.

## Reference Implementation

Our [reference implementation
repository](https://github.com/BlockstreamResearch/codex32) contains
implementations in Rust and PostScript. The inline code in this BIP text
can be used as a Python reference.

## Test Vectors

### Test vector 1

This example shows the codex32 format, when used without splitting the
secret into any shares. The payload contains 26 bech32 characters, which
corresponds to 130 bits. We truncate the last two bits in order to
obtain a 128-bit master seed.

codex32 secret (bech32):
`ms10testsxxxxxxxxxxxxxxxxxxxxxxxxxx4nzvca9cmczlw`

Master secret (hex): `318c6318c6318c6318c6318c6318c631`

  - human-readable part: `ms`
  - separator: `1`
  - k value: `0` (no secret splitting)
  - identifier: `test`
  - share index: `s` (the secret)
  - payload: `xxxxxxxxxxxxxxxxxxxxxxxxxx`
  - checksum: `4nzvca9cmczlw`
  - master node xprv:
    `xprv9s21ZrQH143K3taPNekMd9oV5K6szJ8ND7vVh6fxicRUMDcChr3bFFzuxY8qP3xFFBL6DWc2uEYCfBFZ2nFWbAqKPhtCLRjgv78EZJDEfpL`

### Test vector 2

This example shows generating a new master seed using "random" codex32
shares, as well as deriving an additional codex32 share, using *k*=2 and
an identifier of `NAME`. Although codex32 strings are canonically all
lowercase, it's also valid to use all uppercase.

Share with index `A`: `MS12NAMEA320ZYXWVUTSRQPNMLKJHGFEDCAXRPP870HKKQRM`

Share with index `C`: `MS12NAMECACDEFGHJKLMNPQRSTUVWXYZ023FTR2GDZMPY6PN`

  - Derived share with index `D`:
    `MS12NAMEDLL4F8JLH4E5VDVULDLFXU2JHDNLSM97XVENRXEG`
  - Secret share with index `S`:
    `MS12NAMES6XQGUZTTXKEQNJSJZV4JV3NZ5K3KWGSPHUH6EVW`
  - Master secret (hex): `d1808e096b35b209ca12132b264662a5`
  - master node xprv:
    `xprv9s21ZrQH143K2NkobdHxXeyFDqE44nJYvzLFtsriatJNWMNKznGoGgW5UMTL4fyWtajnMYb5gEc2CgaKhmsKeskoi9eTimpRv2N11THhPTU`

Note that per BIP-0173, the lowercase form is used when determining a
character's value for checksum purposes. In particular, given an all
uppercase codex32 string, we still use lowercase `ms` as the
human-readable part during checksum construction.

### Test vector 3

This example shows splitting an existing 128-bit master seed into
"random" codex32 shares, using *k*=3 and an identifier of `cash`. We
appended two zero bits in order to obtain 26 bech32 characters (130 bits
of data) from the 128-bit master seed.

Master secret (hex): `ffeeddccbbaa99887766554433221100`

Secret share with index `s`:
`ms13cashsllhdmn9m42vcsamx24zrxgs3qqjzqud4m0d6nln`

Share with index `a`: `ms13casha320zyxwvutsrqpnmlkjhgfedca2a8d0zehn8a0t`

Share with index `c`: `ms13cashcacdefghjklmnpqrstuvwxyz023949xq35my48dr`

  - Derived share with index `d`:
    `ms13cashd0wsedstcdcts64cd7wvy4m90lm28w4ffupqs7rm`
  - Derived share with index `e`:
    `ms13casheekgpemxzshcrmqhaydlp6yhms3ws7320xyxsar9`
  - Derived share with index `f`:
    `ms13cashf8jh6sdrkpyrsp5ut94pj8ktehhw2hfvyrj48704`
  - master node xprv:
    `xprv9s21ZrQH143K266qUcrDyYJrSG7KA3A7sE5UHndYRkFzsPQ6xwUhEGK1rNuyyA57Vkc1Ma6a8boVqcKqGNximmAe9L65WsYNcNitKRPnABd`

Any three of the five shares among `acdef` can be used to recover the
secret.

Note that the choice to append two zero bits was arbitrary, and any of
the following four secret shares would have been valid choices. However,
each choice would have resulted in a different set of derived shares.

  - `ms13cashsllhdmn9m42vcsamx24zrxgs3qqjzqud4m0d6nln`
  - `ms13cashsllhdmn9m42vcsamx24zrxgs3qpte35dvzkjpt0r`
  - `ms13cashsllhdmn9m42vcsamx24zrxgs3qzfatvdwq5692k6`
  - `ms13cashsllhdmn9m42vcsamx24zrxgs3qrsx6ydhed97jx2`

### Test vector 4

This example shows converting a 256-bit secret into a codex32 secret,
without splitting the secret into any shares. We appended four zero bits
in order to obtain 52 bech32 characters (260 bits of data) from the
256-bit secret.

256-bit secret (hex):
`ffeeddccbbaa99887766554433221100ffeeddccbbaa99887766554433221100`

  - codex32 secret:
    `ms10leetsllhdmn9m42vcsamx24zrxgs3qrl7ahwvhw4fnzrhve25gvezzyqqtum9pgv99ycma`
  - master node xprv:
    `xprv9s21ZrQH143K3s41UCWxXTsU4TRrhkpD1t21QJETan3hjo8DP5LFdFcB5eaFtV8x6Y9aZotQyP8KByUjgLTbXCUjfu2iosTbMv98g8EQoqr`

Note that the choice to append four zero bits was arbitrary, and any of
the following sixteen codex32 secrets would have been valid:

  - `ms10leetsllhdmn9m42vcsamx24zrxgs3qrl7ahwvhw4fnzrhve25gvezzyqqtum9pgv99ycma`
  - `ms10leetsllhdmn9m42vcsamx24zrxgs3qrl7ahwvhw4fnzrhve25gvezzyqpj82dp34u6lqtd`
  - `ms10leetsllhdmn9m42vcsamx24zrxgs3qrl7ahwvhw4fnzrhve25gvezzyqzsrs4pnh7jmpj5`
  - `ms10leetsllhdmn9m42vcsamx24zrxgs3qrl7ahwvhw4fnzrhve25gvezzyqrfcpap2w8dqezy`
  - `ms10leetsllhdmn9m42vcsamx24zrxgs3qrl7ahwvhw4fnzrhve25gvezzyqy5tdvphn6znrf0`
  - `ms10leetsllhdmn9m42vcsamx24zrxgs3qrl7ahwvhw4fnzrhve25gvezzyq9dsuypw2ragmel`
  - `ms10leetsllhdmn9m42vcsamx24zrxgs3qrl7ahwvhw4fnzrhve25gvezzyqx05xupvgp4v6qx`
  - `ms10leetsllhdmn9m42vcsamx24zrxgs3qrl7ahwvhw4fnzrhve25gvezzyq8k0h5p43c2hzsk`
  - `ms10leetsllhdmn9m42vcsamx24zrxgs3qrl7ahwvhw4fnzrhve25gvezzyqgum7hplmjtr8ks`
  - `ms10leetsllhdmn9m42vcsamx24zrxgs3qrl7ahwvhw4fnzrhve25gvezzyqf9q0lpxzt5clxq`
  - `ms10leetsllhdmn9m42vcsamx24zrxgs3qrl7ahwvhw4fnzrhve25gvezzyq28y48pyqfuu7le`
  - `ms10leetsllhdmn9m42vcsamx24zrxgs3qrl7ahwvhw4fnzrhve25gvezzyqt7ly0paesr8x0f`
  - `ms10leetsllhdmn9m42vcsamx24zrxgs3qrl7ahwvhw4fnzrhve25gvezzyqvrvg7pqydv5uyz`
  - `ms10leetsllhdmn9m42vcsamx24zrxgs3qrl7ahwvhw4fnzrhve25gvezzyqd6hekpea5n0y5j`
  - `ms10leetsllhdmn9m42vcsamx24zrxgs3qrl7ahwvhw4fnzrhve25gvezzyqwcnrwpmlkmt9dt`
  - `ms10leetsllhdmn9m42vcsamx24zrxgs3qrl7ahwvhw4fnzrhve25gvezzyq0pgjxpzx0ysaam`

### Test vector 5

This example shows generating a new 512-bit master seed using "random"
codex32 characters and appending a checksum. The payload contains 103
bech32 characters, which corresponds to 515 bits. The last three bits
are discarded when converting to a 512-bit master seed.

This is an example of a **Long codex32 String**.

  - Secret share with index `S`:
    `MS100C8VSM32ZXFGUHPCHTLUPZRY9X8GF2TVDW0S3JN54KHCE6MUA7LQPZYGSFJD6AN074RXVCEMLH8WU3TK925ACDEFGHJKLMNPQRSTUVWXY06FHPV80UNDVARHRAK`
  - Master secret (hex):
    `dc5423251cb87175ff8110c8531d0952d8d73e1194e95b5f19d6f9df7c01111104c9baecdfea8cccc677fb9ddc8aec5553b86e528bcadfdcc201c17c638c47e9`
  - master node xprv:
    `xprv9s21ZrQH143K4UYT4rP3TZVKKbmRVmfRqTx9mG2xCy2JYipZbkLV8rwvBXsUbEv9KQiUD7oED1Wyi9evZzUn2rqK9skRgPkNaAzyw3YrpJN`

### Invalid test vectors

These examples have incorrect checksums.

  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxve740yyge2ghq`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxve740yyge2ghp`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxlk3yepcstwr`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxx6pgnv7jnpcsp`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxx0cpvr7n4geq`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxm5252y7d3lr`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxrd9sukzl05ej`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxc55srw5jrm0`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxgc7rwhtudwc`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxx4gy22afwghvs`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxe8yfm0`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxvm597d`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxme084q0vpht7pe0`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxme084q0vpht7pew`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxqyadsp3nywm8a`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxzvg7ar4hgaejk`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxcznau0advgxqe`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxch3jrc6j5040j`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx52gxl6ppv40mcv`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx7g4g2nhhle8fk`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx63m45uj8ss4x8`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxy4r708q7kg65x`

These examples use the wrong checksum for their given data sizes.

  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxurfvwmdcmymdufv`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxcsyppjkd8lz4hx3`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxu6hwvl5p0l9xf3c`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxwqey9rfs6smenxa`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxv70wkzrjr4ntqet`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx3hmlrmpa4zl0v`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxrfggf88znkaup`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxpt7l4aycv9qzj`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxus27z9xtyxyw3`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxcwm4re8fs78vn`

These examples have improper lengths. They are either too short, too
long, or would decode to byte sequence with an incomplete group greater
than 4 bits.

  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxw0a4c70rfefn4`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxk4pavy5n46nea`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxx9lrwar5zwng4w`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxr335l5tv88js3`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxvu7q9nz8p7dj68v`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxpq6k542scdxndq3`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkmfw6jm270mz6ej`
  - `ms12fauxxxxxxxxxxxxxxxxxxxxxxxxxxzhddxw99w7xws`
  - `ms12fauxxxxxxxxxxxxxxxxxxxxxxxxxxxx42cux6um92rz`
  - `ms12fauxxxxxxxxxxxxxxxxxxxxxxxxxxxxxarja5kqukdhy9`
  - `ms12fauxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxky0ua3ha84qk8`
  - `ms12fauxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx9eheesxadh2n2n9`
  - `ms12fauxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx9llwmgesfulcj2z`
  - `ms12fauxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx02ev7caq6n9fgkf`

This example uses a "0" threshold with a non-"s" index

  - `ms10fauxxxxxxxxxxxxxxxxxxxxxxxxxxxx0z26tfn0ulw3p`

This example has a threshold that is not a digit.

  - `ms1fauxxxxxxxxxxxxxxxxxxxxxxxxxxxxxda3kr3s0s2swg`

These examples do not begin with the required "ms" or "MS" prefix and/or
are missing the "1" separator.

  - `0fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxuqxkk05lyf3x2`
  - `10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxuqxkk05lyf3x2`
  - `ms0fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxuqxkk05lyf3x2`
  - `m10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxuqxkk05lyf3x2`
  - `s10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxuqxkk05lyf3x2`
  - `0fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxhkd4f70m8lgws`
  - `10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxhkd4f70m8lgws`
  - `m10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxx8t28z74x8hs4l`
  - `s10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxh9d0fhnvfyx3x`

These examples all incorrectly mix upper and lower case characters.

  - `Ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxuqxkk05lyf3x2`
  - `mS10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxuqxkk05lyf3x2`
  - `MS10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxuqxkk05lyf3x2`
  - `ms10FAUXsxxxxxxxxxxxxxxxxxxxxxxxxxxuqxkk05lyf3x2`
  - `ms10fauxSxxxxxxxxxxxxxxxxxxxxxxxxxxuqxkk05lyf3x2`
  - `ms10fauxsXXXXXXXXXXXXXXXXXXXXXXXXXXuqxkk05lyf3x2`
  - `ms10fauxsxxxxxxxxxxxxxxxxxxxxxxxxxxUQXKK05LYF3X2`

## Appendix

### Mathematical Companion

Below we use the bech32 character set to denote values in GF\[32\]. In
bech32, the letter `Q` denotes zero and the letter `P` denotes one. The
digits `0` and `2` through `9` do *not* denote their numeric values.
They are simply elements of GF\[32\].

The generating polynomial for our BCH code is as follows.

We extend GF\[32\] to GF\[1024\] by adjoining a primitive cube root of
unity, `ζ`, satisfying `ζ^2 = ζ + P`.

We select `β := G ζ` which has order 93, and construct the product `(x -
β^i)` for `i` in `{17, 20, 46, 49, 52, 77, 78, 79, 80, 81, 82, 83, 84}`.
The resulting polynomial is our generating polynomial for our 13
character checksum:

`   x^13 + E x^12 + M x^11 + 3 x^10 + G x^9 + Q x^8 + E x^7 + E x^6 + E x^5 + L x^4 + M x^3 + C x^2 + S x + S`

For our long checksum, we select `γ := E + X ζ`, which has order 1023,
and construct the product `(x - γ^i)` for `i` in
`{32, 64, 96, 895, 927, 959, 991, 1019, 1020, 1021, 1022, 1023, 1024, 1025, 1026}`.
The resulting polynomial is our generating polynomial for our 15
character checksum for long strings:

`   x^15 + 0 x^14 + 2 x^13 + E x^12 + 6 x^11 + F x^10 + E x^9 + 4 x^8 + X x^7 + H x^6 + 4 x^5 + X x^4 + 9 x^3 + K x^2 + Y x^1 + H`

(Reminder: the character `0` does *not* denote the zero of the field.)
