# Google.Protobuf: the well-known messages (Timestamp, Duration, Struct), binary serialization, JSON, ByteString, and a generic parser method
load "pkg.ring"
pkgUse("protobuf",[["Google.Protobuf","3.36.2"]],[["Google.Protobuf.dll",["Google.Protobuf","Google.Protobuf.WellKnownTypes"]]])
pkgImport("protobuf","Google.Protobuf.dll","Google.Protobuf")
pkgImport("protobuf","Google.Protobuf.dll","Google.Protobuf.WellKnownTypes")
dnImport("System")

# a message with fields
oStamp = new Timestamp()
oStamp.Seconds = 1700000000
oStamp.Nanos = 500
dnAssert("a field",oStamp.Seconds,1700000000)

# binary: to bytes (a Ring byte string) and back
cBytes = dnStatic("Google.Protobuf.MessageExtensions","ToByteArray",[oStamp])
dnAssert("the bytes of a message",len(cBytes) > 4,1)
oBack = oStamp.Parser.ParseFrom(cBytes)
dnAssert("a message read back, seconds",oBack.Seconds,1700000000)
dnAssert("a message read back, nanos",oBack.Nanos,500)
dnAssert("messages that have the same fields are equal",oBack.Equals(oStamp),1)
dnAssert("the size of a message",oStamp.CalculateSize(),len(cBytes))

# a Timestamp from and to a DateTime
oDate = dnNew("System.DateTime",[ :year = 2024, :month = 5, :day = 17, :hour = 8, :minute = 30, :second = 0, :kind = "Utc" ])
oFromDate = dnStatic("Google.Protobuf.WellKnownTypes.Timestamp","FromDateTime",[oDate])
dnAssert("a timestamp from a date",oFromDate.ToDateTime().Day,17)
dnAssert("the seconds of a date",oFromDate.Seconds,1715934600)

# a Duration
oDuration = dnStatic("Google.Protobuf.WellKnownTypes.Duration","FromTimeSpan",[new TimeSpan().FromSeconds(90)])
dnAssert("a duration in seconds",oDuration.Seconds,90)
dnAssert("a duration to a time span",oDuration.ToTimeSpan().TotalMinutes,1.5)

# JSON: the formatter, and the parser with the type argument (a generic method)
cJson = dnType("Google.Protobuf.JsonFormatter").getProp("Default").Format(oFromDate)
dnAssert("a timestamp as JSON",cJson,'"2024-05-17T08:30:00Z"')
oParser = dnType("Google.Protobuf.JsonParser").getProp("Default")
oStruct = oParser.callGeneric("Parse",["Google.Protobuf.WellKnownTypes.Struct"],['{"name":"Ring","n":3,"tags":["a","b"]}'])
dnAssert("a struct from JSON, a field",oStruct.Fields.Count,3)
dnAssert("a struct, a string value",oStruct.Fields.Item("name").StringValue,"Ring")
dnAssert("a struct, a number value",oStruct.Fields.Item("n").NumberValue,3)
dnAssert("a struct, a list value",oStruct.Fields.Item("tags").ListValue.Values.Count,2)

# ByteString
oBytes = dnStatic("Google.Protobuf.ByteString","CopyFromUtf8",["héllo"])
dnAssert("a ByteString has the bytes of the text",oBytes.Length,6)
dnAssert("a ByteString to a text",oBytes.ToStringUtf8(),"héllo")
dnAssert("a ByteString in Base64",dnStatic("Google.Protobuf.ByteString","CopyFrom",["abc"]).ToBase64(),"YWJj")

dnTestSummary()
