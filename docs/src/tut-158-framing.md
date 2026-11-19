---
title: "Messages on a TCP stream"
lead: TCP carries a stream of bytes, not messages: two writes can arrive as one read, and one write as two. A protocol that sends messages must say where each one ends. This lesson adds a length prefix, reads exactly n bytes with a buffer, handles partial reads, sends empty and binary messages and refuses a length that is too big.
---

## What you will learn

- why TCP has **no message boundaries**,
- a **length prefix**: four bytes in network order (big endian),
- `Read` that returns **fewer bytes** than asked, and reading **exactly n bytes** in a loop,
- sending text, binary, empty and long messages,
- several messages written together and read one by one,
- a **maximum length** that protects the receiver.

The tutorial [Sockets](tut-25-sockets.html) sent a few lines over TCP. Real protocols (chat, file transfer, a database) send many messages of different sizes.

## The program

{{file:samples/UsingDotNet/tutorials/ch07_framing.ring}}

{{output:samples/UsingDotNet/tutorials/ch07_framing.ring}}

## How it works

### A stream, not a list of messages

If a program writes `ab` and then `cd`, the other side may read `abcd` at once, or `a` and `bcd`: the operating system splits and joins the bytes as it likes, and a read gives *what has arrived so far*. A program that assumes *one write is one read* works on the test computer and fails on a slow network or with a long message. The receiver needs to be told where a message ends.

### The length prefix

Each message starts with its **length** in four bytes, biggest byte first (the order of the network, called **big endian**): 300 is `00 00 01 2C` (1 × 256 + 44). The receiver reads four bytes, decodes the length, and then reads exactly that many bytes. `lengthBytes` and `bytesLength` convert in both directions with `char` and `ascii`; a Ring text holds the bytes. Other ways to mark the end exist (a line ending, a special byte), but a length works for any data, including bytes that look like the marker.

### Exactly n bytes

`Read(buffer, offset, count)` returns the number of bytes that it wrote, which can be **less than `count`**: the rest has not arrived yet. `readExact` makes a buffer of the size that it needs and calls `Read` again and again, each time into the **next part** of the same buffer (`offset = nGot`, `count = nCount - nGot`), until all the bytes are there. A `Read` that returns `0` means that the other side closed the connection, and in the middle of a message that is an error, which the function raises.

### The messages

The program sends a text, a message with a NUL and a byte over 127, an **empty** message (the length is 0 and there is nothing more to read) and one of 40,000 bytes, and each comes back as it was sent. A Ring text can hold the bytes, and `dnBuffer` gives `Read` an array to fill. Step 4 writes three messages one after the other and reads them one by one: the boundaries come from the lengths and not from the writes.

### A limit

The length is a number from the **network**, so it can be anything. A message that says that it has 50,000,000 bytes makes a careless receiver allocate that much memory, which is a way to stop a server (a *denial of service*). `readMessage` has a maximum and **refuses** a bigger length before it allocates anything. The sender of a real protocol is also checked (and the connection is closed after the refusal, because the bytes that follow can not be understood any more).

> [!NOTE] The test sends and reads in one program on one thread, so a message must fit in the buffers of the connection (about 64 KB) or `Write` would wait for a reader that never starts. A real client and server run in separate programs or threads.

## What you learned

- TCP is a stream and needs a protocol for messages,
- a length prefix in big endian,
- reading exactly n bytes into a buffer, with partial reads,
- empty and binary messages,
- a maximum length.

## Exercises

1. Add a message type (one byte) after the length: `T` for text and `B` for binary.
2. Write `writeMessage` so that it sends the length and the message in **one** write (join them first).
3. Make the receiver close the connection after a refused length and tell the sender.
4. Add a checksum (four bytes of `CRC32` or the start of a SHA-256) after each message and check it.

## Next

[UDP](tut-91-udp.html)
