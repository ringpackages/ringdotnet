# when things go wrong - exceptions, try/catch, checking before you act
load "dotnet.ring"

using {
	"System"
	"System.IO"
}

func main

	# A .NET exception becomes a Ring error you can catch
	try
		new Int32().Parse("abc")
		? "this line is never reached"
	catch
		? "1. Caught the error:"
		? "   " + cCatchError
	done

	# The text of the error names the .NET exception type: you can react to the kind of error
	try
		new File().ReadAllText("c:\this\file\does\not\exist.txt")
	catch
		if substr(cCatchError,"FileNotFoundException") > 0 or substr(cCatchError,"DirectoryNotFoundException") > 0
			? "2. The file is missing"
		else
			? "2. Some other error: " + cCatchError
		ok
	done

	# Often it is better to ask first than to catch
	cName = "c:\this\file\does\not\exist.txt"
	if new File().Exists(cName)
		? "3. Reading it"
	else
		? "3. Exists() said no: no error at all"
	ok

	# TryParse tells you in the result instead of raising an error
	aNumber = new Int32().TryParse("12x")
	if aNumber[1]
		? "4. A number"
	else
		? "4. Not a number: TryParse returned false"
	ok

	# Your own errors: raise() creates one, the caller catches it
	try
		withdraw(100,250)
	catch
		? "5. " + cCatchError
	done

	# Clean up in every case: do it after the try block
	oWriter = ""
	try
		cFile = new Path().Combine([new Path().GetTempPath(),"ringdotnet_errors.txt"])
		oWriter = new StreamWriter(cFile)
		oWriter.WriteLine("some text")
		new Int32().Parse("oops")
	catch
		? "6. Error while writing: the file will still be closed"
	done
	if isobject(oWriter)
		oWriter.Close()
		new File().Delete(cFile)
		? "   closed and deleted the file"
	ok

	# More detail while you are developing: set RINGDOTNET_TRACE=1 to see the .NET stack trace in the error text

func withdraw nBalance, nAmount

	if nAmount > nBalance
		raise("Not enough money: balance " + nBalance + ", asked " + nAmount)
	ok
	return nBalance - nAmount
