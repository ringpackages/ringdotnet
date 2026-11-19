---
title: "UDP"
lead: UDP sends separate messages without a connection. This lesson sends datagrams between two sockets of your own computer, answers the sender, waits with a time limit, and shows that UDP can lose data without telling anyone.
---

## What you will learn

- the difference between UDP (messages) and TCP (a stream),
- `UdpClient`: `Send`, `Receive`, `ReceiveAsync`, `Available`,
- binding to a port, and reading the port the system chose,
- answering the sender,
- a time limit with `Task.Wait(ms)`,
- why a program that uses UDP must expect lost messages.

The tutorial [Sockets](tut-25-sockets.html) used TCP: a connection, then a stream of bytes. UDP has no connection. Everything in this lesson runs on `127.0.0.1`, so it works without a network.

## The program

{{file:samples/UsingDotNet/tutorials/ch07_udp.ring}}

{{output:samples/UsingDotNet/tutorials/ch07_udp.ring}}

## How it works

### Datagrams

A UDP message is called a **datagram**. It is sent in one piece and received in one piece: three `Send` calls give three `Receive` results of 3, 12 and 5 bytes, never a joined or a half message (a TCP stream has no such borders). There is no `Accept` and no stream; a socket that wants to receive only needs a port. `new UdpClient([ :port = 0 ])` binds to a port that the system chooses, and `Client.LocalEndPoint.Port` tells which one. Texts are sent as bytes (`UTF8Encoding.GetBytes`) and read with `GetString`.

### Sending

`Send` has several forms, so it takes names: the bytes (`:dgram`), their count (`:bytes`) and the target (`:hostname` and `:port`, or an `:endPoint`). `Available` is the number of bytes waiting; after three datagrams of 3, 12 and 5 bytes it is 20.

### Receiving

`Receive` fills an `IPEndPoint` with the address of the sender (a `ref` parameter). In Ring the method returns a list: the data is the first item. `ReceiveAsync` is the task version; its result is read with `getProp("Result")` and has the data (`Buffer`) and the sender (`RemoteEndPoint`) ([Core concepts](concepts.html), *Plain objects*).

### Answering

The sender's address is in the received datagram, so an answer is a `Send` to that `RemoteEndPoint`. The client socket sent without binding, so the system gave it a port; the server found it in the datagram.

### Time limits and lost data

`Receive` waits for ever when nothing comes. `ReceiveAsync` plus `Wait(300)` gives a time limit: false means *nothing came in 300 ms*. A program that talks by UDP must expect that. A datagram can be lost, doubled or delivered in another order, and the sender is **not told**: step 5 sends to a port where nobody listens, and there is no error. If you need every message in order, use TCP; if you need speed and can live with losses (games, sensor values, name lookups, discovery on a local network), use UDP, and add a counter and a timeout with a resend where it matters.

> [!NOTE] Do not leave an unfinished `ReceiveAsync` when you close a socket in a real program: cancel it, or close the socket and catch the error that the waiting task then raises.

## What you learned

- UDP sends messages; TCP sends a stream,
- `UdpClient.Send`, `Receive`, `ReceiveAsync`, `Available`,
- answering to the sender's endpoint,
- a time limit for a receive,
- UDP gives no promise of delivery.

## Exercises

1. Write a small *time server*: it answers every datagram `time` with the current time.
2. Send 100 numbered datagrams quickly to a socket that is slow to read and count how many arrive (on one computer the answer is usually all of them: why is that no proof for UDP in general?).
3. Add a resend: the client sends, waits 200 ms for an answer and tries three times.
4. Send a datagram larger than 1500 bytes and look at what `Receive` returns.

## Next

[WebSockets](tut-156-websockets.html)
