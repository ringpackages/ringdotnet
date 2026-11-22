# Humanizer: extension methods of strings, numbers and time spans, called through their static classes
load "pkg.ring"
pkgUse("humanizer",[["Humanizer.Core","3.0.10"]],[["Humanizer.dll",["Humanizer"]]])
pkgImport("humanizer","Humanizer.dll","Humanizer")
dnImport("System")

dnAssert("Humanize",dnStatic("Humanizer.StringHumanizeExtensions","Humanize",["some_snake_case_text"]),"some snake case text")
dnAssert("Pluralize",dnStatic("Humanizer.InflectorExtensions","Pluralize",["person"]),"people")
dnAssert("Singularize",dnStatic("Humanizer.InflectorExtensions","Singularize",["children"]),"child")
dnAssert("Titleize",dnStatic("Humanizer.InflectorExtensions","Titleize",["hello big world"]),"Hello Big World")
dnAssert("Camelize",dnStatic("Humanizer.InflectorExtensions","Camelize",["hello_world_text"]),"helloWorldText")
dnAssert("Kebaberize",dnStatic("Humanizer.InflectorExtensions","Kebaberize",["HelloWorldText"]),"hello-world-text")
dnAssert("Underscore",dnStatic("Humanizer.InflectorExtensions","Underscore",["HelloWorldText"]),"hello_world_text")
dnAssert("Dehumanize",dnStatic("Humanizer.StringDehumanizeExtensions","Dehumanize",["some text here"]),"SomeTextHere")
dnAssert("ToWords",dnStatic("Humanizer.NumberToWordsExtension","ToWords",[1234]),"one thousand two hundred and thirty-four")
oEnglish = dnNew("System.Globalization.CultureInfo",["en-US"])          # the rules of the current culture decide: English is named
dnAssert("Ordinalize",dnStatic("Humanizer.OrdinalizeExtensions","Ordinalize",[22,oEnglish]),"22nd")
oSpan = new TimeSpan().FromMinutes(90)
dnAssert("a time span",dnStatic("Humanizer.TimeSpanHumanizeExtensions","Humanize",[oSpan]),"1 hour")
dnAssert("a byte size",dnStatic("Humanizer.ByteSizeExtensions","Megabytes",[1.5]).ToString(),"1.5 MB")

dnTestSummary()
