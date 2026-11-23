# Ring in 15 minutes, part 3: decisions, loops and functions
# Ring runs a file from the top. If the file has a function called main, Ring calls it by itself when it reaches the end of the file.
# The code at the top level (before the first func) runs first. A func continues until the next func or class, so statements go BEFORE the functions.

nTotal = 0                          # a global variable: defined at the top, outside every function

func main

	# 1. if / but (else if) / else, closed with ok
	nAge = 17
	if nAge >= 18
		? "adult"
	but nAge >= 13
		? "teenager"
	else
		? "child"
	ok

	# 2. for counts; "step" changes the size of the step. while repeats while the test is true. loop = next round, exit = leave.
	for nI = 1 to 5
		if nI = 2 loop ok            # skip 2
		if nI = 5 exit ok            # stop at 5
		? "for " + nI
	next
	for nI = 10 to 1 step -4
		? "down " + nI
	next
	nN = 1
	while nN < 100
		nN *= 3
	end
	? "while: " + nN

	# 3. switch compares one value with several cases
	cColor = "green"
	switch cColor
	on "red"
		? "stop"
	on "green"
		? "go"
	other
		? "wait"
	off

	# 4. Functions: parameters come after the name, "return" gives a value (a function without it gives "")
	? square(7)
	? greet("Ann","Hello")
	? greet("Bob","Hi")
	aStats = minMax([4,9,2,7])         # return a list to give several values
	? "min " + aStats[1] + ", max " + aStats[2]

	# 5. A variable made inside a function is local. A variable of the top level (nTotal) is global: functions can read and change it.
	addToTotal(5)
	addToTotal(6)
	? "total (global) = " + nTotal

func square nNumber

	return nNumber * nNumber

# A function has one parameter list: calling greet("Ann") with one value raises an error ("less number of parameters").
func greet cName, cGreeting

	return cGreeting + ", " + cName

func minMax aList

	nMin = aList[1]
	nMax = aList[1]
	for nItem in aList
		if nItem < nMin nMin = nItem ok
		if nItem > nMax nMax = nItem ok
	next
	return [nMin,nMax]

func addToTotal nValue

	nTotal += nValue
