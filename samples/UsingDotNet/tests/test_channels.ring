# System.Threading.Channels (part of .NET): a channel of generic type with a writer and a reader; TryWrite, TryRead (an out value), count, completion.
# The channel types are generic classes without a Ring class: members are read with getProp and called with callMethod.
load "dotnet.ring"

oChannel = dnType("System.Threading.Channels.Channel").callGeneric("CreateUnbounded",["System.String"],[])
oWriter = oChannel.getProp("Writer")
oReader = oChannel.getProp("Reader")

dnAssert("a new channel is empty",oReader.getProp("Count"),0)
dnAssert("a write is accepted",oWriter.callMethod("TryWrite",["one"]),1)
oWriter.callMethod("TryWrite",["two"])
oWriter.callMethod("TryWrite",["مرحبا"])
dnAssert("three items wait",oReader.getProp("Count"),3)

aItem = oReader.callMethod("TryRead",[])
dnAssert("a read finds an item",aItem[1],1)
dnAssert("the first in is the first out",aItem[2],"one")
dnAssert("the next one",oReader.callMethod("TryRead",[])[2],"two")
dnAssert("a text that is not English",oReader.callMethod("TryRead",[])[2],"مرحبا")
dnAssert("nothing left",oReader.callMethod("TryRead",[])[1],0)

oBounded = dnType("System.Threading.Channels.Channel").callGeneric("CreateBounded",["System.Int32"],[2])
oBoundedWriter = oBounded.getProp("Writer")
dnAssert("the first fits",oBoundedWriter.callMethod("TryWrite",[1]),1)
dnAssert("the second fits",oBoundedWriter.callMethod("TryWrite",[2]),1)
dnAssert("the third waits for room",oBoundedWriter.callMethod("TryWrite",[3]),0)

oWriter.callMethod("TryComplete",[])
dnAssert("a completed channel takes no more",oWriter.callMethod("TryWrite",["late"]),0)

dnTestSummary()
