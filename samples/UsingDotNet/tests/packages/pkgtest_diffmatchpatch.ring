# DiffMatchPatch: character diffs, a patch made from two texts and applied, fuzzy matching; a class whose name is lower case
load "pkg.ring"
pkgUse("diffmatchpatch",[["DiffMatchPatch","4.0.0"]],[["DiffMatchPatch.dll",["DiffMatchPatch"]]])
pkgImport("diffmatchpatch","DiffMatchPatch.dll","DiffMatchPatch")

oDmp = new diff_match_patch()
aDiffs = oDmp.diff_main([ :text1 = "Ring is great", :text2 = "Ring is very great" ]).toList()
dnAssert("a diff has parts",len(aDiffs) >= 2,1)

cOld = "The quick brown fox jumps over the lazy dog."
cNew = "The quick red fox jumped over the lazy dog!"
aPatches = oDmp.callMethod("patch_make",[cOld,cNew])
aResult = oDmp.callMethod("patch_apply",[aPatches,cOld]).toList()
dnAssert("a patch turns the old text into the new one",aResult[1],cNew)
dnAssert("all of the patches were applied",aResult[2].toList()[1],1)

# the patch is applied to a text that is a little different
cOther = "The quick brown fox jumps over the sleepy dog."
aOther = oDmp.callMethod("patch_apply",[aPatches,cOther]).toList()
dnAssert("a patch applies to a similar text",substr(aOther[1],"red fox jumped") > 0,1)

dnAssert("a fuzzy match finds a place",oDmp.callMethod("match_main",["abcdef ring is here","rng",7]) >= 0,1)

dnTestSummary()
