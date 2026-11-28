# StackExchange.Redis: the connection configuration (parsed from and written to the connection string), keys, values and channels; no server is used
load "pkg.ring"
pkgUse("redisconfig",[["StackExchange.Redis","2.8.16"]],[["StackExchange.Redis.dll",["StackExchange.Redis"]]])
pkgImport("redisconfig","StackExchange.Redis.dll","StackExchange.Redis")

oOptions = (new ConfigurationOptions).Parse("localhost:6380,password=secret,ssl=true,defaultDatabase=3,connectTimeout=2500,abortConnect=false,name=ringclient")
dnAssert("the end point list",oOptions.EndPoints.Count,1)
dnAssert("the host and port",oOptions.EndPoints.toList()[1].ToString(),"Unspecified/localhost:6380")
dnAssert("the password",oOptions.Password,"secret")
dnAssert("ssl",oOptions.Ssl,True)
dnAssert("the database",oOptions.DefaultDatabase,3)
dnAssert("the connect timeout",oOptions.ConnectTimeout,2500)
dnAssert("abort on connect fail",oOptions.AbortOnConnectFail,False)
dnAssert("the client name",oOptions.ClientName,"ringclient")

# written back to a connection string, then parsed again
cText = oOptions.ToString()
dnAssert("the text has the host",substr(cText,"localhost:6380") > 0,True)
oAgain = (new ConfigurationOptions).Parse(cText)
dnAssert("the parsed text keeps the database",oAgain.DefaultDatabase,3)
dnAssert("the parsed text keeps the name",oAgain.ClientName,"ringclient")

# options set in code
oCode = new ConfigurationOptions()
oCode.EndPoints.Add("redis.example.com:6379")
oCode.ClientName = "made in code"
oCode.ConnectRetry = 5
oCode.AllowAdmin = True
dnAssert("a code option: retries",oCode.ConnectRetry,5)
dnAssert("a code option: admin",oCode.AllowAdmin,True)
dnAssert("a code option: an end point",oCode.EndPoints.Count,1)
oClone = oCode.Clone()
oClone.ConnectRetry = 9
dnAssert("a clone is a separate object",oCode.ConnectRetry,5)
dnAssert("the clone has the change",oClone.ConnectRetry,9)

# keys, values and channels
oKey = (new RedisKey).@New("user:1")
dnAssert("a key",oKey.ToString(),"user:1")
dnAssert("a key with a prefix",oKey.Prepend("app:").ToString(),"app:user:1")
oValue = (new RedisValue).@New("hello")
dnAssert("a value",oValue.ToString(),"hello")
dnAssert("a value has a length",oValue.Length(),5)
dnAssert("a value is not null",oValue.getIsNull(),False)
dnAssert("a value starts with",oValue.StartsWith("hel"),True)
dnAssert("the null value",oValue.getNull().getIsNull(),True)
oChannel = (new RedisChannel).Literal("news")
dnAssert("a literal channel",oChannel.ToString(),"news")
dnAssert("a literal channel is not a pattern",oChannel.IsPattern,False)
dnAssert("a pattern channel",(new RedisChannel).Pattern("news.*").IsPattern,True)

# a bad connection string is an error
lError = 0
try
	(new ConfigurationOptions).Parse("localhost:6379,connectTimeout=notanumber")
catch
	lError = 1
done
dnAssert("a bad option raises an error",lError,1)

dnTestSummary()
