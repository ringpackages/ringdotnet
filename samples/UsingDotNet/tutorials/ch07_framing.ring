# messages on a TCP stream - TCP has no message boundaries: a length prefix, reading exactly n bytes, partial reads and a limit
load "dotnet.ring"
using {
	"System"
	"System.Net"
	"System.Net.Sockets"
}

func main
	# TCP is a STREAM of bytes, not a list of messages. If a program writes "ab" and then "cd", the other side may read "abcd" in one call,
	# or "a" and "bcd", or ... The sizes of the pieces that Read returns have nothing to do with the sizes of the writes. A protocol that
	# sends MESSAGES must say where each one ends: here every message has a LENGTH PREFIX, four bytes with the size of the message,
	# and then the message itself.
	oListener = new TcpListener(new IPAddress().Loopback,0)
	oListener.Start(NULL)
	oClient = new TcpClient().New_([ :hostname = "127.0.0.1", :port = oListener.LocalEndpoint.Port ])
	oServerSide = oListener.AcceptTcpClient()
	oSender = oClient.GetStream()
	oReceiver = oServerSide.GetStream()
	? "1. connected"

	# 2. The length as four bytes (big endian: the biggest byte first, the order of the network)
	? nl + "2. the length as four bytes:"
	for nLength in [ 0, 5, 300, 40000 ]
		? "   " + padLeft("" + nLength,6) + " -> " + hexText(lengthBytes(nLength))
	next
	? "   decoded again: " + bytesLength(lengthBytes(40000))

	# 3. Messages: text, bytes that are not text (a NUL and a byte over 127), an empty message, and a long one. Each is written as ONE
	#    message, and read back as one message, whatever the pieces of the TCP stream were.
	? nl + "3. messages through the stream:"
	aMessages = [ "hello", "a" + char(0) + "b" + char(255), "", copy("0123456789",4000) ]
	for cMessage in aMessages
		writeMessage(oSender,cMessage)
		aResult = readMessage(oReceiver,100000)
		? "   sent " + padLeft("" + len(cMessage),5) + " bytes, received " + padLeft("" + len(aResult[1]),5) + " bytes; the same: " + yesNo(aResult[1] = cMessage)
	next

	# 4. Several messages written together: the receiver still gets them one by one
	writeMessage(oSender,"one")
	writeMessage(oSender,"two")
	writeMessage(oSender,"three")
	? nl + "4. three messages written together are read as: " + readMessage(oReceiver,1000)[1] + ", " + readMessage(oReceiver,1000)[1] + ", " + readMessage(oReceiver,1000)[1]

	# 5. A limit. The length comes from the network, so it can be anything: 4 gigabytes would make the receiver allocate 4 gigabytes.
	#    A protocol has a maximum, and a message with a bigger length is refused before any memory is used.
	oSender.Write(lengthBytes(50000000),0,4)
	? nl + "5. a message that claims 50,000,000 bytes (the limit is 1,000): " + readMessage(oReceiver,1000)[1]

	oClient.Close()
	oServerSide.Close()
	oListener.Stop()

# the length as four bytes, biggest first
func lengthBytes nLength
	return char(floor(nLength / 16777216) % 256) + char(floor(nLength / 65536) % 256) + char(floor(nLength / 256) % 256) + char(nLength % 256)

func bytesLength cBytes
	return ascii(substr(cBytes,1,1)) * 16777216 + ascii(substr(cBytes,2,1)) * 65536 + ascii(substr(cBytes,3,1)) * 256 + ascii(substr(cBytes,4,1))

# one message: the length, then the bytes. Two writes (a real program may write both in one buffer).
func writeMessage oStream,cMessage
	oStream.Write(lengthBytes(len(cMessage)),0,4)
	if len(cMessage) > 0
		oStream.Write(cMessage,0,len(cMessage))
	ok

# Read EXACTLY nCount bytes. A single Read may give fewer bytes than were asked for (the rest has not arrived yet), so the program reads
# again, into the next part of the same buffer, until all the bytes are there. Read gives 0 when the other side has closed the connection.
# The answer is [the bytes, the number of Read calls].
func readExact oStream,nCount
	if nCount = 0
		return [ "", 0 ]
	ok
	oBuffer = dnBuffer(nCount)
	nGot = 0
	nCalls = 0
	while nGot < nCount
		nRead = oStream.Read(oBuffer,nGot,nCount - nGot)
		nCalls++
		if nRead = 0
			raise("the connection was closed in the middle of a message")
		ok
		nGot += nRead
	end
	return [ dnBufferBytes(oBuffer,nCount), nCalls ]

# One message: read the four bytes of the length, check it against the maximum, then read the message. The answer is [the message, the
# number of Read calls: it depends on how the bytes arrived, so the program does not print it), or ["(refused: ...)", 0] for a length over the maximum.
func readMessage oStream,nMaximum
	aHeader = readExact(oStream,4)
	nLength = bytesLength(aHeader[1])
	if nLength > nMaximum
		return [ "(refused: " + nLength + " bytes is more than " + nMaximum + ")", 0 ]
	ok
	aBody = readExact(oStream,nLength)
	return [ aBody[1], aHeader[2] + aBody[2] ]

func hexText cBytes
	cText = ""
	for i = 1 to len(cBytes)
		cText += right("0" + upper(hex(ascii(substr(cBytes,i,1)))),2) + " "
	next
	return trim(cText)

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"

func padLeft cText,nWidth
	return copy(" ",nWidth - len(cText)) + cText
