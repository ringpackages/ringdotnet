# Unidecode.NET: Unicode text turned into ASCII (a text in, a text out); Cyrillic, Greek, Chinese, accents, emoji
load "pkg.ring"
pkgUse("unidecode",[["Unidecode.NET","2.1.0"]],[["Unidecode.NET.dll",["Unidecode.NET"]]])
pkgImport("unidecode","Unidecode.NET.dll","Unidecode.NET")

dnAssert("Cyrillic",ud("Привет"),"Privet")
dnAssert("accents",ud("Crème brûlée à la façon"),"Creme brulee a la facon")
dnAssert("Greek",ud("Ελλάδα"),"Ellada")
dnAssert("Chinese",ud("北京"),"Bei Jing ")
dnAssert("German",ud("Größe"),"Grosse")
dnAssert("plain text stays",ud("ring 1.28"),"ring 1.28")
dnAssert("an empty text",ud(""),"")
dnAssert("a long text",len(ud(copy("Привет ",1000))),7000)

dnTestSummary()

func ud cText

	return dnType("Unidecode.NET.Unidecoder").callMethod("Unidecode",[cText])
