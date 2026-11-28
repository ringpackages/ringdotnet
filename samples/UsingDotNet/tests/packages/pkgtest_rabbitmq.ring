# RabbitMQ.Client: the connection factory (defaults, settings, an AMQP address), end points, publication addresses and timestamps; no broker is used
load "pkg.ring"
pkgUse("rabbitmq",[["RabbitMQ.Client","6.8.1"]],[["RabbitMQ.Client.dll",["RabbitMQ.Client","RabbitMQ.Client.Events"]]])
pkgImport("rabbitmq","RabbitMQ.Client.dll","RabbitMQ.Client")
pkgImport("rabbitmq","RabbitMQ.Client.dll","RabbitMQ.Client.Events")
dnImport("System")

oFactory = new ConnectionFactory()
dnAssert("the default host",oFactory.HostName,"localhost")
dnAssert("the default port is not chosen yet",oFactory.Port,-1)
dnAssert("the default user",oFactory.UserName,"guest")
dnAssert("the default virtual host",oFactory.VirtualHost,"/")
dnAssert("recovery is on by default",oFactory.AutomaticRecoveryEnabled,True)

oFactory.HostName = "mq.example.com"
oFactory.Port = 5673
oFactory.UserName = "ring"
oFactory.Password = "secret"
oFactory.VirtualHost = "sales"
oFactory.ClientProvidedName = "ring client"
oFactory.AutomaticRecoveryEnabled = False
dnAssert("the host",oFactory.HostName,"mq.example.com")
dnAssert("the port",oFactory.Port,5673)
dnAssert("the user",oFactory.UserName,"ring")
dnAssert("the virtual host",oFactory.VirtualHost,"sales")
dnAssert("the client name",oFactory.ClientProvidedName,"ring client")
dnAssert("recovery is off",oFactory.AutomaticRecoveryEnabled,False)
dnAssert("the end point has the host",oFactory.Endpoint.HostName,"mq.example.com")

# an AMQP address sets all of it
oUri = new Uri("amqp://alice:pw@broker.local:5680/orders")
oFactory.Uri = oUri
dnAssert("the address: the host",oFactory.HostName,"broker.local")
dnAssert("the address: the port",oFactory.Port,5680)
dnAssert("the address: the user",oFactory.UserName,"alice")
dnAssert("the address: the virtual host",oFactory.VirtualHost,"orders")

# end points
oEndpoint = (new AmqpTcpEndpoint).Parse("rabbit.example.com:5671")
dnAssert("an end point: the host",oEndpoint.HostName,"rabbit.example.com")
dnAssert("an end point: the port",oEndpoint.Port,5671)
oMany = (new AmqpTcpEndpoint).ParseMultiple("one:5672,two:5673")
dnAssert("several end points",len(oMany.toList()),2)
dnAssert("the second end point",oMany.toList()[2].HostName,"two")

# a publication address: exchange type, exchange and routing key
oAddress = (new PublicationAddress).Parse("direct://amq.direct/orders.new")
dnAssert("the exchange type",oAddress.ExchangeType,"direct")
dnAssert("the exchange",oAddress.ExchangeName,"amq.direct")
dnAssert("the routing key",oAddress.RoutingKey,"orders.new")

# a timestamp is seconds since 1970
oTime = (new AmqpTimestamp).@New(1700000000)
dnAssert("a timestamp",oTime.UnixTime,1700000000)

# there is no broker
oBad = new ConnectionFactory()
oBad.HostName = "127.0.0.1"
oBad.Port = 1
oBad.RequestedConnectionTimeout = (new TimeSpan).FromSeconds(2)
lError = 0
try
	oBad.CreateConnection()
catch
	lError = 1
done
dnAssert("a connection to nobody raises an error",lError,1)

dnTestSummary()
