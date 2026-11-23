# The cost of a call from Ring to .NET, in microseconds (run it by hand: ring bench_calls.ring; run.sh does not start it).
# Compare the numbers before and after a change of the library on the same computer in the same session: they differ from computer to computer.
load "dotnet.ring"

using {
	"System.Collections.Generic"
	"System.Text"
}

func main

	oList = new StringList()
	oList.Add("a")
	oSB = new StringBuilder("x")
	nCount = 20000

	t0 = clock()
	for i = 1 to nCount  r = oList.Contains("a")  next
	report("a method that returns a yes/no  (Contains)",t0,nCount)

	t0 = clock()
	for i = 1 to nCount  r = oList.Item(0)  next
	report("a method that returns a text    (Item)    ",t0,nCount)

	t0 = clock()
	for i = 1 to nCount  r = oSB.Length  next
	report("a property read                 (Length)  ",t0,nCount)

	t0 = clock()
	for i = 1 to nCount  r = oSB.Append("")  next
	report("a method that returns an object (Append)  ",t0,nCount)

	t0 = clock()
	for i = 1 to nCount  r = new StringBuilder("x")  next
	report("new StringBuilder('x')                    ",t0,nCount)

func report cTitle, nStart, nCount

	? cTitle + " : " + ((clock() - nStart) * 1000000 / clockspersecond() / nCount) + " us"
