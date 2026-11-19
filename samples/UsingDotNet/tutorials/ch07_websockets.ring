# WebSockets - a connection that stays open: a client and a server in one program, text and binary messages, long messages in parts, closing
load "dotnet.ring"
using {
	"System"
	"System.Net"
	"System.Net.Sockets"
	"System.Net.WebSockets"
	"System.Threading"
}

oToken = ""                       # a token that cancels everything after 20 seconds, so that a mistake cannot hang the program

func main
	# HTTP is a question and an answer. A WEBSOCKET is a connection that stays open after the first HTTP request: both sides can send a
	# message whenever they like, which is what a chat, a live price list or a game needs. The first request asks to "upgrade" the
	# connection, and then the two sides send MESSAGES (text or binary) until one of them closes it.
	oSource = new CancellationTokenSource().New_([ :millisecondsDelay = 20000 ])
	oToken = oSource.Token

	# 1. The server: an HttpListener that accepts the upgrade. The port is a free one, found by asking the system for port 0.
	oProbe = new TcpListener(new IPAddress().Loopback,0)
	oProbe.Start(NULL)
	nPort = oProbe.LocalEndpoint.Port
	oProbe.Stop()
	oListener = new HttpListener()
	oListener.Prefixes.Add("http://localhost:" + nPort + "/")
	oListener.Start()
	? "1. the server listens"

	# 2. The client connects. Everything is done with tasks, and the program waits for each task where it must: connecting and accepting
	#    are two sides of one handshake, so both tasks are started first and then both are waited for.
	oClient = new ClientWebSocket()
	oConnect = oClient.ConnectAsync([ :uri = new Uri("ws://localhost:" + nPort + "/chat"), :cancellationToken = oToken ])
	oContextTask = oListener.GetContextAsync()
	oContextTask.Wait(NULL)
	oContext = oContextTask.getProp("Result")
	? nl + "2. a request arrived for " + oContext.Request.Url.AbsolutePath + ", it is a WebSocket request: " + yesNo(oContext.Request.IsWebSocketRequest)
	oAccept = oContext.AcceptWebSocketAsync(dnNull())                  # (no sub protocol)
	oAccept.Wait(NULL)
	oConnect.Wait(NULL)
	oServer = oAccept.getProp("Result").WebSocket
	? "   client state: " + oClient.State + ", server state: " + oServer.State

	# 3. Text messages. The client sends, the server receives and answers, the client receives the answer.
	? nl + "3. text messages:"
	for cText in [ "hello", "how are you?" ]
		sendText(oClient,cText,True)
		cGot = receiveText(oServer)
		? "   the server received '" + cGot + "'"
		sendText(oServer,upper(cGot),False)
		? "   the client received '" + receiveText(oClient) + "'"
	next

	# 4. A binary message: all 256 byte values (a Ring text can hold any byte)
	cBytes = ""
	for i = 0 to 255
		cBytes += char(i)
	next
	send(oClient,cBytes,"Binary",True)
	aGot = receive(oServer,1024)
	? nl + "4. a binary message of " + len(cBytes) + " bytes: the server received " + len(aGot[1]) + " bytes, of type " + aGot[2] + ", the same: " + yesNo(aGot[1] = cBytes)

	# 5. A long message comes in PARTS. The receiver has a buffer of 8 bytes, so a message of 20 bytes needs three calls of Receive; the
	#    result says EndOfMessage when the message is complete.
	sendText(oClient,"0123456789ABCDEFGHIJ",True)
	? nl + "5. a message of 20 bytes, a buffer of 8 bytes:"
	cWhole = ""
	nParts = 0
	while True
		aPart = receive(oServer,8)
		cWhole += aPart[1]
		nParts++
		? "   part " + nParts + ": '" + aPart[1] + "', last part: " + yesNo(aPart[3])
		if aPart[3]
			exit
		ok
	end
	? "   the whole message: " + cWhole

	# 6. Closing. One side starts the close handshake (CloseOutput says "I send no more"), the other receives the close message and
	#    answers with its own, and then both are Closed.
	oClient.CloseOutputAsync("NormalClosure","bye",oToken).Wait(NULL)
	aClose = receive(oServer,64)
	? nl + "6. the server received a message of type " + aClose[2] + ", status " + oServer.CloseStatus + ", description '" + oServer.CloseStatusDescription + "'"
	oServer.CloseAsync("NormalClosure","bye too",oToken).Wait(NULL)
	receive(oClient,64)
	? "   client state: " + oClient.State + ", server state: " + oServer.State

	oListener.Stop()

# send a text or binary message in one piece: the text is turned into an ArraySegment of bytes (the part of an array that is sent). The
# class ClientWebSocket has SendAsync with four values; the object that the server got is a WebSocket, where SendAsync has more forms and
# takes the values by name.
func send oSocket,cBytes,cType,lClient
	oSegment = dnNew("System.ArraySegment`1[[System.Byte]]",[ cBytes ])
	if lClient
		oSocket.SendAsync(oSegment,cType,True,oToken).Wait(NULL)
	else
		oSocket.SendAsync([ :buffer = oSegment, :messageType = cType, :endOfMessage = True, :cancellationToken = oToken ]).Wait(NULL)
	ok

func sendText oSocket,cText,lClient
	send(oSocket,cText,"Text",lClient)

# Receive into a buffer of nSize bytes. The buffer is a byte buffer (dnBuffer): a .NET byte[] that Ring holds. The ArraySegment is made
# on that array, .NET fills it, and the received bytes are the first Count bytes of the buffer. The answer is [the bytes, the type,
# EndOfMessage].
func receive oSocket,nSize
	oBuffer = dnBuffer(nSize)
	oSegment = dnNew("System.ArraySegment`1[[System.Byte]]",[ oBuffer ])
	oTask = oSocket.ReceiveAsync(oSegment,oToken)
	oTask.Wait(NULL)
	oResult = oTask.getProp("Result")
	return [ dnBufferBytes(oBuffer,oResult.Count), "" + oResult.MessageType, oResult.EndOfMessage ]

func receiveText oSocket
	return receive(oSocket,1024)[1]

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"
