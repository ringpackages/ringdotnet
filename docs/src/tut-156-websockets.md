---
title: "WebSockets"
lead: HTTP is a question and an answer. A WebSocket is a connection that stays open, so both sides can send a message whenever they like — the base of chats, live prices and games. This lesson runs a server and a client in one program and sends text, binary data and a long message in parts, and then closes the connection properly.
---

## What you will learn

- what a **WebSocket** is and how it starts (an HTTP request that asks to *upgrade*),
- a server with `HttpListener` and `AcceptWebSocketAsync`,
- a client with `ClientWebSocket` and `ConnectAsync`,
- **text** and **binary** messages with `SendAsync` and `ReceiveAsync`,
- how **bytes** go through the bridge: an `ArraySegment` that .NET fills,
- messages that arrive in **parts** (`EndOfMessage`),
- the **close handshake**.

The tutorials [Sockets](tut-25-sockets.html) and [UDP](tut-91-udp.html) sent bytes over TCP and UDP. A WebSocket adds *messages* on top of TCP, and a browser can use it.

## The program

{{file:samples/UsingDotNet/tutorials/ch07_websockets.ring}}

{{output:samples/UsingDotNet/tutorials/ch07_websockets.ring}}

> [!NOTE] This program uses a few generic functions (`dnNew`, `dnStatic`, `dnNewGeneric`, `callMethod`, `getProp`) where a class cannot be used. The lesson [The generic functions](tut-160-generic-calls.html) explains them.

## How it works

### The upgrade

A WebSocket starts as a normal HTTP request with the headers `Upgrade: websocket` and `Connection: Upgrade`. The server answers *101 Switching Protocols*, and from then on the connection is not HTTP any more: it carries messages in both directions until it is closed. In .NET the server side is an `HttpListener`: `GetContextAsync()` waits for a request, `Request.IsWebSocketRequest` says whether it asks for an upgrade, and `AcceptWebSocketAsync` does the upgrade and gives a `WebSocket`. (The `WebServer` of this package serves HTTP only; `HttpListener` is the .NET class for this job.) The program asks the system for a free port, so it cannot clash with another program.

### One thread, two sides

Server and client are both in the program, and Ring runs on one thread. The connecting and the accepting are two halves of one handshake, so the program **starts** both tasks first and then waits for both (`Wait(NULL)`). A cancellation token with a limit of 20 seconds makes every call fail with an error instead of waiting for ever if something is wrong.

### Bytes and the bridge

A message is a **byte array**. `SendAsync` takes an `ArraySegment<byte>`: a part of an array. A Ring text can hold any bytes, so `dnNew("System.ArraySegment`1[[System.Byte]]", [ text ])` makes a segment (and the array inside it) from the bytes of the text. For receiving, .NET must **write into an array that Ring can read afterwards**, and a Ring text is copied when it goes in. So the program makes a **byte buffer** with `dnBuffer(nSize)`: a .NET object that holds a live `byte[]`. The segment is made on that buffer, `ReceiveAsync` fills it, and `dnBufferBytes(oBuffer, count)` copies the first `Count` bytes into a Ring text. Ring strings are binary strings, so nothing is lost on the way (step 4 sends all 256 byte values).

### Text and binary

The message type is `"Text"` (the bytes are UTF-8 text) or `"Binary"` (anything). The server echoes each text in capital letters, so a round trip shows both directions. The result of `ReceiveAsync` has `Count`, `MessageType` and `EndOfMessage`.

### Messages in parts

A receiver has a buffer of a fixed size. A message that is bigger than the buffer comes in several parts, and `EndOfMessage` is false until the last one. The program reads in a loop and joins the parts: a message of 20 bytes with a buffer of 8 arrives as 8, 8 and 4. Real programs use a buffer of a few kilobytes and the same loop.

### Closing

Closing is a conversation too. The client calls `CloseOutputAsync("NormalClosure", "bye", token)`, which says *I send nothing more* and does not wait. The server receives a message of type `Close`, and its `CloseStatus` and `CloseStatusDescription` are the status and the text of the client. The server answers with `CloseAsync` and the client receives that answer: now both states are `Closed`. A connection that is just dropped (the program ends, the cable is pulled) makes the other side raise an error on the next receive, which a program must expect.

### Two forms of SendAsync

The `ClientWebSocket` class has `SendAsync` with four plain values (`segment`, `type`, `endOfMessage`, `token`). The `WebSocket` that the server gets has more forms of the method, so there it is one method that takes a list of names. The function `send` knows which of the two it has.

> [!NOTE] A server program that serves many clients needs one task for each connection, so that one slow client does not stop the others. Ring code runs on one thread, so such a server polls its connections in a loop (`Wait` with a short time limit) or uses the web server of the tutorial [A web service with a database](tut-16-web-service.html) for the HTTP part.

## What you learned

- a WebSocket as a connection that stays open,
- the server with `HttpListener` and the client with `ClientWebSocket`,
- sending and receiving text and binary messages through an `ArraySegment`,
- reading long messages in parts,
- the close handshake.

## Exercises

1. Make the server answer each message with its length.
2. Send a message of 10,000 bytes with a buffer of 1,024 and count the parts.
3. Let the client send a message after the server closed, and read the error.
4. Send a JSON text (the tutorial [JSON as a tree](tut-80-json-nodes.html)) and parse it on the other side.

## Next

[HttpClient in depth](tut-84-http-client.html)
