# NetMQ: a managed ZeroMQ; two pair sockets in one process talk through an inproc address (frames are texts and binary bytes)
load "pkg.ring"
pkgUse("netmq",[["NetMQ","4.0.2.2"]],[["NetMQ.dll",["NetMQ","NetMQ.Sockets"]],["AsyncIO.dll",[]]])
pkgImport("netmq","NetMQ.dll","NetMQ")
pkgImport("netmq","NetMQ.dll","NetMQ.Sockets")

oServer = new PairSocket()
oClient = new PairSocket()
oServer.Bind("inproc://ring-test")
oClient.Connect("inproc://ring-test")

oClient.callMethod("SendFrame",["hello"])
dnAssert("a text frame",oServer.callMethod("ReceiveFrameString",[]),"hello")

oServer.callMethod("SendFrame",["مرحبا"])
dnAssert("a text frame that is not English",oClient.callMethod("ReceiveFrameString",[]),"مرحبا")

cBytes = ""
for i = 0 to 255
	cBytes += char(i)
next
oClient.callMethod("SendFrame",[dnBuffer(cBytes)])
dnAssert("every byte value in a binary frame",oServer.callMethod("ReceiveFrameBytes",[]),cBytes)

oClient.callMethod("SendMoreFrame",["part one"])
oClient.callMethod("SendFrame",["part two"])
aParts = oServer.callMethod("ReceiveMultipartStrings",[]).toList()
dnAssert("a message of two frames",len(aParts),2)
dnAssert("the second frame",aParts[2],"part two")

oClient.Dispose()
oServer.Dispose()
dnType("NetMQ.NetMQConfig").callMethod("Cleanup",[0])
dnTestSummary()
