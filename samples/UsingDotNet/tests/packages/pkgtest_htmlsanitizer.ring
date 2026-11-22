# HtmlSanitizer: unsafe HTML made safe (scripts, event handlers and bad URLs removed), with the lists of allowed tags and attributes
load "pkg.ring"
pkgUse("htmlsanitizer",[["HtmlSanitizer","11.0.26"]],[["HtmlSanitizer.dll",["Ganss.Xss"]],["AngleSharp.dll",[]],["AngleSharp.Css.dll",[]]])
pkgImport("htmlsanitizer","HtmlSanitizer.dll","Ganss.Xss")

oSanitizer = new HtmlSanitizer()
cSafe = oSanitizer.Sanitize("<p onclick='steal()'>Hello <b>world</b><script>alert(1)</script></p>")
dnAssert("a script is removed",substr(cSafe,"script") = 0 and substr(cSafe,"alert") = 0,1)
dnAssert("an event handler is removed",substr(cSafe,"onclick") = 0,1)
dnAssert("the safe tags stay",substr(cSafe,"<p>Hello <b>world</b></p>") > 0,1)

# links: a javascript URL is removed, a normal one stays
dnAssert("a javascript URL is removed",substr(oSanitizer.Sanitize('<a href="javascript:alert(1)">x</a>'),"javascript") = 0,1)
dnAssert("a normal link stays",substr(oSanitizer.Sanitize('<a href="https://example.org/page">x</a>'),'href="https://example.org/page"') > 0,1)

# a tag that is not allowed is removed (the text stays)
dnAssert("an iframe is removed",substr(oSanitizer.Sanitize('<iframe src="https://evil.example"></iframe>ok'),"iframe") = 0,1)

# the lists can be changed: allow a tag
oSanitizer.AllowedTags.Add("marquee")
dnAssert("an allowed tag stays",substr(oSanitizer.Sanitize("<marquee>moving</marquee>"),"<marquee>moving</marquee>") > 0,1)
oSanitizer.AllowedTags.Remove("b")
dnAssert("a tag that is no longer allowed is removed",substr(oSanitizer.Sanitize("<b>bold</b>"),"<b>") = 0,1)

dnTestSummary()
