---
title: "Tutorial 63: A chat over TCP"
lead: A server that relays every line to all clients, two chat windows that connect to it, and a timer that polls the sockets so the windows never freeze. A real network program in one file.
---

## What you will learn

- the structure of a chat: one server, many clients,
- a text protocol with one message per line,
- why a window program must **never wait** for the network,
- reading the bytes that are available, and building lines from them,
- polling with a timer,
- testing network code with a pump and a short wait.

## The idea

The server listens on a port. Each client connects and sends lines such as `Alice: Hello`. The server sends **every** line it receives to **all** clients, including the sender, so everybody sees the same conversation in the same order. The protocol is the simplest possible: one message per line, the sender's name at the start. [Tutorial 25](tut-25-sockets.html) explains sockets; here they are used in a window program.

## The program

{{file:docs/tutorials/g64_chat.ring}}

![The chat](img/shots/tut-g64.png "Two clients and one server in one program; the title shows the port that the server chose")

{{output:docs/tutorials/g64_chat.ring --selftest}}

## How it works

### Never wait in a window program

`StreamReader.ReadLine()` waits until a whole line arrives. In a window program that means the window freezes: it cannot repaint or answer clicks. Ring has one thread, so waiting is not allowed. The solution has two parts:

1. **Ask first.** `NetworkStream.DataAvailable` says whether bytes are waiting. `LineReader.lines()` reads only the bytes that are there (`ReadByte`), adds them to a buffer, and returns a line each time it sees a line feed (byte 10). An unfinished line stays in `cPartial` until the next call.
2. **Ask often.** A `uiTimer` calls `pump()` every 100 milliseconds: the server accepts new connections (`Pending()`), reads and relays the lines, and each client shows what it received.

A Ring text is a list of bytes, so `cPartial += char(nByte)` rebuilds UTF-8 text correctly, also for non-English letters.

### The classes

- **`LineReader`** turns a stream into lines without waiting.
- **`ChatServer`** keeps a list of connections `[socket, reader, writer]`; `poll()` accepts, reads, and writes each received line to every connection.
- **`ChatClient`** connects, sends `"Name: text"` and returns the lines that arrived.

The two windows live in the same program only to make the tutorial easy to run; the classes would work the same in different programs on different computers. Give the server's address instead of `127.0.0.1`.

> [!WARNING] Two Ring details that cost time while writing this lesson: `for x in object.method()` calls the method *again for every item*, so a method that consumes data must be assigned to a variable first; and a variable named `oR` is read as the keyword `or`.

### Testing

The self test sends a line from Alice and calls `waitForText`, which pumps up to 50 times with a 20 ms sleep until both windows show the line — network messages arrive a little later, so a test must wait for them instead of checking at once. Then it checks that Bob's line arrives in both windows, that the server has two clients, and that an empty text is not sent.

## What you learned

- server and clients with `TcpListener` and `TcpClient`,
- a line-based protocol,
- polling with a timer instead of waiting,
- `DataAvailable` and `ReadByte`,
- testing asynchronous code with a bounded wait.

## Exercises

1. Show a list of the connected names and tell everybody when somebody joins.
2. Add a third window.
3. Send a private message with `/to Bob text`: the server must send it only to Bob.
4. Close a client and make the server remove the dead connection from its list.

## Where to go next

You have reached the end of the tutorials. Keep [Core concepts](concepts.html), the [class reference](api.html) and [Gotchas & limits](gotchas.html) at hand, and read the [applications](gallery-apps.html) for bigger programs.
