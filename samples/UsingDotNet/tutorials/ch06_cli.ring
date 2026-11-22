# a command-line tool - arguments, options, usage text and results
#   ring ch06_cli.ring                        runs a demonstration of several command lines
#   ring ch06_cli.ring file.txt --top 5       is a real use of the tool: the 5 most frequent words of file.txt
load "dotnet.ring"
using {
	"System.IO"
	"System.Text.RegularExpressions"
}

func main
	# the arguments after the program name: sysargv = [ring, program, arg1, arg2, ...] (the first two are not ours)
	aArguments = []
	for nIndex = 3 to len(sysargv)
		aArguments + sysargv[nIndex]
	next
	if len(aArguments) > 0
		nCode = run(aArguments)
		? "(exit code " + nCode + ")"
		return
	ok

	# no arguments: a demonstration. A file with some text first.
	cFile = new Path().Combine([new Path().GetTempPath(),"ringdotnet_cli.txt"])
	new File().WriteAllText([ :path = cFile, :contents = "The cat and the dog. The dog and the bird! A cat, a dog, a bird and the fish." ])
	? "$ wordstat --help"
	showResult(run(["--help"]))
	? nl + "$ wordstat ringdotnet_cli.txt --top 3"
	showResult(run([cFile,"--top","3"]))
	? nl + "$ wordstat ringdotnet_cli.txt --top 3 --min 4"
	showResult(run([cFile,"--top","3","--min","4"]))
	? nl + "$ wordstat missing.txt"
	showResult(run(["missing.txt"]))
	? nl + "$ wordstat ringdotnet_cli.txt --top many"
	showResult(run([cFile,"--top","many"]))
	? nl + "$ wordstat ringdotnet_cli.txt --color"
	showResult(run([cFile,"--color"]))
	new File().Delete(cFile)

func showResult nCode
	? "(exit code " + nCode + ")"

# Runs the tool with a list of arguments. It returns an exit code: 0 = success, 1 = a problem with the arguments, 2 = a problem with the file.
func run aArguments
	aOptions = parseArguments(aArguments)
	if islist(aOptions) = False
		return 1
	ok
	if optionValue(aOptions,"help") != ""
		showUsage()
		return 0
	ok
	cFile = optionValue(aOptions,"file")
	if cFile = ""
		? "error: no file given"
		showUsage()
		return 1
	ok
	if not new File().Exists(cFile)
		? "error: the file '" + new Path().GetFileName(cFile) + "' does not exist"
		return 2
	ok
	showStatistics(cFile,number(optionValue(aOptions,"top")),number(optionValue(aOptions,"min")))
	return 0

# Options start with --; some have a value (--top 5). A word without -- is the file. Returns a list of [name, value], or false on a mistake.
func parseArguments aArguments
	aOptions = [["top","10"],["min","1"],["help",""],["file",""]]
	nIndex = 1
	while nIndex <= len(aArguments)
		cArgument = aArguments[nIndex]
		if cArgument = "--help" or cArgument = "-h"
			setOption(aOptions,"help","1")
		but cArgument = "--top" or cArgument = "--min"
			nIndex++
			if nIndex > len(aArguments) or not isNumberText(aArguments[nIndex])
				? "error: " + cArgument + " needs a number"
				return false
			ok
			setOption(aOptions,substr(cArgument,3),aArguments[nIndex])
		but left(cArgument,1) = "-"
			? "error: unknown option " + cArgument
			return false
		else
			setOption(aOptions,"file",cArgument)
		ok
		nIndex++
	end
	return aOptions

func setOption aOptions, cName, cValue
	for nPos = 1 to len(aOptions)
		if aOptions[nPos][1] = cName
			aOptions[nPos][2] = cValue
		ok
	next

func optionValue aOptions, cName
	for aPair in aOptions
		if aPair[1] = cName
			return aPair[2]
		ok
	next
	return ""

func isNumberText cText
	return new Regex("^[0-9]+$").IsMatch(cText)

func showUsage
	? "usage: wordstat FILE [--top N] [--min LENGTH]"
	? "  FILE        a text file"
	? "  --top N     show the N most frequent words (default 10)"
	? "  --min L     ignore words shorter than L letters (default 1)"
	? "  --help      this text"

# the words of a file counted, the most frequent first
func showStatistics cFile, nTop, nMin
	oWords = new Regex("[A-Za-z]+").Matches(new File().ReadAllText(cFile))
	aWords = []                              # [word, count]
	for nIndex = 0 to oWords.Count - 1
		cWord = lower(oWords.Item(nIndex).Value)
		if len(cWord) < nMin
			loop
		ok
		nFound = 0
		for nPos = 1 to len(aWords)
			if aWords[nPos][1] = cWord
				nFound = nPos
			ok
		next
		if nFound > 0
			aWords[nFound][2]++
		else
			aWords + [cWord,1]
		ok
	next
	# sort by count (biggest first), words with the same count by name
	aSorted = sortBy(aWords)
	? "words counted: " + len(aWords) + " different"
	for nIndex = 1 to min(nTop,len(aSorted))
		? "  " + right("   " + aSorted[nIndex][2],3) + "  " + aSorted[nIndex][1]
	next

func sortBy aPairs
	for nI = 1 to len(aPairs) - 1
		for nJ = nI + 1 to len(aPairs)
			if aPairs[nJ][2] > aPairs[nI][2] or (aPairs[nJ][2] = aPairs[nI][2] and strcmp(aPairs[nJ][1],aPairs[nI][1]) < 0)
				aTemp = aPairs[nI]
				aPairs[nI] = aPairs[nJ]
				aPairs[nJ] = aTemp
			ok
		next
	next
	return aPairs
