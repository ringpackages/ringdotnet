# Dapper with Microsoft.Data.Sqlite: an in-memory database, queries with parameters, rows as dictionaries
load "pkg.ring"
aPkgExtra = ["SQLitePCLRaw.core.dll","SQLitePCLRaw.provider.e_sqlite3.dll","SQLitePCLRaw.batteries_v2.dll"]
pkgUse("dapper",[["Dapper","2.1.100"],["Microsoft.Data.Sqlite","9.0.23"]],[["Microsoft.Data.Sqlite.dll",["Microsoft.Data.Sqlite"]],["Dapper.dll",["Dapper"]]])
pkgImport("dapper","Microsoft.Data.Sqlite.dll","Microsoft.Data.Sqlite")
pkgImport("dapper","Dapper.dll","Dapper")
dnRequest("call",[dnType("SQLitePCL.Batteries_V2"),"Init"])

oConn = new SqliteConnection().@New([ :connectionString = "Data Source=:memory:" ])
oConn.Open()
dnStatic("Dapper.SqlMapper","Execute",[oConn,"create table person(id integer primary key, name text, age integer)"])
dnAssert("rows inserted",dnStatic("Dapper.SqlMapper","Execute",[oConn,"insert into person(name,age) values ('Ann',31),('Bo',25),('Cy',40)"]),3)

aRows = dnStatic("Dapper.SqlMapper","Query",[oConn,"select * from person where age > 26 order by age"]).toList()
dnAssert("two rows are older",len(aRows),2)
dnAssert("a column of a row",aRows[1].Item("name"),"Ann")
dnAssert("a number column of a row",aRows[2].Item("age"),40)
dnAssert("a scalar",dnStatic("Dapper.SqlMapper","ExecuteScalar",[oConn,"select count(*) from person"]),3)

oParams = new DynamicParameters()
oParams.Add([ :name = "minAge", :value = 30 ])
aOlder = dnStatic("Dapper.SqlMapper","Query",[oConn,"select name from person where age >= @minAge",oParams]).toList()
dnAssert("a query with a parameter",len(aOlder),2)
dnAssert("the first or default row",dnStatic("Dapper.SqlMapper","QueryFirstOrDefault",[oConn,"select name,age from person where id = 2"]).Item("name"),"Bo")
oNone = dnStatic("Dapper.SqlMapper","QueryFirstOrDefault",[oConn,"select name from person where id = 99"])
dnAssert("no row is null",oNone.isNull(),1)

oConn.Close()
dnTestSummary()
