# System.Reactive: observables, subjects and operators; the subscriptions are callbacks of Ring, the operators are generic extension methods with the type arguments
load "pkg.ring"
pkgUse("reactive",[["System.Reactive","7.0.0"]],[["System.Reactive.dll",[]]])
dnImport("System")

aSeen = []
cCompleted = ""
cObservable = "System.Reactive.Linq.Observable"
oLinq = dnType(cObservable)
cSubscribe = "System.ObservableExtensions"

# a sequence of numbers: Range, and the subscription with a callback for each item
oRange = oLinq.callMethod("Range",[1,5])
oSubscription = dnType(cSubscribe).callGeneric("Subscribe",["System.Int32"],[oRange,dnCallback("seeItem")])
dnAssert("the items that were pushed",len(aSeen),5)
dnAssert("the first and the last",aSeen[1] + aSeen[5],6)

# operators: Where and Select with callbacks
aSeen = []
oEven = oLinq.callGeneric("Where",["System.Int32"],[oRange,dnCallback("isEven")])
oSquares = oLinq.callGeneric("Select",["System.Int32","System.Int32"],[oEven,dnCallback("square")])
dnType(cSubscribe).callGeneric("Subscribe",["System.Int32"],[oSquares,dnCallback("seeItem")])
dnAssert("even numbers squared",len(aSeen),2)
dnAssert("the values",aSeen[1] + aSeen[2],20)

# a subject: items pushed by Ring reach the subscribers
aSeen = []
oSubject = dnNew("System.Reactive.Subjects.Subject`1[[System.Int32]]",[])
oSubscribed = dnType(cSubscribe).callGeneric("Subscribe",["System.Int32"],[oSubject,dnCallback("seeItem")])
oSubject.OnNext(10)
oSubject.OnNext(20)
dnAssert("two items from the subject",len(aSeen),2)
oSubscribed.Dispose()
oSubject.OnNext(30)
dnAssert("nothing after the subscription was disposed",len(aSeen),2)

# aggregation: a task with the result
oSum = oLinq.callMethod("Sum",[oRange])
dnAssert("the sum of a sequence (a task)",awaitFirst(oSum,"System.Int32"),15)
oCount = oLinq.callGeneric("Count",["System.Int32"],[oRange])
dnAssert("the count of a sequence",awaitFirst(oCount,"System.Int32"),5)

# the list of the items: ToList gives an observable of one list
oList = oLinq.callGeneric("ToList",["System.Int32"],[oRange])
dnAssert("the items as a list",awaitFirst(oList,"System.Collections.Generic.IList`1[[System.Int32]]").Count,5)

# an error in the source is an error of the subscription
oFailing = oLinq.callGeneric("Throw",["System.Int32"],[dnNew("System.InvalidOperationException",["broken"])])
cError = ""
# two callbacks fit Subscribe(onNext, onCompleted) and Subscribe(onNext, onError): the names of the parameters say which is meant
dnRequest("callnamed",[dnType(cSubscribe),"Subscribe",[ ["typeArguments",["System.Int32"]], ["source",oFailing], ["onNext",dnCallback("seeItem")], ["onError",dnCallback("seeError")] ]])
dnAssert("the error handler got the error",cError,"broken")

dnTestSummary()

func seeItem aArgs
	add(aSeen,aArgs[1])

func seeError aArgs
	cError = aArgs[1].Message

func isEven aArgs
	return aArgs[1] % 2 = 0

func square aArgs
	return aArgs[1] * aArgs[1]

func awaitFirst oObservable, cType
	# ToTask makes a task of the last item of an observable: its Result waits for it
	return dnType("System.Reactive.Threading.Tasks.TaskObservableExtensions").callGeneric("ToTask",[cType],[oObservable]).Result
