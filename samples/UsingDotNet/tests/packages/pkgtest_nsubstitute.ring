# NSubstitute: a substitute (a mock) of an interface made at run time (the type argument is the interface), with return values, arguments and the calls it received
load "pkg.ring"
pkgUse("nsubstitute",[["NSubstitute","6.2.0"]],[["NSubstitute.dll",["NSubstitute"]]])
pkgImport("nsubstitute","NSubstitute.dll","NSubstitute")
dnImport("System")
dnImport("System.Collections")

oExtensions = dnType("NSubstitute.SubstituteExtensions")
# a substitute of IComparable: its CompareTo answers what we set
oSubstitute = dnType("NSubstitute.Substitute").callGeneric("For",["System.IComparable"],[ [] ])
dnAssert("a substitute is an object that implements the interface",isobject(oSubstitute),1)
dnAssert("a call with no value set gives the default",oSubstitute.CompareTo("x"),0)

# set a return value: the extension method Returns of the call that was made
oCall = oSubstitute.CompareTo("a")
oExtensions.callGeneric("Returns",["System.Int32"],[oCall,7])          # Ring numbers are doubles: the type argument says Int32
dnAssert("the value that was set",oSubstitute.CompareTo("a"),7)
dnAssert("another argument gets the default",oSubstitute.CompareTo("b"),0)

# calls that were received
oSubstitute.CompareTo("c")
oSubstitute.CompareTo("c")
aCalls = dnStatic("NSubstitute.SubstituteExtensions","ReceivedCalls",[oSubstitute]).toList()
dnAssert("the calls that the substitute received",len(aCalls) >= 5,1)
oLast = aCalls[len(aCalls)]
dnAssert("a call has its method",oLast.callMethod("GetMethodInfo",[]).getProp("Name"),"CompareTo")
dnAssert("a call has its arguments",oLast.callMethod("GetArguments",[]).toList()[1],"c")

# a substitute of an interface with several members
oEnumerator = dnType("NSubstitute.Substitute").callGeneric("For",["System.Collections.IEnumerator"],[ [] ])
dnAssert("MoveNext gives false by default",oEnumerator.MoveNext(),0)
oMove = oEnumerator.MoveNext()
oBools = oExtensions.callGeneric("Returns",["System.Boolean"],[oMove,1])
dnAssert("MoveNext after Returns",oEnumerator.MoveNext(),1)

dnTestSummary()
