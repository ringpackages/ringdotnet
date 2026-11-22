# SqlKata: a query builder; the SQL text and its bindings for different database compilers
load "pkg.ring"
pkgUse("sqlkata",[["SqlKata","2.4.0"]],[["SqlKata.dll",["SqlKata","SqlKata.Compilers"]]])
pkgImport("sqlkata","SqlKata.dll","SqlKata")
pkgImport("sqlkata","SqlKata.dll","SqlKata.Compilers")

oQuery = new Query().@New("Users")
oQuery.Select(["Name","Age"])
oQuery.callMethod("Where",["Age",">",18])
oQuery.OrderBy("Name")
oQuery.Limit(10)

oSql = new SqlServerCompiler().Compile(oQuery)
dnAssert("SQL Server",oSql.Sql,"SELECT [Name], [Age] FROM [Users] WHERE [Age] > @p0 ORDER BY [Name] OFFSET @p1 ROWS FETCH NEXT @p2 ROWS ONLY")

oSqlite = new SqliteCompiler().Compile(oQuery)
dnAssert("SQLite",oSqlite.Sql,'SELECT "Name", "Age" FROM "Users" WHERE "Age" > @p0 ORDER BY "Name" LIMIT @p1')

oMy = new MySqlCompiler().Compile(oQuery)
dnAssert("MySQL",oMy.Sql,"SELECT `Name`, `Age` FROM `Users` WHERE `Age` > @p0 ORDER BY `Name` LIMIT @p1")

dnAssert("the bindings are the value and the limit",len(oSqlite.Bindings.toList()),2)
dnAssert("the binding value",oSqlite.Bindings.toList()[1],18)
dnAssert("the limit as a binding",oSqlite.Bindings.toList()[2],10)
dnAssert("the same with placeholders",substr(oSqlite.ToString(),"18") > 0,1)

oJoin = new Query().@New("Orders")
oJoin.callMethod("Join",["Users","Users.Id","Orders.UserId"])
oJoin.WhereIn("Orders.Status",["new","paid"])
dnAssert("a join and a list",substr(new SqliteCompiler().Compile(oJoin).Sql,'INNER JOIN "Users" ON "Users"."Id" = "Orders"."UserId"') > 0,1)

dnTestSummary()
