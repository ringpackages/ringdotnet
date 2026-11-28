# MySqlConnector: the connection string builder, a connection, a command and its parameters, without a server (a connection to a port that nobody listens to fails)
load "pkg.ring"
pkgUse("mysqlconnector",[["MySqlConnector","2.4.0"]],[["MySqlConnector.dll",["MySqlConnector"]]])
pkgImport("mysqlconnector","MySqlConnector.dll","MySqlConnector")

oBuilder = new MySqlConnectionStringBuilder()
oBuilder.Server = "db.example.com"
oBuilder.Port = 3307
oBuilder.UserID = "ring"
oBuilder.Password = "secret"
oBuilder.Database = "sales"
oBuilder.Pooling = False
oBuilder.ConnectionTimeout = 2
dnAssert("the server",oBuilder.Server,"db.example.com")
dnAssert("the port",oBuilder.Port,3307)
dnAssert("the user",oBuilder.UserID,"ring")
dnAssert("pooling is off",oBuilder.Pooling,False)
cText = oBuilder.ConnectionString
dnAssert("the text has the server",substr(lower(cText),"server=db.example.com") > 0,True)
dnAssert("the text has the database",substr(lower(cText),"database=sales") > 0,True)

# the builder reads a connection string too
oRead = new MySqlConnectionStringBuilder()
oRead.ConnectionString = "Server=localhost;Port=3306;User ID=root;Database=test;Allow User Variables=true;Default Command Timeout=45"
dnAssert("read: the server",oRead.Server,"localhost")
dnAssert("read: the database",oRead.Database,"test")
dnAssert("read: user variables",oRead.AllowUserVariables,True)
dnAssert("read: the command timeout",oRead.DefaultCommandTimeout,45)

# a connection object that is not open
oConnection = (new MySqlConnection).@New(cText)
dnAssert("a new connection: the database",oConnection.Database,"sales")
dnAssert("a new connection: the data source",oConnection.DataSource,"db.example.com")
dnAssert("a new connection is closed",oConnection.State,"Closed")

# a command and its parameters
oCommand = oConnection.CreateCommand()
oCommand.CommandText = "SELECT * FROM orders WHERE customer = @customer AND total > @total"
oCommand.CommandTimeout = 15
oParameters = oCommand.Parameters
oParameters.AddWithValue("@customer","Ann")
oParameters.AddWithValue("@total",100)
dnAssert("the command text",left(oCommand.CommandText,13),"SELECT * FROM")
dnAssert("the command timeout",oCommand.CommandTimeout,15)
dnAssert("two parameters",oParameters.Count,2)
dnAssert("a parameter is there",oParameters.Contains("@customer"),True)
dnAssert("a parameter that is not there",oParameters.Contains("@other"),False)
oFirst = oParameters.Item("@customer")
dnAssert("a parameter value",oFirst.Value,"Ann")
oParameter = new MySqlParameter()
oParameter.ParameterName = "@size"
oParameter.Value = 12
dnAssert("a new parameter: the name",oParameter.ParameterName,"@size")
dnAssert("a new parameter: the value",oParameter.Value,12)

# there is no server
oBad = (new MySqlConnection).@New("Server=127.0.0.1;Port=1;ConnectionTimeout=2;Pooling=false")
lError = 0
try
	oBad.Open()
catch
	lError = 1
done
dnAssert("a connection to nobody raises an error",lError,1)

dnTestSummary()
