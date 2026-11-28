# LanguageExt.Core: functional types: Option (some or none), Either (left or right), immutable Seq and tuples; the static class Prelude makes them
load "pkg.ring"
pkgUse("languageext",[["LanguageExt.Core","4.4.9"]],[["LanguageExt.Core.dll",["LanguageExt","LanguageExt.Common"]]])
pkgImport("languageext","LanguageExt.Core.dll","LanguageExt")
dnImport("System")

oPrelude = dnType("LanguageExt.Prelude")

# Option: a value that may be missing, without null
oSome = oPrelude.callGeneric("Some",["System.Int32"],[5])
dnAssert("a some value",oSome.IsSome,True)
dnAssert("a some value is not none",oSome.IsNone,False)
dnAssert("the text of a some",oSome.ToString(),"Some(5)")
dnAssert("a some keeps its value",oSome.callMethod("IfNone",[7]),5)
oNone = dnType("LanguageExt.Option`1[[System.Int32]]").getProp("None")
dnAssert("a none value",oNone.IsNone,True)
dnAssert("the text of a none",oNone.ToString(),"None")
dnAssert("a none gives the default",oNone.callMethod("IfNone",[7]),7)
oText = oPrelude.callGeneric("Optional",["System.String"],["x"])
dnAssert("optional makes a some from a value",oText.IsSome,True)
oEmpty = oPrelude.callGeneric("Optional",["System.String"],[dnNull()])
dnAssert("optional makes a none from null",oEmpty.IsNone,True)
dnAssert("two equal some values are equal",oSome.Equals(oPrelude.callGeneric("Some",["System.Int32"],[5])),True)

# Either: a result that is a right value or a left one (an error)
oLeft = oPrelude.callGeneric("Left",["System.String","System.Int32"],["bad"])
oRight = oPrelude.callGeneric("Right",["System.String","System.Int32"],[42])
dnAssert("a left",oLeft.IsLeft,True)
dnAssert("a right",oRight.IsRight,True)
dnAssert("a right is not left",oRight.IsLeft,False)
dnAssert("the text of a left",oLeft.ToString(),"Left(bad)")
dnAssert("the text of a right",oRight.ToString(),"Right(42)")
dnAssert("a right gives its value",oRight.callMethod("IfLeft",[0]),42)
dnAssert("a left gives the default",oLeft.callMethod("IfLeft",[0]),0)

# Seq: an immutable sequence, a change gives a new one
oSeq = dnStatic("LanguageExt.Prelude","Seq",[1,2,3])
dnAssert("a sequence",oSeq.ToString(),"[1, 2, 3]")
oLonger = oSeq.Add(4)
dnAssert("the new sequence has the item",oLonger.ToString(),"[1, 2, 3, 4]")
dnAssert("the old sequence is the same",oSeq.ToString(),"[1, 2, 3]")
aBack = oSeq.callMethod("Reverse",[]).toList()
dnAssert("the reverse",list2str(aBack),"3"+nl+"2"+nl+"1")
dnAssert("the count",oSeq.getProp("Count"),3)

# a tuple
oTuple = dnStatic("LanguageExt.Prelude","Tuple",[1,"a"])
dnAssert("a tuple",oTuple.ToString(),"(1, a)")

dnTestSummary()
