---
title: "Tutorial 78: Protecting and signing messages"
lead: Encrypting a message is not enough: you must also be sure that nobody changed it. This lesson derives keys from a password, encrypts with AES, adds an HMAC (encrypt-then-MAC), detects tampering, and signs a message with an RSA key pair.
---

## What you will learn

- turning a password into keys with PBKDF2 (`Rfc2898DeriveBytes`),
- AES encryption with a random IV,
- an **HMAC** that proves that the message was not changed,
- why you check the HMAC *before* you decrypt,
- digital signatures with **RSA**,
- how these classes are called from Ring (byte arrays are Ring texts).

This builds on [tutorial 8](tut-08-security.html) (hashes and basic encryption).

## Two different problems

| Problem | Tool | Key |
|---|---|---|
| Nobody should *read* the message | **encryption** (AES) | one **secret key**, shared by sender and receiver |
| Nobody should *change* it, and I want to know it is genuine | **HMAC** (shared key) or a **signature** (RSA) | HMAC: the same shared key. Signature: a **private** key signs, the **public** key verifies. |

Use both for a protected message: **encrypt first, then compute the HMAC over the encrypted bytes** (*encrypt-then-MAC*). The receiver checks the HMAC first, so a forged or damaged package is refused *before* any decryption work happens.

## The program

{{file:docs/tutorials/t78_crypto.ring}}

{{output:docs/tutorials/t78_crypto.ring}}

## How it works

### Keys from a password

A password is short and predictable; a key must be 32 random-looking bytes. `Rfc2898DeriveBytes` (PBKDF2) repeats a hash 100,000 times with a random **salt** and returns as many bytes as you ask for. 64 bytes are split in two: **one key for encryption and a different one for the HMAC** — never use one key for two jobs. The salt is not secret: store it next to the package. The constructor has several forms, so it is made with named arguments: `dnNew("Rfc2898DeriveBytes",[ :password = ..., :salt = ..., :iterations = ..., :hashAlgorithm = ... ])`.

### Encrypting

`Aes` (made with `new Aes().Create(NULL)`) needs a `Key` and an `IV` (*initialization vector*). The IV must be **new and random for every message**; it is not secret and is stored in front of the ciphertext. `CreateEncryptor(NULL)` gives the transformer and `TransformFinalBlock(text, 0, len)` encrypts a whole message. Byte arrays are plain Ring texts in this package, so the message goes in as it is and the ciphertext comes back as a text of bytes. AES works on blocks of 16 bytes, so the 28-byte message becomes 32 bytes.

The package is `IV (16) + ciphertext (32) + tag (32)` = 80 bytes. Protecting the same message twice gives different packages (step 5) because the IV differs, so an observer cannot even see that a message repeats.

### The tag

`HMACSHA256` with the MAC key computes a 32-byte tag over `IV + ciphertext`. `unprotect` recomputes it and compares. In step 4 one byte of the package is changed and the package is **refused** — no decryption, no garbage. The comparison `sameBytes` does not stop at the first difference: a comparison that stops early takes a different time for different inputs, and that difference can leak the tag to an attacker (*timing attack*).

> [!WARNING] Never decrypt data before you have verified it. Padding errors and other messages of the decryptor can reveal information about the plaintext (*padding oracle* attacks). Modern code also uses an authenticated mode such as AES-GCM; this lesson shows the construction by hand because it is available in every .NET version and explains why the tag exists.

### Signatures

RSA uses a **pair** of keys. `new RSA().Create(2048)` makes the pair; `ToXmlString(False)` exports the **public** half as text, which you may give to anyone. `SignData(data, hashAlgorithm, padding)` hashes the data with SHA-256 and signs the hash with the private key (256 bytes for a 2048-bit key). Anyone with the public key can `VerifyData` — and a change in the message, even `100` to `900`, makes the check fail (step 6). The private key never leaves the signer.

The algorithm and the padding are objects: `new HashAlgorithmName().SHA256`, `new RSASignaturePadding().Pkcs1`.

> [!NOTE] `ICryptoTransform` is an interface, so its `Dispose` is called by name: `oEncryptor.callMethod("Dispose",[])`. And `Aes.Create`, `CreateEncryptor` and the like have an overload with a name or key, so the form without arguments is written with `NULL`.

### What this program is not

It is a teaching construction. For real systems use a well-reviewed protocol (TLS for networks, the platform's data-protection APIs for files), keep keys out of source code, and have security-sensitive code reviewed by someone who knows the field.

## What you learned

- PBKDF2 keys and salts,
- AES with a fresh IV,
- encrypt-then-MAC and verifying first,
- a comparison that takes the same time,
- RSA signatures with a public key,
- byte arrays as Ring texts.

## Exercises

1. Put the salt in front of the package so that it can be opened with only the password.
2. Save the public key XML in a file and verify a signature in a second program.
3. Sign a file's SHA-256 hash instead of the whole file with `SignHash`.
4. Time `deriveKeys` and change the number of rounds; how many are comfortable for your computer?

## Next

[Tutorial 105: Digital signatures](tut-105-signatures.html)
