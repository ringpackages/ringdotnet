# NodaTime: dates, times, periods, instants and time zones; operators between objects, patterns, static properties
load "pkg.ring"
pkgUse("nodatime",[["NodaTime","3.3.7"]],[["NodaTime.dll",["NodaTime","NodaTime.Text"]]])
pkgImport("nodatime","NodaTime.dll","NodaTime")
pkgImport("nodatime","NodaTime.dll","NodaTime.Text")

oDate = dnNew("NodaTime.LocalDate",[ :year = 2024, :month = 2, :day = 28 ])
oLater = oDate + dnStatic("NodaTime.Period","FromDays",[3])
dnAssert("a date plus a period, the month",oLater.Month,3)
dnAssert("a date plus a period, the day",oLater.Day,2)
dnAssert("the year",oLater.Year,2024)
dnAssert("the day of the week is an enum text",oLater.DayOfWeek,"Saturday")
bLater = oLater > oDate
dnAssert("dates compare",bLater,1)
dnAssert("dates are equal to themselves",oDate = oDate,1)

oTime = dnNew("NodaTime.LocalTime",[ :hour = 14, :minute = 30 ])
oDateTime = oDate + oTime
dnAssert("a date plus a time",oDateTime.Hour,14)

oProvider = dnType("NodaTime.DateTimeZoneProviders").getProp("Tzdb")
oZone = oProvider.GetZoneOrNull("Africa/Cairo")
dnAssert("a time zone",oZone.Id,"Africa/Cairo")
oInstant = dnStatic("NodaTime.Instant","FromUtc",[2024,6,1,12,0])
dnAssert("an instant",oInstant.ToString(),"2024-06-01T12:00:00Z")
dnAssert("an instant in a zone",oInstant.InZone(oZone).Hour,15)
oNow = dnStatic("NodaTime.SystemClock","Instance",[]).callMethod("GetCurrentInstant",[])
bNow = oNow > oInstant
dnAssert("the clock is after 2024",bNow,1)

oPattern = dnStatic("NodaTime.Text.LocalDatePattern","Create",["yyyy-MM-dd",dnType("System.Globalization.CultureInfo").getProp("InvariantCulture")])
dnAssert("a pattern formats",oPattern.Format(oDate),"2024-02-28")
oParsed = oPattern.Parse("2023-12-25")
dnAssert("a pattern parses",oParsed.Success,1)
dnAssert("the day of the year",oParsed.Value.DayOfYear,359)

dnTestSummary()
