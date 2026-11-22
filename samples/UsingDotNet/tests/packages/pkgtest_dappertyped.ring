# Dapper with classes: Query<T> maps the rows of a SQLite table to objects of a .NET class (Person of a helper project), and an object is the parameters of a command
load "pkg.ring"
aPkgExtra = ["SQLitePCLRaw.core.dll","SQLitePCLRaw.provider.e_sqlite3.dll","SQLitePCLRaw.batteries_v2.dll"]
pkgUseProject("dappertyped","helpers/PkgHelpers",[["PkgHelpers.dll",["PkgHelpers"]],["Microsoft.Data.Sqlite.dll",["Microsoft.Data.Sqlite"]],["Dapper.dll",["Dapper"]]])
pkgImport("dappertyped","PkgHelpers.dll","PkgHelpers")
pkgImport("dappertyped","Microsoft.Data.Sqlite.dll","Microsoft.Data.Sqlite")
pkgImport("dappertyped","Dapper.dll","Dapper")
dnRequest("call",[dnType("SQLitePCL.Batteries_V2"),"Init"])

oConn = new SqliteConnection().@New([ :connectionString = "Data Source=:memory:" ])
oConn.Open()
oMapper = dnType("Dapper.SqlMapper")
oMapper.callMethod("Execute",[oConn,"create table People(FirstName text, LastName text, Age integer, Email text)"])

# an object is the parameters: its properties are the parameter names (@FirstName ...)
for aData in [ ["Ann","Lee",31,"ann@example.org"], ["Bo","Kim",25,""], ["Cy","Park",40,"cy@example.org"] ]
	oPerson = new Person()
	oPerson.FirstName = aData[1]
	oPerson.LastName = aData[2]
	oPerson.Age = aData[3]
	oPerson.Email = aData[4]
	oMapper.callMethod("Execute",[oConn,"insert into People values (@FirstName, @LastName, @Age, @Email)",oPerson])
next
dnAssert("three rows were inserted",oMapper.callMethod("ExecuteScalar",[oConn,"select count(*) from People"]),3)

# Query<Person>: the rows become objects of the class, the columns are the properties
aPeople = dnRequest("callnamed",[oMapper,"Query",[ ["typeArguments",["PkgHelpers.Person"]], ["cnn",oConn], ["sql","select * from People order by Age"] ]]).toList()
dnAssert("three people",len(aPeople),3)
dnAssert("the class of a row",classname(aPeople[1]),"person")
dnAssert("a text column",aPeople[1].FirstName,"Bo")
dnAssert("a number column",aPeople[3].Age,40)
dnAssert("the last name",aPeople[2].LastName,"Lee")

# a parameter object for a query, and QueryFirstOrDefault<Person>
oFilter = new Person()
oFilter.Age = 30
aOlder = dnRequest("callnamed",[oMapper,"Query",[ ["typeArguments",["PkgHelpers.Person"]], ["cnn",oConn], ["sql","select * from People where Age >= @Age order by Age"], ["param",oFilter] ]]).toList()
dnAssert("two people are 30 or more",len(aOlder),2)
oOne = dnRequest("callnamed",[oMapper,"QueryFirstOrDefault",[ ["typeArguments",["PkgHelpers.Person"]], ["cnn",oConn], ["sql","select * from People where FirstName = 'Cy'"] ]])
dnAssert("a single object",oOne.Email,"cy@example.org")
oNone = dnRequest("callnamed",[oMapper,"QueryFirstOrDefault",[ ["typeArguments",["PkgHelpers.Person"]], ["cnn",oConn], ["sql","select * from People where FirstName = 'Nobody'"] ]])
dnAssert("no row is null",oNone.isNull(),1)

# a column that has no property is ignored, and a scalar can be asked as a typed value
dnAssert("a typed scalar",dnRequest("callnamed",[oMapper,"ExecuteScalar",[ ["typeArguments",["System.Int32"]], ["cnn",oConn], ["sql","select max(Age) from People"] ]]),40)

oConn.Close()
dnTestSummary()
