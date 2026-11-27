# FluentDateTime: date and time helpers as extension methods (end of month, business days, next weekday, set the time) of DateTime, and the ones of int
load "pkg.ring"
pkgUse("fluentdatetime",[["FluentDateTime","3.0.0"]],[["FluentDateTime.dll",["FluentDate","FluentDateTime","FluentDateTimeOffset"]]])
pkgImport("fluentdatetime","FluentDateTime.dll","FluentDate")
pkgImport("fluentdatetime","FluentDateTime.dll","FluentDateTime")
pkgImport("fluentdatetime","FluentDateTime.dll","FluentDateTimeOffset")

using {
	"System"
}

oDate = new DateTime(2024,2,10).AddHours(13).AddMinutes(45).AddSeconds(30)          # a Saturday
dnAssert("the day of the week",oDate.DayOfWeek,"Saturday")

# DateTime is a class of the library, not of this package: the extension methods of the package are called with callMethod
dnAssert("the beginning of the day",textOf(oDate,"BeginningOfDay",[],"yyyy-MM-dd HH:mm:ss"),"2024-02-10 00:00:00")
dnAssert("midnight",textOf(oDate,"Midnight",[],"HH:mm"),"00:00")
dnAssert("noon",textOf(oDate,"Noon",[],"HH:mm"),"12:00")
dnAssert("the first day of the month",textOf(oDate,"FirstDayOfMonth",[],"yyyy-MM-dd"),"2024-02-01")
dnAssert("the last day of the month (a leap year)",textOf(oDate,"LastDayOfMonth",[],"yyyy-MM-dd"),"2024-02-29")
dnAssert("the first day of the quarter",textOf(oDate,"FirstDayOfQuarter",[],"yyyy-MM-dd"),"2024-01-01")
dnAssert("the next day",textOf(oDate,"NextDay",[],"yyyy-MM-dd"),"2024-02-11")
dnAssert("the previous year",textOf(oDate,"PreviousYear",[],"yyyy-MM-dd"),"2023-02-10")
dnAssert("a week after",textOf(oDate,"WeekAfter",[],"yyyy-MM-dd"),"2024-02-17")
oNext = oDate.callMethod("NextDay",[])
dnAssert("is before",oDate.callMethod("IsBefore",[oNext]),1)
dnAssert("is after",oDate.callMethod("IsAfter",[oNext]),0)

# business days skip the weekend: the Saturday + 3 business days is the Wednesday
dnAssert("business days",textOf(oDate,"AddBusinessDays",[3],"yyyy-MM-dd"),"2024-02-14")
dnAssert("business days back",textOf(oDate,"SubtractBusinessDays",[1],"yyyy-MM-dd"),"2024-02-09")

# a method with several overloads: the time can be set in steps
dnAssert("set the hour",textOf(oDate,"SetHour",[8],"HH:mm:ss"),"08:45:30")
dnAssert("set hour and minute (the seconds stay)",textOf(oDate,"SetTime",[6,15],"HH:mm:ss"),"06:15:30")
dnAssert("set the month",textOf(oDate,"SetMonth",[7],"yyyy-MM-dd"),"2024-07-10")

# the extensions of int are in a static class of the package: a day of a month
oInts = new IntExtensions()
oMarch = oInts.Mar(2025,8)
dnAssert("a date from numbers",textOfObject(oMarch.AtLocal([ :hour = 0 ]),"yyyy-MM-dd"),"2025-03-08")
oChristmas = oInts.Dec(2025,25)
dnAssert("a time on that date",textOfObject(oChristmas.AtLocal([ :hour = 18, :minute = 30 ]),"yyyy-MM-dd HH:mm"),"2025-12-25 18:30")


dnTestSummary()

# the text of the DateTime that an extension method gives (the result is held in a variable before it is used)
func textOf oStart,cMethod,aArguments,cFormat

	oResult = oStart.callMethod(cMethod,aArguments)
	return oResult.callMethod("ToString",[cFormat])

func textOfObject oValue,cFormat

	return oValue.callMethod("ToString",[cFormat])
