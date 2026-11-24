# Where the time of a call from Ring to .NET goes (run it by hand: ring bench_wire.ring; run.sh does not start it).
#
# bench_calls.ring answers "how much does one kind of call cost". This program separates the parts of a call, so that a change
# (a different wire format, a cache, typed entry points) can be judged on the part that it changes:
#
#   1. the floor     a Ring call, and the cheapest call to .NET (a property read that returns a number)
#   2. the result    yes/no, number, text, a long text, an object (the wrapper object that Ring makes)
#   3. the argument  a text of 1, 1000 and 100000 bytes; whole numbers and numbers with a fraction
#   4. the style     oRnd.Next(...) or callMethod("Next",[...]); one request or 500 requests for 500 items
#   5. the object    the cost of making the wrapper of a small class and of a class with many properties
#
# Every case runs five times; the table shows the best time and the middle time, in microseconds for one call, and the best time
# minus the time of an empty Ring call. The numbers differ from computer to computer: compare two runs on the same computer in
# the same session, before and after a change.

load "dotnet.ring"

using {
	"System"
	"System.Collections.Generic"
	"System.Text"
}

# The objects and the texts that the cases use are global, because eval() runs the code of a case inside measure().
oList = ""
oList500 = ""
oSB = ""
oBig = ""
oRnd = ""
c1k = ""
c100k = ""
nRuns = 5
nBase = 0

func main

	oList = new StringList()
	oList.Add("a")
	oList500 = new StringList()
	for i = 1 to 500  oList500.Add("item " + i)  next
	oSB = new StringBuilder("x")
	oBig = new StringBuilder(copy("x",100000))
	oRnd = new Random(42)
	c1k = copy("x",1000)
	c100k = copy("x",100000)

	# The first call starts the runtime and fills the caches of the bridge: it is not measured.
	r = oList.Contains("a")
	r = oList.Item(0)
	r = oSB.Length
	r = oSB.Append("")
	r = dnStatic("System.Math","Max",[3,9])
	r = oRnd.@Next(10)
	r = oList500.toList()
	r = oBig.ToString()
	r = new Uri("http://example.com/a")

	? ""
	? padRight("case",66) + padLeft("best us",10) + padLeft("middle us",11) + padLeft("best - empty",14)
	? copy("-",101)

	nBase = measure("Ring: an empty function call (the floor of the loop)","r = noop(1)",200000,0)

	section("1. the cheapest call to .NET")
	measure("a property read, a number                (Length)","r = oSB.Length",20000,nBase)

	section("2. the type of the result (no arguments or the smallest one)")
	measure("a yes/no                                (Contains)",'r = oList.Contains("a")',20000,nBase)
	measure("a text                                  (Item)",'r = oList.Item(0)',20000,nBase)
	measure("a text of 100000 bytes                  (ToString)","r = oBig.ToString()",500,nBase)
	measure("an object (the wrapper is made)         (Append)",'r = oSB.Append("")',20000,nBase)

	section("3. the size and the kind of the argument (the result is a yes/no or a number)")
	measure("a text of 1 byte",'r = oList.Contains("a")',20000,nBase)
	measure("a text of 1000 bytes","r = oList.Contains(c1k)",20000,nBase)
	measure("a text of 100000 bytes","r = oList.Contains(c100k)",1000,nBase)
	measure("two whole numbers, a static method      (Math.Max)","r = dnStatic('System.Math','Max',[3,9])",20000,nBase)
	measure("two numbers with a fraction             (Math.Max)","r = dnStatic('System.Math','Max',[3.5,9.25])",20000,nBase)

	section("4. the style of the call, and the number of requests")
	measure("overloaded, one argument               (Next)","r = oRnd.@Next(10)",20000,nBase)
	measure("the same method, as callMethod         (Next)","r = oRnd.callMethod('Next',[10])",20000,nBase)
	measure("500 items, one request each: Item(j)","for j = 0 to 499  r = oList500.Item(j)  next",20,nBase)
	measure("500 items, one request: toList()","r = oList500.toList()",200,nBase)

	section("5. making the wrapper object")
	measure("new StringBuilder('x')                  (small class)",'r = new StringBuilder("x")',5000,nBase)
	measure("new Uri('http://example.com/a')         (a class with many properties)",'r = new Uri("http://example.com/a")',5000,nBase)
	? ""

func section cTitle

	? ""
	? cTitle

# Runs the code of one case nRuns times and writes one line. Returns the best time for one call, in microseconds.
func measure cTitle, cCode, nCount, nFloor

	aTimes = []
	for nRun = 1 to nRuns
		t0 = clock()
		eval("for i = 1 to " + nCount + " " + cCode + " next")
		aTimes + ((clock() - t0) * 1000000 / clockspersecond() / nCount)
	next
	aTimes = sort(aTimes)
	nBest = aTimes[1]
	nMiddle = aTimes[(nRuns + 1) / 2]
	cNet = ""
	if nFloor > 0
		nNet = nBest - nFloor
		if nNet < 0  nNet = 0  ok
		cNet = fixed(nNet)
	ok
	? padRight(cTitle,66) + padLeft(fixed(nBest),10) + padLeft(fixed(nMiddle),11) + padLeft(cNet,14)
	return nBest

func noop x

	return x

func fixed n

	return "" + (floor(n * 100 + 0.5) / 100)

func padRight c, n

	if len(c) >= n  return left(c,n - 1) + " "  ok

	return c + copy(" ",n - len(c))

func padLeft c, n

	if len(c) >= n  return c  ok

	return copy(" ",n - len(c)) + c
