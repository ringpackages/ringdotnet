# sockets - a TCP server and client in one program
load "dotnet.ring"
using {
	"System.IO"
	"System.Net"
	"System.Net.Sockets"
}

func main
	# STEP 1. The server: a listener waits for connections on a port of this computer.
	oListener = new TcpListener(new IPAddress().Loopback,0)        # port 0: any free port
	oListener.Start(NULL)
	nPort = oListener.LocalEndpoint.Port
	? "STEP 1: the server listens on 127.0.0.1, port is chosen: " + (nPort > 0)

	# STEP 2. The client connects. The connection is accepted by the operating system at once.
	oClient = new TcpClient()
	oClient.Connect([ :hostname = "127.0.0.1", :port = nPort ])
	? "STEP 2: the client is connected: " + oClient.Connected

	# STEP 3. The server accepts the waiting connection. Each side gets a stream to read and write.
	oAccepted = oListener.AcceptTcpClient()
	oServerStream = oAccepted.GetStream()
	oClientStream = oClient.GetStream()
	oServerReader = new StreamReader(oServerStream)
	oServerWriter = new StreamWriter(oServerStream)
	oServerWriter.AutoFlush = True
	oClientReader = new StreamReader(oClientStream)
	oClientWriter = new StreamWriter(oClientStream)
	oClientWriter.AutoFlush = True              # send every line at once
	? "STEP 3: the server accepted the connection"

	# STEP 4. A conversation: the client sends a line, the server answers with the same line in upper case
	? nl + "STEP 4: three messages"
	for cMessage in ["hello","how are you","bye"]
		oClientWriter.WriteLine(cMessage)               # client -> server
		cReceived = oServerReader.ReadLine()
		oServerWriter.WriteLine("echo: " + upper(cReceived))   # server -> client
		? "   sent '" + cMessage + "', answer '" + oClientReader.ReadLine() + "'"
	next

	# STEP 5. Close everything: streams, then the connections, then the listener
	oClient.Close()
	oAccepted.Close()
	oListener.Stop()
	? nl + "STEP 5: closed"

	# Real programs run the server and the clients in different programs (or different computers).
	# Then the server loops: while true, accept a client, read, answer. Ring code runs on one thread, so a server that
	# talks to many clients at once checks oListener.Pending() and polls the clients one after another.
