# UAParser: the user agent text of a browser parsed with a set of rules (regexes) into browser, system and device
load "pkg.ring"
pkgUse("uaparser",[["UAParser","3.1.47"]],[["UAParser.dll",["UAParser"]]])
pkgImport("uaparser","UAParser.dll","UAParser")

cChrome = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
oParser = dnStatic("UAParser.Parser","GetDefault",[])
oInfo = oParser.Parse(cChrome)
dnAssert("the browser",oInfo.UA.Family,"Chrome")
dnAssert("the major version",oInfo.UA.Major,"120")
dnAssert("the system",oInfo.OS.Family,"Windows")

cIphone = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
oPhone = oParser.Parse(cIphone)
dnAssert("a phone's system",oPhone.OS.Family,"iOS")
dnAssert("its browser",oPhone.UA.Family,"Mobile Safari")
dnAssert("its device",oPhone.Device.Family,"iPhone")

dnAssert("a text that is no browser",oParser.Parse("nothing").UA.Family,"Other")

dnTestSummary()
