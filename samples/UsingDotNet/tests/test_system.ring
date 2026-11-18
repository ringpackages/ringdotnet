# Batch: namespace System (core types)
load "dotnet.ring"
dnImport("System")

oMath = new Math()
dnAssert("Math.Max",oMath.Max(3,9),9)
dnAssert("Math.Pow",oMath.Pow(2,10),1024)
dnAssert("Math.Abs",oMath.Abs(-5),5)
dnAssert("Math.PI",oMath.PI,3.14159265358979)
dnAssert("Math.Round",oMath.Round([ :value = 2.567, :digits = 2 ]),2.57)

oConvert = new Convert()
dnAssert("Convert.ToInt32",oConvert.ToInt32("42"),42)
dnAssert("Convert.ToBase64String",oConvert.ToBase64String("abc"),"YWJj")
dnAssert("Convert.FromBase64String",oConvert.FromBase64String("YWJj"),"abc")
dnAssert("Convert.ToString(255,16)",oConvert.Format([ :value = 255, :toBase = 16 ]),"ff")

oStr = new String()
dnAssert("String.Join",oStr.Join([ :separator = ",", :value = ["a","b","c"] ]),"a,b,c")
dnAssert("String.IsNullOrEmpty",oStr.IsNullOrEmpty(""),1)
dnAssert("String.Concat",oStr.Concat([ :str0 = "ab", :str1 = "cd" ]),"abcd")
dnAssert("String.Format",oStr.Format([ :format = "{0}-{1}", :args = ["x",7] ]),"x-7")

oInt = new Int32()
dnAssert("Int32.MaxValue",oInt.MaxValue,2147483647)
dnAssert("Int32.Parse",oInt.Parse("12"),12)
aTry = oInt.TryParse("zz")
dnAssert("Int32.TryParse fails",aTry[1],0)

oChar = new Char()
dnAssert("Char.IsDigit",oChar.IsDigit("5"),1)
dnAssert("Char.ToUpper",oChar.ToUpper("a"),"A")
dnAssert("Double.IsNaN",new Double().IsNaN(0),0)

oGuid = new Guid()
dnAssert("Guid.NewGuid length",len(oGuid.NewGuid().ToString()),36)
dnAssert("Guid.Parse",oGuid.Parse("11111111-2222-3333-4444-555555555555").ToString(),"11111111-2222-3333-4444-555555555555")

oUri = new Uri("https://example.com:8080/a/b?x=1")
dnAssert("Uri.Host",oUri.Host,"example.com")
dnAssert("Uri.Port",oUri.Port,8080)
dnAssert("Uri.AbsolutePath",oUri.AbsolutePath,"/a/b")
dnAssert("Uri.Query",oUri.Query,"?x=1")

oVer = new Version("1.2.3")
dnAssert("Version.Minor",oVer.Minor,2)
dnAssert("Version.ToString",oVer.ToString(),"1.2.3")

oSpan = new TimeSpan().FromMinutes(90)
dnAssert("TimeSpan.TotalHours",oSpan.TotalHours,1.5)
dnAssert("TimeSpan.ToString",oSpan.ToString(),"01:30:00")

oDate = new DateTime(2024,1,31)
dnAssert("DateTime.AddMonths",oDate.AddMonths(1).Day,29)
dnAssert("DateTime.DaysInMonth",oDate.DaysInMonth(2023,2),28)
dnAssert("DateTime.IsLeapYear",oDate.IsLeapYear(2024),1)
dnAssert("DateTime.ToString",oDate.Format("yyyy-MM-dd"),"2024-01-31")
dnAssert("DateTime.Kind enum",oDate.Kind,"Unspecified")
dnAssert("DateOnly",new DateOnly(2020,5,17).DayOfWeek,"Sunday")

oEnv = new Environment()
dnAssert("Environment.ProcessorCount",oEnv.ProcessorCount > 0,1)
dnAssert("Environment.MachineName",len(oEnv.MachineName) > 0,1)
dnAssert("Environment.NewLine",oEnv.NewLine,windowsnl())

dnAssert("Random seed",new Random(1).Next_([ :minValue = 5, :maxValue = 6 ]),5)
dnAssert("TimeZoneInfo.Utc",new TimeZoneInfo().Utc.Id,"UTC")
dnAssert("GC memory",new GC().GetTotalMemory(0) > 0,1)
dnAssert("Decimal.Parse",new Decimal().Parse("12.5"),12.5)

nFail = dnTestSummary()
