# SmartFormat: named and indexed placeholders, plurals, conditions, lists, params object[]
load "pkg.ring"
pkgUse("smartformat",[["SmartFormat.NET","3.6.0"]],[["SmartFormat.dll",["SmartFormat"]]])
pkgImport("smartformat","SmartFormat.dll","SmartFormat")

dnAssert("indexed placeholders",dnStatic("SmartFormat.Smart","Format",["{0} has {1} items","Ann",3]),"Ann has 3 items")
dnAssert("a plural: one",dnStatic("SmartFormat.Smart","Format",["{0} {0:plural:item|items}",1]),"1 item")
dnAssert("a plural: many",dnStatic("SmartFormat.Smart","Format",["{0} {0:plural:item|items}",5]),"5 items")
dnAssert("a condition",dnStatic("SmartFormat.Smart","Format",["{0:cond:>10?big|small}",42]),"big")
dnAssert("a list",dnStatic("SmartFormat.Smart","Format",["{0:list:{}|, | and }",[["a","b","c"]]]),"a, b and c")
dnAssert("a choice",dnStatic("SmartFormat.Smart","Format",["{0:choose(1|2):one|two|other}",2]),"two")
dnAssert("a number format",dnStatic("SmartFormat.Smart","Format",["{0:N2}",3.14159]),"3.14")

dnTestSummary()
