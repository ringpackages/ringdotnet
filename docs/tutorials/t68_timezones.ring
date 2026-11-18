# Tutorial 68: time zones - UTC, local time, daylight saving, a meeting for several cities and a flight
load "dotnet.ring"
using {
	"System"
}

func main
	oZones = new TimeZoneInfo()
	aCities = [["New York","Eastern Standard Time"],["London","GMT Standard Time"],["Cairo","Egypt Standard Time"],["Tokyo","Tokyo Standard Time"]]

	# 1. A meeting at 12:00 UTC. Store and compare times in UTC; convert to local time only to SHOW them.
	? "1. the meeting at 12:00 UTC on 1 July 2024:"
	oSummer = new DateTime(2024,7,1).AddHours(12)
	for aCity in aCities
		oLocal = localTime(oZones,oSummer,aCity[2])
		? "   " + padRight(aCity[1],10) + oLocal.Format("yyyy-MM-dd HH:mm") + "   (UTC" + offsetText(oZones,oSummer,aCity[2]) + ")"
	next

	# 2. The same meeting in winter: New York, London and Cairo are one hour different (daylight saving time), Tokyo does not have it
	? nl + "2. the same meeting at 12:00 UTC on 15 January 2024:"
	oWinter = new DateTime(2024,1,15).AddHours(12)
	for aCity in aCities
		oLocal = localTime(oZones,oWinter,aCity[2])
		? "   " + padRight(aCity[1],10) + oLocal.Format("yyyy-MM-dd HH:mm") + "   (UTC" + offsetText(oZones,oWinter,aCity[2]) + ")"
	next

	# 3. Is daylight saving time in force?
	oNewYork = oZones.FindSystemTimeZoneById("Eastern Standard Time")
	? nl + "3. New York in July: daylight saving? " + yesNo(oNewYork.IsDaylightSavingTime(oSummer)) + "; in January? " + yesNo(oNewYork.IsDaylightSavingTime(oWinter))

	# 4. A flight: leaves Cairo at 22:30 local time, flies 11 hours 15 minutes. When does it arrive in New York, in New York time?
	oDeparture = new DateTime(2024,7,1).AddHours(22).AddMinutes(30)                 # local time in Cairo
	oDepartureUtc = oZones.ConvertTimeToUtc([ :dateTime = oDeparture, :sourceTimeZone = oZones.FindSystemTimeZoneById("Egypt Standard Time") ])
	oArrivalUtc = oDepartureUtc.AddMinutes(11 * 60 + 15)
	oArrival = oZones.ConvertTimeFromUtc(oArrivalUtc,oNewYork)
	? nl + "4. departure Cairo " + oDeparture.Format("dd MMM HH:mm") + ", arrival New York " + oArrival.Format("dd MMM HH:mm")
	? "   in UTC: " + oDepartureUtc.Format("HH:mm") + " -> " + oArrivalUtc.Format("HH:mm") + " (the duration is the same in every zone)"

	# 5. A day does not always have 24 hours: on 10 March 2024 clocks in New York jump from 02:00 to 03:00
	oMissing = new DateTime(2024,3,10).AddHours(2).AddMinutes(30)
	? nl + "5. does 2:30 on 10 March 2024 exist in New York? " + yesNo(not oNewYork.IsInvalidTime(oMissing))
	oMidnight = new DateTime(2024,3,10)
	oNextMidnight = new DateTime(2024,3,11)
	nHours = (oZones.ConvertTimeToUtc([ :dateTime = oNextMidnight, :sourceTimeZone = oNewYork ]).Ticks - oZones.ConvertTimeToUtc([ :dateTime = oMidnight, :sourceTimeZone = oNewYork ]).Ticks) / 36000000000
	? "   hours between midnight and midnight that day: " + nHours

func localTime oZones, oUtc, cZoneId
	return oZones.ConvertTimeFromUtc(oUtc,oZones.FindSystemTimeZoneById(cZoneId))

# "+02:00" or "-04:00": the offset from UTC at that moment (it includes daylight saving)
func offsetText oZones, oUtc, cZoneId
	oZone = oZones.FindSystemTimeZoneById(cZoneId)
	cOffset = oZone.GetUtcOffset(oUtc).ToString()
	if left(cOffset,1) != "-"
		cOffset = "+" + cOffset
	ok
	return left(cOffset,6)

func padRight cText, nWidth
	while len(cText) < nWidth
		cText += " "
	end
	return cText

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"
