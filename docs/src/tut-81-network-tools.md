---
title: "Network tools"
lead: IP addresses, names, ping, network interfaces and "is this port open?" — the classes behind everyday network tools. Everything in this lesson runs on your own computer, so it works without internet.
---

## What you will learn

- `IPAddress`: parsing, families (IPv4, IPv6), loopback,
- `TryParse` and other methods with `out` parameters,
- `IPEndPoint`: an address and a port,
- `Dns.GetHostEntry`,
- `Ping`,
- `NetworkInterface`,
- checking whether a port accepts connections, with a time limit.

## The program

{{file:samples/UsingDotNet/tutorials/ch07_network_tools.ring}}

{{output:samples/UsingDotNet/tutorials/ch07_network_tools.ring}}

## How it works

### Addresses and `out` parameters

`IPAddress.Parse("192.168.1.20")` gives an object. `GetAddressBytes()` returns the four bytes as a Ring text (a `byte[]` is a text in this package), so `ascii(cBytes[1])` is 192. `AddressFamily` is `InterNetwork` for IPv4 and `InterNetworkV6` for IPv6, and `IsLoopback` tests for `127.0.0.1` and `::1`.

`IPAddress.TryParse(text, out address)` answers *yes or no* without raising an error. In .NET the address comes back through an `out` parameter; in Ring **a method with `out` parameters returns a list**: `[ success, the address ]`. So `aGood = oParser.TryParse("10.0.0.7")` gives `aGood[1]` = 1 and `aGood[2]` = the address. The same applies to every `TryParse` and `TryGetValue` of .NET.

### Endpoints

An `IPEndPoint` is an address plus a port. It is made with `new IPEndPoint(address, 8080)`.

### DNS

`Dns.GetHostEntry("localhost")` returns the names and addresses of a host. `localhost` is known without a network (usually both `127.0.0.1` and `::1`). A real name such as `example.com` needs the internet and can take seconds or raise an error: wrap it in `try` / `catch`.

### Ping

`Ping.Send("127.0.0.1")` sends an ICMP echo and returns a `PingReply` with `Status` (`Success`, `TimedOut`, ...), `RoundtripTime` in milliseconds and `Address`. Pinging 127.0.0.1 tests only your own network software; ping a real host to test a connection, and give `Send` a timeout.

### Interfaces

`NetworkInterface.GetAllNetworkInterfaces()` lists the network cards (and virtual ones). `NetworkInterfaceType` is a text: `Ethernet`, `Wireless80211`, `Loopback`... Their addresses and speeds are properties too; this lesson only counts them, because the details are about *your* computer.

### Is the port open?

The last step starts a `TcpListener` on port 0 (the system chooses a free port) and checks it with `portIsOpen`: `ConnectAsync([ :host = address, :port = port ])` starts the connection, `Task.Wait(500)` waits at most half a second, and a refused connection raises an error that the `try` turns into *no*. While the listener runs the answer is *yes*; after `Stop()` it is *no*. This is the whole idea of a port scanner — and the reason for the rules below.

> [!WARNING] Only test ports of computers that are yours or that you have permission to test. Scanning other people's computers can be a crime and is always rude. This tutorial only touches `127.0.0.1`.

> [!NOTE] The `catch` in `portIsOpen` also catches errors in the Ring code (a misspelled method name, for example), which then look like "port closed". While you develop, print `cCatchError` in the `catch` block.


## What you learned

- `IPAddress`, `IPEndPoint`,
- `out` parameters come back as a list,
- `Dns`, `Ping`, `NetworkInterface`,
- a connection test with a time limit.

## Exercises

1. Write `waitForPort(address, port, seconds)` that tries every 200 ms and returns when the port opens.
2. List the open ports of 127.0.0.1 between 8000 and 8010 after starting two listeners.
3. Ping `127.0.0.1` five times and print the average round trip.
4. Resolve a real host name with `Dns.GetHostEntry` and handle the error when there is no network.

## Next

[IP networks](tut-102-ip-networks.html)
