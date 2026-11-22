# Slugify: URL slugs from texts (a helper object with options, and the replacements of characters)
load "pkg.ring"
pkgUse("slugify",[["Slugify.Core","5.2.0"]],[["Slugify.Core.dll",["Slugify"]]])
pkgImport("slugify","Slugify.Core.dll","Slugify")

oHelper = new SlugHelper()
dnAssert("a title as a slug",oHelper.GenerateSlug("Hello, World! This is a Test"),"hello-world-this-is-a-test")
dnAssert("accents are removed",oHelper.GenerateSlug("Café Ünïcode ñoño"),"cafe-unicode-nono")
dnAssert("spaces collapse",oHelper.GenerateSlug("  many    spaces   here "),"many-spaces-here")
dnAssert("numbers and dots stay",oHelper.GenerateSlug("Version 2.0 release"),"version-2.0-release")

# the options: another replacement of a space and the case
oConfig = new SlugHelperConfiguration()
oConfig.ForceLowerCase = 0
oConfig.StringReplacements.SetItem(" ","_")
oCustom = dnNew("Slugify.SlugHelper",[oConfig])
dnAssert("a slug with underscores and the case kept",oCustom.GenerateSlug("Hello World"),"Hello_World")

# a replacement of a character
oConfig2 = new SlugHelperConfiguration()
oConfig2.StringReplacements.SetItem("&","and")
oAnd = dnNew("Slugify.SlugHelper",[oConfig2])
dnAssert("a replacement of a character",oAnd.GenerateSlug("Salt & Pepper"),"salt-and-pepper")


dnTestSummary()
