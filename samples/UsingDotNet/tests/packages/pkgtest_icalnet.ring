# Ical.Net: a calendar with an event (dates, recurrence), written as iCalendar text and read back
load "pkg.ring"
pkgUse("icalnet",[["Ical.Net","5.2.4"]],[["Ical.Net.dll",["Ical.Net","Ical.Net.CalendarComponents","Ical.Net.DataTypes","Ical.Net.Serialization"]]])
pkgImport("icalnet","Ical.Net.dll","Ical.Net")
pkgImport("icalnet","Ical.Net.dll","Ical.Net.CalendarComponents")
pkgImport("icalnet","Ical.Net.dll","Ical.Net.DataTypes")
pkgImport("icalnet","Ical.Net.dll","Ical.Net.Serialization")
dnImport("System")

oStart = dnNew("Ical.Net.DataTypes.CalDateTime",[ :year = 2024, :month = 5, :day = 17, :hour = 9, :minute = 0, :second = 0 ])
oEnd = dnNew("Ical.Net.DataTypes.CalDateTime",[ :year = 2024, :month = 5, :day = 17, :hour = 10, :minute = 30, :second = 0 ])
oEvent = new CalendarEvent()
oEvent.Summary = "Ring meeting"
oEvent.Description = "talk about .NET"
oEvent.Location = "Cairo"
oEvent.DtStart = oStart
oEvent.DtEnd = oEnd
dnAssert("the summary of an event",oEvent.Summary,"Ring meeting")

oCalendar = new NetCalendar()          # Calendar is the name of System.Globalization.Calendar: this one has the last part of its namespace as a prefix
oCalendar.Events.Add(oEvent)
dnAssert("the calendar has the event",oCalendar.Events.Count,1)

# the iCalendar text
oSerializer = new CalendarSerializer()
cText = oSerializer.SerializeToString(oCalendar)
dnAssert("the text starts a calendar",substr(cText,"BEGIN:VCALENDAR") > 0,1)
dnAssert("the text has the event",substr(cText,"BEGIN:VEVENT") > 0 and substr(cText,"SUMMARY:Ring meeting") > 0,1)
dnAssert("the text has the start",substr(cText,"DTSTART:20240517T090000") > 0,1)
dnAssert("the text has the location",substr(cText,"LOCATION:Cairo") > 0,1)

# read it back
oBack = dnStatic("Ical.Net.Calendar","Load",[cText])
dnAssert("the calendar read back has the event",oBack.Events.Count,1)
oEventBack = oBack.Events.toList()[1]
dnAssert("the summary read back",oEventBack.Summary,"Ring meeting")
dnAssert("the start read back",oEventBack.DtStart.Hour,9)

# a weekly event: the occurrences in a range
oWeekly = new CalendarEvent()
oWeekly.Summary = "Weekly"
oWeekly.DtStart = oStart
oRule = dnNew("Ical.Net.DataTypes.RecurrencePattern",[ :frequency = "Weekly", :interval = 1 ])
oRule.Count = 4
oWeekly.RecurrenceRules.Add(oRule)
oCalendar2 = new NetCalendar()
oCalendar2.Events.Add(oWeekly)
oRange = dnNew("Ical.Net.DataTypes.CalDateTime",[ :year = 2024, :month = 5, :day = 1, :hour = 0, :minute = 0, :second = 0 ])
oOccurrences = oCalendar2.GetOccurrences(oRange)
dnAssert("a weekly event with four occurrences",len(oOccurrences.toList()),4)

dnTestSummary()
