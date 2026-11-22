# NCrontab: cron expressions; next occurrences from a date, a range of occurrences, six fields with seconds
load "pkg.ring"
pkgUse("ncrontab",[["NCrontab","3.4.0"]],[["NCrontab.dll",["NCrontab"]]])
pkgImport("ncrontab","NCrontab.dll","NCrontab")

oFrom = dnNew("System.DateTime",[ :year = 2024, :month = 3, :day = 10, :hour = 10, :minute = 2, :second = 0 ])
oEvery5 = dnStatic("NCrontab.CrontabSchedule","Parse",["*/5 * * * *"])
oNext = oEvery5.GetNextOccurrence(oFrom)
dnAssert("the next multiple of five",oNext.Minute,5)
dnAssert("in the same hour",oNext.Hour,10)

oDaily = dnStatic("NCrontab.CrontabSchedule","Parse",["30 6 * * *"])
dnAssert("a daily schedule: the day",oDaily.GetNextOccurrence(oFrom).Day,11)
dnAssert("a daily schedule: the hour",oDaily.GetNextOccurrence(oFrom).Hour,6)

oOptions = dnNew("NCrontab.CrontabSchedule+ParseOptions",[])
oOptions.IncludingSeconds = 1
oSeconds = dnStatic("NCrontab.CrontabSchedule","Parse",["*/20 * * * * *",oOptions])
dnAssert("every twenty seconds",oSeconds.GetNextOccurrence(oFrom).Second,20)

oTo = dnNew("System.DateTime",[ :year = 2024, :month = 3, :day = 10, :hour = 11, :minute = 0, :second = 0 ])
dnAssert("the occurrences in an hour",len(oEvery5.GetNextOccurrences(oFrom,oTo).toList()),11)

dnAssert("a valid expression",dnStatic("NCrontab.CrontabSchedule","TryParse",["0 0 * * *"]) != NULL,1)
cError = ""
try
	dnStatic("NCrontab.CrontabSchedule","Parse",["not a cron"])
catch
	cError = cCatchError
done
dnAssert("a bad expression raises an error",len(cError) > 0,1)

dnTestSummary()
