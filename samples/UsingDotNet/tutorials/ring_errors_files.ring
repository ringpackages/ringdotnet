# Ring in 15 minutes, part 5: errors, files, arguments and other files

func main

	# 1. try / catch / done: the error text is in cCatchError. raise() makes an error of your own.
	try
		nResult = 10 / 0
	catch
		? "caught: " + substr(cCatchError,14)     # a runtime error starts with "Error (R1) : ", then the text
	done
	try
		checkAge(-5)
	catch
		? "caught: " + cCatchError
	done
	checkAge(30)
	? "30 is fine"

	# 2. Files: write() and read() work with the whole text of a file; fexists() asks if it exists
	cFile = "ring_intro_demo.txt"
	write(cFile,"line one" + nl + "line two" + nl)
	? fexists(cFile)
	cText = read(cFile)
	? string(len(cText)) + " bytes"
	aLines = str2list(cText)          # a text with lines becomes a list of lines
	? string(len(aLines)) + " lines, the second is: " + aLines[2]
	remove(cFile)
	? fexists(cFile)

	# 3. The arguments of the program: sysargv is [the ring program, your file, the arguments ...]
	? len(sysargv) >= 2                # true: at least [ring, the file]

	# 4. eval() runs text as Ring code; the function name in a text can be called with call
	eval("? 6 * 7")
	cFunction = "hello"
	call cFunction()

	# 5. load "file.ring" runs another file first, at the top of your program (see the next page: load "dotnet.ring")
	? "done"

func checkAge nAge

	if nAge < 0
		raise("an age can not be negative: " + nAge)
	ok

func hello

	? "hello from a function called by name"
