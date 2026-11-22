# Pluralize.NET: English plurals and singulars (a pluralizer object; text in, text out)
load "pkg.ring"
pkgUse("pluralize",[["Pluralize.NET","1.0.2"]],[["Pluralize.NET.dll",["Pluralize.NET"]]])
pkgImport("pluralize","Pluralize.NET.dll","Pluralize.NET")

oPluralizer = new Pluralizer()
dnAssert("a regular plural",oPluralizer.Pluralize("dog"),"dogs")
dnAssert("an irregular plural",oPluralizer.Pluralize("person"),"people")
dnAssert("a word that ends in y",oPluralizer.Pluralize("city"),"cities")
dnAssert("a word that ends in s",oPluralizer.Pluralize("bus"),"buses")
dnAssert("a singular",oPluralizer.Singularize("dogs"),"dog")
dnAssert("an irregular singular",oPluralizer.Singularize("children"),"child")
dnAssert("a word that does not change",oPluralizer.Pluralize("sheep"),"sheep")
dnAssert("is plural",oPluralizer.IsPlural("cats"),1)
dnAssert("is singular",oPluralizer.IsSingular("cats"),0)
dnAssert("a count of one stays singular",oPluralizer.Format([ :word = "item", :count = 1, :inclusive = 1 ]),"1 item")
dnAssert("a count of three is plural",oPluralizer.Format([ :word = "item", :count = 3, :inclusive = 1 ]),"3 items")

dnTestSummary()
