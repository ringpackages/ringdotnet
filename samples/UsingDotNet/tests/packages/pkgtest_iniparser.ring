# ini-parser: INI text is parsed into sections and keys, read, changed, extended and written back as text
load "pkg.ring"
pkgUse("iniparser",[["ini-parser-netstandard","2.5.2"]],[["INIFileParser.dll",["IniParser","IniParser.Model","IniParser.Parser"]]])
pkgImport("iniparser","INIFileParser.dll","IniParser")
pkgImport("iniparser","INIFileParser.dll","IniParser.Model")
pkgImport("iniparser","INIFileParser.dll","IniParser.Parser")

cIni = "name = Ring" + nl + "; a comment about the database" + nl + "[database]" + nl + "host = localhost" + nl + "port = 5432" + nl + nl + "[paths]" + nl + "home = /usr/ring" + nl
oParser = new IniDataParser()
oData = oParser.Parse(cIni)
dnAssert("the parser found no errors",oParser.HasError,False)
dnAssert("two sections",oData.Sections.Count,2)
dnAssert("a global key",oData.Global.Item("name"),"Ring")
oDatabase = oData.Sections.GetSectionData("database")
dnAssert("a section name",oDatabase.SectionName,"database")
dnAssert("a key of a section",oDatabase.Keys.Item("host"),"localhost")
dnAssert("a number is text",oDatabase.Keys.Item("port"),"5432")
dnAssert("the keys of a section",oDatabase.Keys.Count,2)
dnAssert("a key through the data",oData.GetKey("database.port"),"5432")
dnAssert("a section that is there",oData.Sections.ContainsSection("paths"),True)
dnAssert("a section that is not there",oData.Sections.ContainsSection("other"),False)
dnAssert("a key that is there",oDatabase.Keys.ContainsKey("host"),True)
dnAssert("a key that is not there",oDatabase.Keys.ContainsKey("user"),False)

# change, add and remove
oDatabase.Keys.SetItem("port","5433")
oDatabase.Keys.AddKey("user")
oDatabase.Keys.SetItem("user","ring")
dnAssert("a changed key",oDatabase.Keys.Item("port"),"5433")
dnAssert("an added key",oDatabase.Keys.Item("user"),"ring")
dnAssert("the keys with the new one",oDatabase.Keys.Count,3)
oDatabase.Keys.RemoveKey("user")
dnAssert("a removed key",oDatabase.Keys.Count,2)
oData.Sections.AddSection("cache")
oData.Sections.GetSectionData("cache").Keys.AddKey("size")
dnAssert("an added section",oData.Sections.Count,3)

# written back as text
cOut = oData.ToString()
dnAssert("the text has the section",substr(cOut,"[database]") > 0,True)
dnAssert("the text has the new value",substr(cOut,"port=5433") > 0 or substr(cOut,"port = 5433") > 0,True)
oAgain = oParser.Parse(cOut)
dnAssert("the text is parsed again",oAgain.Sections.Count,3)
dnAssert("the value is the same after the round trip",oAgain.GetKey("database.port"),"5433")

dnTestSummary()
