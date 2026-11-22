# Ulid: a struct that is a sortable identifier; parsing, text, time, ordering, 16 bytes
load "pkg.ring"
pkgUse("ulid",[["Ulid","1.3.4"]],[["Ulid.dll",["System"]]])
pkgImport("ulid","Ulid.dll","System")

oUlid = dnStatic("System.Ulid","NewUlid",[])
cText = oUlid.ToString()
dnAssert("26 characters",len(cText),26)
oBack = dnStatic("System.Ulid","Parse",[cText])
dnAssert("parse gives the same text",oBack.ToString(),cText)
dnAssert("16 bytes",len(oBack.ToByteArray()),16)

oOther = dnStatic("System.Ulid","NewUlid",[])
dnAssert("two are different",oOther.ToString() != cText,1)
dnAssert("the later one sorts later",oUlid.CompareTo(oOther) <= 0,1)

oTime = dnNew("System.DateTimeOffset",[ :year = 2024, :month = 5, :day = 6, :hour = 7, :minute = 8, :second = 9, :offset = dnStatic("System.TimeSpan","Zero",[]) ])
oFixed = dnStatic("System.Ulid","NewUlid",[oTime])
dnAssert("the time is kept",oFixed.Time.Year,2024)
dnAssert("the time is kept: the month",oFixed.Time.Month,5)

dnAssert("an empty one",dnStatic("System.Ulid","Empty",[]).ToString(),"00000000000000000000000000")
cError = ""
try
	dnStatic("System.Ulid","Parse",["nope"])
catch
	cError = cCatchError
done
dnAssert("a bad text is an error",len(cError) > 0,1)

dnTestSummary()
