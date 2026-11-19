# network tools - IP addresses, DNS, ping, network interfaces and checking whether a port is open (all on this computer)
load "dotnet.ring"
using {
	"System"
	"System.Net"
	"System.Net.Sockets"
	"System.Net.NetworkInformation"
}

func main
	# 1. IPAddress parses an address and knows its family. A method with an "out" parameter returns a list: [success, the address].
	oParser = new IPAddress()
	oAddress = oParser.Parse("192.168.1.20")
	cBytes = oAddress.GetAddressBytes()                                  # the 4 bytes of an IPv4 address (a byte[] is a Ring text)
	? "1. " + oAddress.ToString() + " is " + oAddress.AddressFamily + ", " + len(cBytes) + " bytes, the first is " + ascii(cBytes[1])
	aGood = oParser.TryParse("10.0.0.7")
	aBad = oParser.TryParse("999.1.1.1")
	? "   TryParse('10.0.0.7'): " + yesNo(aGood[1]) + ", TryParse('999.1.1.1'): " + yesNo(aBad[1])
	oV6 = oParser.Parse("::1")
	? "   '::1' is " + oV6.AddressFamily + ", loopback: " + yesNo(oParser.IsLoopback(oV6))
	? "   private address 192.168.1.20 is not the loopback: " + yesNo(not oParser.IsLoopback(oAddress))

	# 2. An address plus a port is an IPEndPoint. Built from named arguments, because the constructor has several forms.
	oEndPoint = dnNew("IPEndPoint",[ :address = oAddress, :port = 8080 ])
	? nl + "2. the endpoint " + oEndPoint.ToString() + ": address " + oEndPoint.Address.ToString() + ", port " + oEndPoint.Port

	# 3. DNS: names to addresses. "localhost" is always known, also without a network.
	oHost = new Dns().GetHostEntry("localhost")
	aAddresses = oHost.AddressList.toList()
	? nl + "3. localhost has " + len(aAddresses) + " address(es); the first is a loopback address: " + yesNo(oParser.IsLoopback(aAddresses[1]))

	# 4. Ping: an ICMP echo. The reply has a status and the round trip time in milliseconds.
	oPing = new Ping()
	oReply = oPing.Send("127.0.0.1")
	? nl + "4. ping 127.0.0.1: " + oReply.Status + ", the answer came from " + oReply.Address.ToString() + ", fast (under 100 ms): " + yesNo(oReply.RoundtripTime < 100)
	oPing.Dispose()

	# 5. The network interfaces of this computer (the types are text: Ethernet, Wireless80211, Loopback...)
	aInterfaces = new NetworkInterface().GetAllNetworkInterfaces().toList()
	lLoopback = False
	for oInterface in aInterfaces
		if oInterface.NetworkInterfaceType = "Loopback"
			lLoopback = True
		ok
	next
	? nl + "5. the computer has network interfaces: " + yesNo(len(aInterfaces) > 0) + "; one of them is the loopback: " + yesNo(lLoopback)

	# 6. Is a port open? Start a listener on a free port: connecting works. Connect to a port where nobody listens: it is refused.
	oListener = new TcpListener(oParser.Loopback,0)
	oListener.Start(NULL)
	nOpenPort = oListener.LocalEndpoint.Port
	? nl + "6. a listener is on a port that the system chose: port is open = " + yesNo(portIsOpen("127.0.0.1",nOpenPort))
	oListener.Stop()
	? "   after Stop the same port is open = " + yesNo(portIsOpen("127.0.0.1",nOpenPort))

# true when a TCP connection to the address and port is accepted within half a second
func portIsOpen cAddress, nPort
	oClient = new TcpClient()
	lOpen = False
	try
		oTask = oClient.ConnectAsync([ :host = cAddress, :port = nPort ])
		lOpen = oTask.Wait(500) and oClient.Connected
	catch
		lOpen = False                          # refused or failed: the error is the answer
	done
	oClient.Dispose()
	return lOpen

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"
