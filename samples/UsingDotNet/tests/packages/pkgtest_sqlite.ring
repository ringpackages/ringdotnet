# Microsoft.Data.Sqlite: ADO.NET objects (connection, command, parameters, reader, transaction); the types of values (a whole number is an integer, a fraction a real, text, a blob, null)
load "pkg.ring"
aPkgExtra = ["SQLitePCLRaw.core.dll","SQLitePCLRaw.provider.e_sqlite3.dll","SQLitePCLRaw.batteries_v2.dll"]
pkgUse("sqlite",[["Microsoft.Data.Sqlite","9.0.23"]],[["Microsoft.Data.Sqlite.dll",["Microsoft.Data.Sqlite"]]])
pkgImport("sqlite","Microsoft.Data.Sqlite.dll","Microsoft.Data.Sqlite")
dnRequest("call",[dnType("SQLitePCL.Batteries_V2"),"Init"])

oConn = new SqliteConnection().@New([ :connectionString = "Data Source=:memory:" ])
oConn.Open()
runSql("create table t(id integer primary key, n, label text, data blob)")

# parameters with values of Ring: a whole number is stored as an integer, a number with a fraction as a real
oInsert = oConn.CreateCommand()
oInsert.CommandText = "insert into t(n, label, data) values (@n, @label, @data)"
oInsert.Parameters.AddWithValue("@n",5)
oInsert.Parameters.AddWithValue("@label","five")
oInsert.Parameters.AddWithValue("@data","bytes" + char(0) + char(255))
dnAssert("one row inserted",oInsert.ExecuteNonQuery(),1)
oInsert2 = oConn.CreateCommand()
oInsert2.CommandText = "insert into t(n, label) values (@n, @label)"
oInsert2.Parameters.AddWithValue("@n",2.5)
oInsert2.Parameters.AddWithValue("@label",dnType("System.DBNull").getProp("Value"))          # a null column: DBNull.Value
oInsert2.ExecuteNonQuery()

# the storage class of the values, as SQLite says it
oSelect = oConn.CreateCommand()
oSelect.CommandText = "select typeof(n), typeof(label), typeof(data) from t order by id"
oReader = oSelect.ExecuteReader(NULL)
aTypes = []
while oReader.Read()
	add(aTypes,oReader.GetString(0) + "," + oReader.GetString(1) + "," + oReader.GetString(2))
end
oReader.Dispose()
dnAssert("a whole number is an integer, text is text, bytes are a blob",aTypes[1],"integer,text,blob")
dnAssert("a fraction is a real, null is null",aTypes[2],"real,null,null")

# read the values back
oValues = oConn.CreateCommand()
oValues.CommandText = "select n, label, data from t order by id"
oRead = oValues.ExecuteReader(NULL)
oRead.Read()
dnAssert("an integer column",oRead.GetInt32(0),5)
dnAssert("a text column",oRead.GetString(1),"five")
dnAssert("a blob column is a byte string (binary safe)",oRead.GetValue(2),"bytes" + char(0) + char(255))
dnAssert("the number of columns",oRead.FieldCount,3)
dnAssert("the name of a column",oRead.GetName(1),"label")
oRead.Read()
dnAssert("a real column",oRead.GetDouble(0),2.5)
dnAssert("a null column",oRead.IsDBNull(1),1)
dnAssert("there is no third row",oRead.Read(),0)
oRead.Dispose()

# a transaction: a rollback undoes the insert
oTransaction = oConn.BeginTransaction(NULL)
runSql("insert into t(n,label) values (99,'temporary')")
oTransaction.Rollback(NULL)
dnAssert("a rolled back insert is gone",scalar("select count(*) from t where n = 99"),0)
oCommit = oConn.BeginTransaction(NULL)
runSql("insert into t(n,label) values (77,'kept')")
oCommit.Commit()
dnAssert("a committed insert stays",scalar("select count(*) from t where n = 77"),1)

# an error of SQL is an error of Ring with the message of SQLite
try
	runSql("select from nothing")
	dnAssert("bad SQL is an error",1,0)
catch
	dnAssert("bad SQL is an error",substr(cCatchError,"SqliteException") > 0 or substr(cCatchError,"syntax error") > 0,1)
done

oConn.Close()
dnTestSummary()

func runSql cSql

	oCommand = oConn.CreateCommand()
	oCommand.CommandText = cSql
	return oCommand.ExecuteNonQuery()

func scalar cSql

	oCommand = oConn.CreateCommand()
	oCommand.CommandText = cSql
	return oCommand.ExecuteScalar()
