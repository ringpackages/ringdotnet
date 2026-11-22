# Cronos: cron expressions, the next time a schedule fires (a nullable DateTime), seconds, and bad expressions
load "pkg.ring"
pkgUse("cronos",[["Cronos","0.13.0"]],[["Cronos.dll",["Cronos"]]])
pkgImport("cronos","Cronos.dll","Cronos")
dnImport("System")

oFrom = dnNew("System.DateTime",[ :year = 2024, :month = 3, :day = 10, :hour = 10, :minute = 2, :second = 0, :kind = "Utc" ])
oEvery5 = dnStatic("Cronos.CronExpression","Parse",["*/5 * * * *"])
oNext = oEvery5.GetNextOccurrence(oFrom)
dnAssert("the next minute that is a multiple of five",oNext.Minute,5)
dnAssert("in the same hour",oNext.Hour,10)

oDaily = dnStatic("Cronos.CronExpression","Parse",["30 6 * * *"])
oNext = oDaily.GetNextOccurrence(oFrom)
dnAssert("a daily schedule: the next day",oNext.Day,11)
dnAssert("a daily schedule: the hour",oNext.Hour,6)
dnAssert("a daily schedule: the minute",oNext.Minute,30)

# a weekday schedule: 10 March 2024 is a Sunday, the next Monday is the 11th
oWeek = dnStatic("Cronos.CronExpression","Parse",["0 9 * * MON"])
dnAssert("a Monday",oWeek.GetNextOccurrence(oFrom).Day,11)

# the format with seconds
oSeconds = dnStatic("Cronos.CronExpression","Parse",["*/20 * * * * *",dnStatic("Cronos.CronFormat","IncludeSeconds",[])])
dnAssert("every twenty seconds",oSeconds.GetNextOccurrence(oFrom).Second,20)

# several occurrences in a range
oTo = dnNew("System.DateTime",[ :year = 2024, :month = 3, :day = 10, :hour = 11, :minute = 0, :second = 0, :kind = "Utc" ])
oMany = oEvery5.GetOccurrences([ :fromUtc = oFrom, :toUtc = oTo ])
dnAssert("the occurrences in an hour",oMany.toList()[1] != NULL and len(oMany.toList()) >= 10,1)

try
	dnStatic("Cronos.CronExpression","Parse",["not a cron"])
	dnAssert("a bad expression is an error",1,0)
catch
	dnAssert("a bad expression is an error",substr(cCatchError,"CronFormatException") > 0,1)
done

dnTestSummary()
