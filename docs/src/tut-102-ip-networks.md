---
title: "Tutorial 102: IP networks"
lead: Which addresses belong to a network? Is this client allowed in? The IPNetwork type answers these questions with the CIDR notation that firewalls, cloud consoles and configuration files use. This lesson parses networks, counts their addresses, tests addresses and builds a small allow list.
---

## What you will learn

- the **CIDR** notation (`192.168.1.0/24`),
- `IPNetwork`: `TryParse`, `BaseAddress`, `PrefixLength`, `Contains`,
- how many addresses a network has,
- what a wrong network looks like,
- an allow list for private addresses (RFC 1918),
- IPv6.

[Tutorial 81](tut-81-network-tools.html) used `IPAddress` and `IPEndPoint`. This lesson goes one level up: a *range* of addresses. A web program ([tutorial 16](tut-16-web-service.html)) uses it to allow or refuse a client by its address.

## The program

{{file:docs/tutorials/t102_ip_networks.ring}}

{{output:docs/tutorials/t102_ip_networks.ring}}

## How it works

### CIDR notation

An IPv4 address has 32 bits. A network is written as an address and a **prefix length**: the number of bits at the start that are the same for every address of the network. In `192.168.1.0/24` the first 24 bits (`192.168.1`) are fixed and the last 8 bits are free, so the network holds the addresses `192.168.1.0` to `192.168.1.255`. `IPNetwork.TryParse(text)` answers `[ success, network ]` ([tutorial 81](tut-81-network-tools.html)); the network has `BaseAddress`, `PrefixLength` and `ToString()`.

### Contains

`oNetwork.Contains(address)` tells whether an `IPAddress` is inside the range. The first and the last address of the range (`192.168.1.0` and `192.168.1.255`) count as inside; in a real network they are the network and the broadcast address and are not given to computers, but `Contains` only looks at the bits.

### How many addresses

A network with prefix length *p* has 2 to the power of *(32 − p)* addresses. `/8` has 16 777 216, `/16` has 65 536, `/24` has 256, `/28` has 16 and `/32` has just one address (a single computer). A **longer** prefix means a **smaller** network. For IPv6 the number is 2 to the power of *(128 − p)*, which is too big for a Ring number, so a program counts bits instead.

### A wrong network

The address in the text must be the **base** of the network: the free bits must be zero. `192.168.1.77/24` is refused because `77` has bits in the last 8 positions; write `192.168.1.0/24`. A prefix longer than 32 (`/33`) is refused for IPv4. `TryParse` is a yes or no, so the check is safe for text that a user typed.

### An allow list

Step 5 keeps the three private ranges of RFC 1918 (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) in a Ring list and checks an address against each. `172.20.1.1` is private and `172.32.0.1` is not, because the second range ends at `172.31.255.255` — the kind of boundary that is easy to get wrong with text comparison and impossible to get wrong with `Contains`. `127.0.0.1` is *loopback*, not private, so it is not in the list.

> [!WARNING] The address a program sees may not be the address of the real client. Behind a proxy or a load balancer every request seems to come from the proxy; the real address is in a header such as `X-Forwarded-For`, and that header can be written by the client. Trust it only when your own proxy sets it.

### IPv6

The same type works for IPv6: `2001:db8::/32` holds every address that starts with `2001:db8`, so `2001:db8:1::5` is inside and `2001:db9::1` is not.

## What you learned

- CIDR: an address and a prefix length,
- `IPNetwork.TryParse`, `BaseAddress`, `PrefixLength`, `Contains`,
- the size of a network, 2 to the power of (bits − prefix),
- the base address rule,
- an allow list in a Ring list.

## Exercises

1. Write `networkOf(cAddress, nPrefix)` that returns the network that contains an address.
2. Write an allow list that reads its networks from a settings file ([tutorial 32](tut-32-settings.html)).
3. Use the list in [tutorial 55](tut-55-miniweb.html) so that only addresses of `127.0.0.0/8` can see the page.
4. Print the first and last address of `192.168.1.64/26`.

## Where to go next

You have reached the end of the tutorials. Keep [Core concepts](concepts.html), the [class reference](api.html) and [Gotchas & limits](gotchas.html) at hand, and read the [applications](gallery-apps.html) for bigger programs.
