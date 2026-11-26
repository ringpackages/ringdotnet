# UDP - datagrams between two sockets of this computer, Receive with a time limit, broadcast-style replies and lost data
load "dotnet.ring"

using {
	"System"
	"System.Net"
	"System.Net.Sockets"
	"System.Text"
}

func main

	oUtf8 = new UTF8Encoding()
	oLoop = new IPAddress().Loopback

	# 1. UDP sends separate messages (datagrams) without a connection: no Accept, no stream. A socket that listens binds to a port
	#    (0 = the system chooses a free one); LocalEndPoint tells which.
	oServer = new UdpClient().@New([ :port = 0 ])
	nPort = oServer.Client.LocalEndPoint.Port
	? "1. the server socket is bound to a port: " + (nPort > 0)

	# 2. The client sends three datagrams. Each Send is one message, and each Receive on the other side returns ONE message, not a
	#    part of a stream (TCP has no such borders).
	oClient = new UdpClient()
	for cText in ["one","two and more","three"]
		aBytes = oUtf8.GetBytes(cText)
		oClient.Send([ :dgram = aBytes, :bytes = len(aBytes), :hostname = "127.0.0.1", :port = nPort ])
	next
	? nl + "2. three datagrams sent; the server has data waiting: " + oServer.Available
	for i = 1 to 3
		oRemote = new IPEndPoint(oLoop,0)
		aGot = oServer.Receive(oRemote)
		cData = aGot[1]
		? "   datagram " + i + ": '" + oUtf8.GetString(cData) + "' (" + len(cData) + " bytes)"
	next

	# 3. A reply goes to the address of the sender. ReceiveAsync gives a result with the data (Buffer) and the sender (RemoteEndPoint).
	oClient.Send([ :dgram = oUtf8.GetBytes("ping"), :bytes = 4, :hostname = "127.0.0.1", :port = nPort ])
	oTask = oServer.ReceiveAsync(NULL)
	oTask.Wait(NULL)
	oResult = oTask.Result
	? nl + "3. the server got '" + oUtf8.GetString(oResult.Buffer) + "' from the port of the client socket: " + (oResult.RemoteEndPoint.Port > 0)
	cAnswer = oUtf8.GetBytes("pong")
	oServer.Send([ :dgram = cAnswer, :bytes = len(cAnswer), :endPoint = oResult.RemoteEndPoint ])
	oTask2 = oClient.ReceiveAsync(NULL)
	oTask2.Wait(NULL)
	? "   the client got '" + oUtf8.GetString(oTask2.Result.Buffer) + "'"

	# 4. UDP does not promise delivery. Nothing is waiting now, so a Receive with a time limit ends without data:
	#    ReceiveAsync + Wait(ms) answers false when nothing arrived.
	oTask3 = oServer.ReceiveAsync(NULL)
	lGot = oTask3.Wait(300)
	? nl + "4. waited 300 ms with no sender: a datagram arrived = " + lGot

	# 5. A datagram sent to a port where nobody listens is lost without an error on the sender's side
	oClient.Send([ :dgram = oUtf8.GetBytes("anyone?"), :bytes = 7, :hostname = "127.0.0.1", :port = 9 ])
	? nl + "5. sent to port 9 where nobody listens: no error, the data is just gone"
	oServer.Close()
	oClient.Close()
