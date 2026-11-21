# Operators and conversions of .NET types: + - * / = < ... call the op_ methods (or Equals / CompareTo), convertTo is a cast
load "dotnet.ring"
dnImport("System")
dnImport("System.Numerics")

oOneHour = new TimeSpan().FromHours(1)
oHalfHour = new TimeSpan().FromMinutes(30)
oSum = oOneHour + oHalfHour
dnAssert("TimeSpan + TimeSpan",oSum.TotalMinutes,90)
dnAssert("TimeSpan - TimeSpan",(oOneHour - oHalfHour).TotalMinutes,30)
dnAssert("TimeSpan > TimeSpan",oOneHour > oHalfHour,1)
dnAssert("TimeSpan < TimeSpan",oOneHour < oHalfHour,0)
dnAssert("TimeSpan = TimeSpan",oOneHour = new TimeSpan().FromMinutes(60),1)
dnAssert("TimeSpan != TimeSpan",oOneHour != oHalfHour,1)
dnAssert("TimeSpan * number",(oHalfHour * 4).TotalMinutes,120)
dnAssert("TimeSpan / number",(oOneHour / 2).TotalMinutes,30)
dnAssert("negative",(-oOneHour).TotalMinutes,-60)

oDate = dnNew("System.DateTime",[ :year = 2024, :month = 5, :day = 17 ])
oLater = oDate + oOneHour
dnAssert("DateTime + TimeSpan",oLater.Hour,1)
dnAssert("DateTime - DateTime",(oLater - oDate).TotalMinutes,60)
dnAssert("DateTime < DateTime",oDate < oLater,1)

# a type with Equals and CompareTo only
oGuid = new Guid().NewGuid()
dnAssert("Guid = itself",oGuid = oGuid,1)
dnAssert("Guid != another",oGuid != new Guid().NewGuid(),1)

# the object comes second: the number is converted
oBig = new BigInteger().Parse("100000000000000000000")
dnAssert("BigInteger + number",(oBig + 1).ToString(),"100000000000000000001")
dnAssert("number + BigInteger",(1 + oBig).ToString(),"100000000000000000001")
dnAssert("number < BigInteger",5 < oBig,1)

# conversions: op_Explicit / op_Implicit
dnAssert("BigInteger to Int64",new BigInteger().Parse("42").convertTo("System.Int64"),42)
dnAssert("BigInteger to Double",new BigInteger().Parse("42").convertTo("System.Double"),42)

try
	oOneHour + "text"
	dnAssert("an operator that does not fit raises an error",1,0)
catch
	dnAssert("an operator that does not fit raises an error",substr(cCatchError,"No operator") > 0,1)
done

dnTestSummary()
