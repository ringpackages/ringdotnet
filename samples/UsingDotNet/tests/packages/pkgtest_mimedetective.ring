# Mime-Detective: the type of a file found from its first bytes (the signatures), with the file extension and the MIME type of the best match
load "pkg.ring"
pkgUse("mimedetective",[["Mime-Detective","25.8.1"]],[["MimeDetective.dll",["MimeDetective","MimeDetective.Definitions","MimeDetective.Engine"]]])
pkgImport("mimedetective","MimeDetective.dll","MimeDetective")
pkgImport("mimedetective","MimeDetective.dll","MimeDetective.Definitions")
pkgImport("mimedetective","MimeDetective.dll","MimeDetective.Engine")

# the inspector knows the signatures of the default definitions (hundreds of file types)
oDefinitions = new DefaultDefinitions()
oBuilder = new ContentInspectorBuilder()
oBuilder.Definitions = oDefinitions.All()
oInspector = oBuilder.Build()
oExtensions = new ContentInspectorExtensions()

dnAssert("a PNG",bestExtension(oInspector,oExtensions,char(137) + "PNG" + char(13) + char(10) + char(26) + char(10) + copy(char(0),40)),"png")
dnAssert("a GIF",bestExtension(oInspector,oExtensions,"GIF89a" + copy(char(0),40)),"gif")
dnAssert("a PDF",bestExtension(oInspector,oExtensions,"%PDF-1.4" + nl + copy(" ",40)),"pdf")
dnAssert("a JPEG",bestExtension(oInspector,oExtensions,char(255) + char(216) + char(255) + char(224) + char(0) + char(16) + "JFIF" + char(0) + copy(char(1),40)),"jpg")
dnAssert("a ZIP archive",bestExtension(oInspector,oExtensions,"PK" + char(3) + char(4) + copy(char(0),40)),"zip")

# the MIME type of the best match
oMatches = oInspector.Inspect(char(137) + "PNG" + char(13) + char(10) + char(26) + char(10) + copy(char(0),40))
oByType = oExtensions.ByMimeType(oMatches)
aTypes = oByType.toList()
dnAssert("the MIME type of a PNG",aTypes[1].MimeType,"image/png")

# bytes that no signature knows have no match
oNothing = oInspector.Inspect("just some text that is not a known signature")
dnAssert("unknown bytes have no match",len(oExtensions.ByFileExtension(oNothing).toList()),0)

dnTestSummary()

# the extension of the match that has the most points
func bestExtension oInspector,oExtensions,cBytes

	oMatches = oInspector.Inspect(cBytes)
	aList = oExtensions.ByFileExtension(oMatches).toList()
	if len(aList) = 0
		return ""
	ok
	oBest = aList[1]
	return oBest.Extension
