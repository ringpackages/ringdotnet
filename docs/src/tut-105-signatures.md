---
title: "Tutorial 105: Digital signatures"
lead: A digital signature shows who wrote a message and that nobody changed it. This lesson makes an ECDsa key pair, signs a message, verifies it, shows that a changed message or another key fails, and shares only the public key.
---

## What you will learn

- what a signature proves, and what it does not,
- **private** and **public** keys,
- `ECDsa`: making a key, `SignData`, `VerifyData`,
- why a changed message or a different key fails,
- sharing the public key and nothing else.

[Tutorial 8](tut-08-security.html) used hashes and encryption and [tutorial 78](tut-78-crypto.html) used RSA and more. A signature adds the answer to *"who?"*.

## The program

{{file:docs/tutorials/t105_signatures.ring}}

{{output:docs/tutorials/t105_signatures.ring}}

## How it works

### What a signature proves

A key pair has two parts that fit each other. The **private key** stays with its owner and makes signatures. The **public key** can be given to everybody and only *checks* signatures. A valid signature proves two things: the message was signed by the **owner of the private key**, and the message is **exactly** the signed one — changing a single character makes the check fail. It does **not** hide the message (that is encryption) and it does not prove that the owner is the person you think; for that you need a certificate from somebody you trust.

### ECDsa

`ECDsa` uses elliptic curves: a 256-bit key gives the security of a much longer RSA key, and signing is fast. The key is made on a named curve: `ECCurve.CreateFromFriendlyName("nistP256")` and then `ECDsa.Create(curve)`. These are static methods, called with `dnStatic(type, method, [arguments])`; the key object has no generated Ring class, so its methods are called with `callMethod("Name", [arguments])` and its properties with `getProp` ([Core concepts](concepts.html), *Plain objects*). The key size is 256 bits and a signature on this curve has 64 bytes.

### Sign and verify

`SignData(data, hashAlgorithm)` hashes the data (SHA-256) and signs the hash; `VerifyData(data, signature, hashAlgorithm)` answers *true* or *false*. The data is a byte array: a Ring text of bytes (`UTF8Encoding.GetBytes`). Step 3 shows the three results that matter: the original message is valid, the changed message ("100" to "900") is **not**, and a second signature of the same message is also valid but **different** from the first, because a random number is part of every ECDsa signature. So never compare signatures to see whether a message is the same: always verify.

### Another key

A signature made with one key does not verify with another key (step 4). Nobody can sign in your name without your private key, which is why the private key must be kept safe: in a file with strict rights, in a key store or in a hardware token, and never in the source code or in a mail.

### Sharing the public key

`ExportParameters(False)` returns the curve and the **public** point of the key, without the private number (`True` would include it). The receiver makes a new key object and imports these parameters (`ImportParameters`); now it can verify, and it *cannot sign*: `SignData` raises an error because there is no private key. In a real program you send the public key as a file (PEM or the bytes) or fetch it from a certificate. The bridge cannot pass `Span` parameters, so the byte-array methods `ExportSubjectPublicKeyInfo` and `ImportSubjectPublicKeyInfo` are not used here.

> [!WARNING] Sign **bytes**, not "the same text": agree exactly on the bytes (the encoding, the line endings, the order of the fields). A message that is written as JSON by one program and re-written by another may be the same *data* but not the same *bytes*, and then the signature fails. Sign the exact bytes that you send.

## What you learned

- a signature proves the owner and the integrity, not secrecy,
- the private key signs and the public key verifies,
- `ECCurve.CreateFromFriendlyName`, `ECDsa.Create`, `SignData`, `VerifyData`,
- a changed message or another key fails,
- export the public parameters and keep the private key.

## Exercises

1. Sign a file ([tutorial 5](tut-05-files.html)) and write the signature to another file; verify both later.
2. Write `signedMessage(text)` that returns the text and its signature as Base64 in a JSON object ([tutorial 100](tut-100-json-writer.html)).
3. Change one byte of the signature and check that verification fails.
4. Try the curve `nistP384` and look at the size of the signature.

## Next

[Tutorial 106: Arrays](tut-106-arrays.html)
