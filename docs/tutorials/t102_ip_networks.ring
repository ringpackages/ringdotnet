# IP networks - CIDR notation, the addresses of a subnet, "is this address in that network?" and a small allow list
load "dotnet.ring"
using {
	"System"
	"System.Net"
}

func main
	# A network is written in CIDR form: an address and the number of bits that are the same for the whole network.
	# 192.168.1.0/24 means: the first 24 bits (192.168.1) are fixed, the last 8 bits (0 to 255) are free.
	oNetworkClass = new IPNetwork()
	aParsed = oNetworkClass.TryParse("192.168.1.0/24")
	oNetwork = aParsed[2]
	? "1. network: " + oNetwork.ToString()
	? "   base address: " + oNetwork.BaseAddress.ToString() + ", prefix length: " + oNetwork.PrefixLength

	# 2. Contains answers whether an address belongs to the network
	oIP = new IPAddress()
	? nl + "2. 192.168.1.77 is inside:  " + oNetwork.Contains(oIP.Parse("192.168.1.77"))
	? "   192.168.2.5 is inside:   " + oNetwork.Contains(oIP.Parse("192.168.2.5"))
	? "   192.168.1.255 is inside: " + oNetwork.Contains(oIP.Parse("192.168.1.255")) + "   (the broadcast address is part of the range)"

	# 3. The number of addresses is 2 to the power of (32 - prefix). Smaller networks have a longer prefix.
	? nl + "3. addresses in a network:"
	for cText in ["10.0.0.0/8","172.16.0.0/12","192.168.0.0/16","192.168.1.0/24","192.168.1.0/28","192.168.1.5/32"]
		aOne = oNetworkClass.TryParse(cText)
		? "   " + padRight(cText,17) + addressCount(aOne[2].PrefixLength)
	next

	# 4. A wrong network is refused: the address must be the BASE of the network (the free bits are zero)
	? nl + "4. 192.168.1.77/24 is a network: " + oNetworkClass.TryParse("192.168.1.77/24")[1] + "   (the last bits are not zero)"
	? "   192.168.1.0/33 is a network: " + oNetworkClass.TryParse("192.168.1.0/33")[1] + "   (IPv4 has 32 bits)"
	? "   192.168.1.0/24 is a network: " + oNetworkClass.TryParse("192.168.1.0/24")[1]

	# 5. An allow list: the private ranges of RFC 1918, and a check that says whether an address is private
	aPrivate = ["10.0.0.0/8","172.16.0.0/12","192.168.0.0/16"]
	? nl + "5. which of these addresses are private:"
	for cAddress in ["10.4.4.4","172.20.1.1","172.32.0.1","192.168.200.9","8.8.8.8","127.0.0.1"]
		? "   " + padRight(cAddress,15) + isPrivate(cAddress,aPrivate)
	next

	# 6. IPv6 works the same way
	oV6 = oNetworkClass.TryParse("2001:db8::/32")[2]
	? nl + "6. 2001:db8:1::5 is in 2001:db8::/32: " + oV6.Contains(oIP.Parse("2001:db8:1::5")) + ", 2001:db9::1: " + oV6.Contains(oIP.Parse("2001:db9::1"))

func addressCount nPrefix
	return floor(pow(2,32 - nPrefix))

func isPrivate cAddress,aRanges
	oNet = new IPNetwork()
	oAddress = new IPAddress().Parse(cAddress)
	for cRange in aRanges
		if oNet.TryParse(cRange)[2].Contains(oAddress)
			return "private (" + cRange + ")"
		ok
	next
	return "not in the private ranges"

func padRight cText,nWidth
	return cText + copy(" ",nWidth - len(cText))
