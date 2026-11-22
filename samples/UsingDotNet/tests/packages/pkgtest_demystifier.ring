# Ben.Demystifier: readable stack traces; an extension method on Exception (ToStringDemystified) that works on an exception from a Ring call
load "pkg.ring"
pkgUse("demystifier",[["Ben.Demystifier","0.4.1"]],[["Ben.Demystifier.dll",["System.Diagnostics"]]])

try
	dnStatic("System.Int32","Parse",["not a number"])
catch
	cText = cCatchError
done
dnAssert("the error of a failed parse",substr(cText,"FormatException") > 0,1)

oException = dnNew("System.InvalidOperationException",["something went wrong"])
cDemystified = dnType("System.Diagnostics.ExceptionExtensions").callMethod("ToStringDemystified",[oException])
dnAssert("the text names the exception type",substr(cDemystified,"System.InvalidOperationException") > 0,1)
dnAssert("and the message",substr(cDemystified,"something went wrong") > 0,1)

oThrown = dnType("System.Diagnostics.ExceptionExtensions").callMethod("Demystify",[oException])
dnAssert("Demystify returns the same exception",oThrown.Message,"something went wrong")

dnTestSummary()
