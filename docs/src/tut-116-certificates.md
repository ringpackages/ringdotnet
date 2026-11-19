---
title: "Tutorial 116: Certificates"
lead: A certificate ties a public key to a name and a time of validity. HTTPS sites, signed programs and services that must prove who they are all use them. This lesson makes a self-signed X.509 certificate, reads what it contains, exports it with and without the private key, signs with it, and shows why a computer does not trust it.
---

## What you will learn

- what a **certificate** is: public key, subject, issuer, validity, thumbprint,
- making a **self-signed** certificate (`CertificateRequest`, `CreateSelfSigned`),
- **extensions** such as basic constraints,
- exporting: **PFX** (with the private key and a password) and **PEM / .cer** (public only),
- signing with the private key and verifying with the public certificate,
- trust and the **chain**.

[Tutorial 105](tut-105-signatures.html) signed data with a bare key pair. A certificate adds the answer to *"whose key is this?"*.

## The program

{{file:docs/tutorials/t116_certificates.ring}}

{{output:docs/tutorials/t116_certificates.ring}}

## How it works

### What a certificate says

A certificate is a small document, signed by an **issuer**, that says: *the public key below belongs to the subject named here, and this is true from this date to that date*. The **subject** is a distinguished name such as `CN=Demo Server, O=RingDotNet, C=EG` (common name, organisation, country). The **thumbprint** is the SHA-1 hash of the whole certificate: a short identifier that you compare to be sure it is *this* certificate and not another one with the same name.

In the real world the issuer is a **certificate authority** (CA) that your computer trusts, and it checks who you are before it signs. In a **self-signed** certificate the subject and the issuer are the same: the certificate vouches for itself. That is useful for tests, for development and for programs that talk to each other on a network you control (you install the certificate on both sides yourself), but no browser trusts it.

### Making one

`RSA.Create(2048)` makes the key pair. A `CertificateRequest` collects the subject name (an `X500DistinguishedName`), the key, the hash algorithm (SHA-256) and the padding (PKCS #1). Extensions are added to `CertificateExtensions`: here **basic constraints** with *not a CA*, because this certificate must not be able to sign other certificates. A server certificate also usually has a *subject alternative name* with the host names and a *key usage*. `CreateSelfSigned(notBefore, notAfter)` signs it with its own key. The validity starts a day in the past, because computers whose clocks differ by a few minutes would otherwise refuse a certificate that was just made. The classes `HashAlgorithmName` and `RSASignaturePadding` have their values as static properties, read with `dnStatic("...","get_SHA256",[])`; the constructors have several forms, so `dnNew` takes names ([Core concepts](concepts.html)).

### Exporting

- **PFX** (also *PKCS #12*) holds the certificate **and the private key**, protected by a **password**. `Export("Pfx", password)` makes the bytes and `new X509Certificate2(bytes, password)` loads them again; a wrong password raises an error. A PFX is a secret: store it like a password, and give it only to the program that must sign or serve with it.
- **PEM** (`ExportCertificatePem()`, the text between `-----BEGIN CERTIFICATE-----` lines) and **.cer** (`Export("Cert")`) hold the **public** part only. This is what you give to everybody. A certificate loaded from it has `HasPrivateKey` false.

### Signing and verifying

The owner takes the private key out of the certificate (`RSACertificateExtensions.GetRSAPrivateKey`) and signs the data; anybody with the **public** certificate verifies it with `GetRSAPublicKey` and `VerifyData`. The signature has 256 bytes for a 2048-bit key. A changed message is refused, and the public-only certificate cannot sign at all (it has no private key). The two helper methods are extension methods, so they are called with `dnStatic` ([tutorial 109](tut-109-memory-cache.html)).

### Trust

`X509Chain.Build(certificate)` asks the system whether it can build a chain from the certificate up to a **trusted root**. For a self-signed certificate that nobody installed as trusted, the answer is *false*. To make a computer trust such a certificate, you add it to its store of trusted roots (`X509Store`), which needs the user's decision and often administrator rights; do that only for certificates you made yourself and for development. Never ask users to install a certificate "to make the warning go away" for a site on the internet.

> [!WARNING] A certificate is only as good as the care of its private key. If the PFX or its password is stolen, the thief can sign as you until the certificate expires or is revoked. Keep validity short, keep keys out of source control, and renew before the end date.

## What you learned

- subject, issuer, validity and thumbprint,
- `CertificateRequest` and `CreateSelfSigned`,
- PFX with a password for the private key, PEM and .cer for the public part,
- signing with the private key, verifying with the public certificate,
- why a self-signed certificate is not trusted.

## Exercises

1. Add a subject alternative name (`SubjectAlternativeNameBuilder`) for `localhost` and `127.0.0.1`.
2. Write the PEM to a file ([tutorial 5](tut-05-files.html)) and read it back with `X509Certificate2.CreateFromPem`.
3. Make a second certificate with a validity of one second and look at `NotAfter` and the check in `isValidNow` after a pause.
4. Find the certificates of your own computer: open the store `Root` with `X509Store` and print the subjects of the first five ([tutorial 118](tut-118-registry.html) shows another store of Windows).

## Next

[Tutorial 113: Protecting data](tut-113-data-protection.html)
