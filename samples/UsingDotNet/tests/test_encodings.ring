# Legacy encodings (Windows-1256 Arabic, Shift-JIS, ISO-8859-1) from the code pages provider of .NET: text to bytes and back, binary safe
load "dotnet.ring"

dnType("System.Text.Encoding").callMethod("RegisterProvider",[dnStatic("System.Text.CodePagesEncodingProvider, System.Text.Encoding.CodePages","Instance",[])])

oArabic = dnStatic("System.Text.Encoding","GetEncoding",[1256])
dnAssert("the name",oArabic.WebName,"windows-1256")
cBytes = oArabic.GetBytes("مرحبا")
dnAssert("one byte for each Arabic letter",len(cBytes),5)
dnAssert("the first letter (meem) is 0xE3",ascii(cBytes[1]),227)
dnAssert("and reads back",oArabic.GetString(cBytes),"مرحبا")
dnAssert("a Latin letter is one byte",oArabic.GetBytes("A"),"A")

oJapanese = dnStatic("System.Text.Encoding","GetEncoding",[932])
cShift = oJapanese.GetBytes("日本語")
dnAssert("two bytes for each Japanese character",len(cShift),6)
dnAssert("Shift-JIS reads back",oJapanese.GetString(cShift),"日本語")

oLatin = dnStatic("System.Text.Encoding","GetEncoding",["iso-8859-1"])
dnAssert("é is one byte in Latin-1",len(oLatin.GetBytes("é")),1)
dnAssert("and two in UTF-8",len("é"),2)
dnAssert("Latin-1 reads a byte as é",oLatin.GetString(char(233)),"é")

# a letter that the encoding does not have becomes a question mark
dnAssert("a letter that is not in Latin-1",oLatin.GetBytes("م"),"?")

dnTestSummary()
