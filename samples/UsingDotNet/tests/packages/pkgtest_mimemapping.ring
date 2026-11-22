# MimeMapping: media types of file names and extensions (static methods that take and return texts), and the reverse
load "pkg.ring"
pkgUse("mimemapping",[["MimeMapping","3.1.0"]],[["MimeMapping.dll",["MimeMapping"]]])
pkgImport("mimemapping","MimeMapping.dll","MimeMapping")

dnAssert("a png",dnStatic("MimeMapping.MimeUtility","GetMimeMapping",["photo.png"]),"image/png")
dnAssert("a json file",dnStatic("MimeMapping.MimeUtility","GetMimeMapping",["data.json"]),"application/json")
dnAssert("a path",dnStatic("MimeMapping.MimeUtility","GetMimeMapping",["C:/files/report.pdf"]),"application/pdf")
dnAssert("upper case",dnStatic("MimeMapping.MimeUtility","GetMimeMapping",["PHOTO.JPG"]),"image/jpeg")
dnAssert("an unknown extension",dnStatic("MimeMapping.MimeUtility","GetMimeMapping",["file.unknownext"]),"application/octet-stream")
dnAssert("no extension",dnStatic("MimeMapping.MimeUtility","GetMimeMapping",["README"]),"application/octet-stream")
dnAssert("a name that is not English",dnStatic("MimeMapping.MimeUtility","GetMimeMapping",["مستند.txt"]),"text/plain")

aExtensions = dnStatic("MimeMapping.MimeUtility","GetExtensions",["image/jpeg"]).toList()
dnAssert("a type has several extensions",len(aExtensions) >= 2,1)

dnTestSummary()
