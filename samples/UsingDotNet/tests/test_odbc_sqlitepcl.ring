# Classes of System.Data.Odbc (ODBC drivers) and SQLitePCL (the native SQLite library of Microsoft.Data.Sqlite)
load "dotnet.ring"
dnUseData()

using {
	"System"
	"System.Data"
	"System.Data.Odbc"
	"SQLitePCL"
	"Microsoft.Data.Sqlite"
}

func main

	# ---- ODBC: the classes exist and work without a driver (a connection is opened only when a driver is installed)
	oConnection = (new OdbcConnection).@New("Driver={No such driver};Dbq=none.accdb;")
	dnAssert("the connection string is kept",oConnection.ConnectionString,"Driver={No such driver};Dbq=none.accdb;")
	dnAssert("a new connection is closed",oConnection.State,"Closed")
	oCommand = oConnection.CreateCommand()
	oCommand.CommandText = "SELECT * FROM t WHERE a = ?"
	oParameters = oCommand.Parameters
	oParameters.AddWithValue("p1",42)
	dnAssert("a parameter was added",oParameters.Count,1)
	lRefused = False
	try
		oConnection.Open()
	catch
		lRefused = True
	done
	dnAssert("a driver that does not exist is refused",lRefused,True)
	(new OdbcConnection).ReleaseObjectPool()

	# ---- SQLitePCL: the native library is started with Batteries_V2.Init, then Microsoft.Data.Sqlite works
	(new Batteries_V2).Init()
	oSqlite = (new SqliteConnection).@New("Data Source=:memory:")
	oSqlite.Open()
	oSelect = oSqlite.CreateCommand()
	oSelect.CommandText = "SELECT 40 + 2"
	dnAssert("SQLite answers",oSelect.ExecuteScalar(),42)
	oSqlite.Dispose()

	dnTestSummary()
