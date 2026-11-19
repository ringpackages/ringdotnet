---
title: "Sockets"
lead: HTTP is built on top of simpler connections called sockets. This lesson builds a tiny TCP server and client in one program and has them talk, line by line.
---

## What you will learn

- what an address, a port, TCP and a socket are,
- `TcpListener` (the server) and `TcpClient` (the client),
- streams, readers and writers over a connection,
- the order in which a conversation happens.

## Words

| Word | Meaning |
|---|---|
| **IP address** | the address of a computer: `127.0.0.1` means *this computer* |
| **port** | a number (0–65535) that says which program on that computer |
| **TCP** | a reliable connection: bytes arrive in order, none lost |
| **socket** | one end of a connection |
| **listener** | a program that waits for others to connect |

## The program

{{file:samples/UsingDotNet/tutorials/ch07_sockets.ring}}

{{output:samples/UsingDotNet/tutorials/ch07_sockets.ring}}

## How it works

### The server side

`new TcpListener(new IPAddress().Loopback, 0)` prepares a listener on the *loopback* address (`127.0.0.1`, reachable only from this computer) and port `0`, which means "any free port". `Start(NULL)` starts it, and `LocalEndpoint.Port` tells which port was chosen.

### The client side

`new TcpClient()` is the client; `Connect("127.0.0.1", nPort)` connects. The operating system accepts the connection at once, even before the program calls `AcceptTcpClient`; this is why client and server can live in one program, without threads.

### Accepting

`oListener.AcceptTcpClient()` returns the server's end of the connection. Each end has a **stream** (`GetStream()`): bytes go in on one side and come out on the other.

### Readers and writers

Raw bytes are awkward; a `StreamReader` and a `StreamWriter` on the stream read and write **lines** of text. `AutoFlush = True` sends every line at once instead of waiting for a full buffer. A reader's `ReadLine()` waits until a whole line arrived.

### The conversation

For each message: the client writes a line, the server reads it, the server writes an answer, the client reads it. Each side must read exactly what the other side wrote; if both sides wait to read, the program **hangs** (a deadlock).

### Closing

Close the connections, then stop the listener.

## Real servers

In a real system the server and the clients are different programs. A server loops: accept a client, talk, accept the next. Ring code runs on one thread, so a server that serves many clients at once checks `oListener.Pending()` and polls its clients in turn; for a web server use the ASP.NET `WebServer` (the tutorial [HTTP](tut-09-http.html)), which handles the threading for you.

## What you learned

- an address and a port identify the other side,
- listener/accept on the server, connect on the client,
- streams, readers and writers,
- each read needs a matching write.

## Exercises

1. Make the server answer `pong` to `ping` and `unknown` to anything else.
2. Let the client send a number; the server answers its square.
3. Try a port that nobody listens on and catch the error from `Connect`.
4. Print the address the client sees: `oClient.Client.RemoteEndPoint.ToString()`.

## Next

[Messages on a TCP stream](tut-158-framing.html)
