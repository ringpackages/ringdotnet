# Tutorial 33: cultures - the same number, date and text written, read and sorted in different languages
load "../../libraries/dotnetlib/dotnetlib.ring"
using {
	"System"
	"System.Globalization"
}

func main
	oString = new String()
	oConvert = new Convert()
	aCultures = ["en-US","de-DE","fr-FR","ar-EG","ja-JP"]

	# A culture (language + country) decides how numbers, money and dates are written
	? "A number, money and a date in five cultures:"
	oDate = new DateTime(2024,7,4)
	for cName in aCultures
		oCulture = new CultureInfo(cName)
		cNumber = oString.Format_3(oCulture,"{0:N2}",1234567.891)
		cMoney = oString.Format_3(oCulture,"{0:C}",1234.5)
		cLong = oDate.ToString_2("D",oCulture)
		? "   " + cName + " : " + cNumber + "  |  " + cMoney + "  |  " + cLong
	next

	# Reading must use the same culture as the writing: "1.234" is 1.234 in English and 1234 in German
	? nl + "Reading '1.234,5' and '1,234.5' with two cultures:"
	oGerman = new CultureInfo("de-DE")
	oEnglish = new CultureInfo("en-US")
	? "   German reads '1.234,5' as   : " + new Double().Parse_2("1.234,5",oGerman)
	? "   English reads '1,234.5' as  : " + new Double().Parse_2("1,234.5",oEnglish)
	? "   English reads '1.234,5' ok? : " + new Double().TryParse_3("1.234,5","Any",oEnglish)[1]

	# The invariant culture never changes: use it for files and data that programs exchange
	oInvariant = new CultureInfo("en-US").InvariantCulture
	? nl + "Invariant culture   : " + oString.Format_3(oInvariant,"{0:N2}",1234567.891) + "  (for files, not for people)"

	# Sorting and comparing: letters sort differently in different languages
	? nl + "Comparing 'a' and 'B' (negative: the first sorts first, positive: the second):"
	? "   by character code (Ordinal) : " + oString.Compare_3("a","B","Ordinal") + "   (a = 97 is after B = 66)"
	? "   by the English alphabet     : " + oString.Compare_4("a","B",False,oEnglish) + "   (a comes before b)"

	# Case changes also depend on the culture (the Turkish i is the famous example)
	oTurkish = new CultureInfo("tr-TR")
	? nl + "'title' in upper case, English: " + oEnglish.TextInfo.ToUpper("title")
	? "'title' in upper case, Turkish: " + oTurkish.TextInfo.ToUpper("title")

	# The culture of this computer
	? nl + "The current culture is known: " + (len(new CultureInfo("en-US").CurrentCulture.Name) > 0)
