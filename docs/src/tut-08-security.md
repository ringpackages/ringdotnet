---
title: "Hashing and encryption"
lead: Checksums that fingerprint data, password hashes that are safe to store, a key that proves a message was not changed, random tokens and real encryption with AES.
---

## What you will learn

- the difference between **hashing** and **encryption**,
- SHA-256 hashes,
- storing passwords correctly with a salt and many rounds (PBKDF2),
- HMAC and random tokens,
- encrypting and decrypting text with AES.

> [!WARNING] This is a first look at the ideas, not a security course. For real systems use the standard libraries as shown here, never invent your own scheme, and keep keys out of your source code.

## Hashing and encryption

| | Hashing | Encryption |
|---|---|---|
| Direction | one way: you cannot get the data back | two ways: you can decrypt with the key |
| Result size | always the same (SHA-256: 32 bytes) | about the size of the data |
| Use | check that data is the same; store passwords | keep data secret |

A **hash** is a fingerprint. The same input always gives the same hash; a tiny change gives a completely different hash.

## The program

{{file:docs/tutorials/t08_security.ring}}

{{output:docs/tutorials/t08_security.ring}}

> [!NOTE] The random values (the salt, the token) change on every run, so your output will differ in those lines.

## How it works

### SHA-256 and MD5

`new SHA256().HashData("abc")` returns the hash bytes; `Convert.ToHexString` writes them as hexadecimal. SHA-256 is the modern standard. **MD5 is broken for security**: it is only fine for a quick checksum of a download.

### Passwords

Never store a password, and never store a plain hash of it either (attackers have tables of hashes of common passwords). Store a **salted, slow hash**:

- a **salt** is random data mixed in, so two people with the same password get different hashes,
- **many rounds** (`iterations`) make each guess slow for an attacker.

`Rfc2898DeriveBytes` (PBKDF2) does both. To check a login you hash the typed password with the **same salt** and compare it with the stored hash. The program shows the right password matching and a wrong one failing. (Store the salt next to the hash.)

### HMAC

An HMAC is a hash that needs a secret key. If you and a server share the key, an HMAC on a message proves the message was not changed on the way.

### Random tokens

For secrets (session ids, reset links) use `RandomNumberGenerator.GetBytes(n)`. The ordinary `Random` class is predictable and must not be used for secrets.

### AES

AES is the standard encryption. `Aes.Create(NULL)` makes an encryptor; `GenerateKey()` and `GenerateIV()` create a random key and *initialisation vector*; `CreateEncryptor(NULL).TransformFinalBlock(text, 0, length)` encrypts, `CreateDecryptor(NULL)` decrypts. Anyone with the key and the IV can decrypt, so those must be kept safe and passed to the receiver separately from the data.

## What you learned

- hashing is one way, encryption is two ways,
- a password hash needs a salt and many rounds,
- `RandomNumberGenerator` for secrets,
- `NULL` selects a method's version without parameters.

## Exercises

1. Write `checksum(cFile)` that returns the SHA-256 of a file's bytes (`File.ReadAllBytes`).
2. Make a tiny "user store": a dictionary of `user → [salt, hash]` with `register` and `login` functions.
3. Compute the HMAC of a message with two different keys. Are the results different?
4. Encrypt a file's text with AES and write the cipher as Base64 text.

## Next

[HTTP](tut-09-http.html)
