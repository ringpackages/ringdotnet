# IPNetwork2: CIDR networks (parse, contain, subnet, supernet, usable addresses); a struct-like object with operators and enum-like properties
load "pkg.ring"
pkgUse("ipnetwork",[["IPNetwork2","5.0.1"]],[["System.Net.IPNetwork.dll",["System.Net"]]])
pkgImport("ipnetwork","System.Net.IPNetwork.dll","System.Net")
dnImport("System.Net")

oNetwork = dnStatic("System.Net.IPNetwork2","Parse",["192.168.1.0/24"])
dnAssert("the network address",oNetwork.Network.ToString(),"192.168.1.0")
dnAssert("the broadcast address",oNetwork.Broadcast.ToString(),"192.168.1.255")
dnAssert("the netmask",oNetwork.Netmask.ToString(),"255.255.255.0")
dnAssert("the prefix length",oNetwork.Cidr,24)
dnAssert("the number of addresses",oNetwork.Total.ToString(),"256")
dnAssert("the number of usable addresses",oNetwork.Usable.ToString(),"254")
dnAssert("the first usable address",oNetwork.FirstUsable.ToString(),"192.168.1.1")
dnAssert("the last usable address",oNetwork.LastUsable.ToString(),"192.168.1.254")

# containing addresses and networks
oInside = dnStatic("System.Net.IPAddress","Parse",["192.168.1.77"])
oOutside = dnStatic("System.Net.IPAddress","Parse",["10.0.0.1"])
dnAssert("an address inside",oNetwork.Contains(oInside),1)
dnAssert("an address outside",oNetwork.Contains(oOutside),0)
oSmall = dnStatic("System.Net.IPNetwork2","Parse",["192.168.1.128/25"])
dnAssert("a network inside another",oNetwork.Contains(oSmall),1)
dnAssert("a network does not contain a bigger one",oSmall.Contains(oNetwork),0)

# subnets of a longer prefix
aSubnets = oNetwork.Subnet(26).toList()
dnAssert("a /24 has four /26 networks",len(aSubnets),4)
dnAssert("the second subnet",aSubnets[2].ToString(),"192.168.1.64/26")

# the supernet of two networks
oA = dnStatic("System.Net.IPNetwork2","Parse",["10.0.0.0/25"])
oB = dnStatic("System.Net.IPNetwork2","Parse",["10.0.0.128/25"])
oSuper = oA.Supernet(oB)
dnAssert("the supernet of two neighbours",oSuper.ToString(),"10.0.0.0/24")

# the addresses of a small network
oTiny = dnStatic("System.Net.IPNetwork2","Parse",["10.1.1.0/30"])
dnAssert("the addresses of a /30",len(oTiny.ListIPAddress(NULL).toList()),4)

# IPv6
oV6 = dnStatic("System.Net.IPNetwork2","Parse",["2001:db8::/32"])
dnAssert("an IPv6 network",oV6.Network.ToString(),"2001:db8::")
dnAssert("the address family",oV6.AddressFamily,"InterNetworkV6")
dnAssert("an IPv6 address inside",oV6.Contains(dnStatic("System.Net.IPAddress","Parse",["2001:db8:1::1"])),1)

# a bad network
aTry = dnStatic("System.Net.IPNetwork2","TryParse",["999.1.1.1/8"])
dnAssert("a bad network does not parse",aTry[1],0)

dnTestSummary()
