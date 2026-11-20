# common mistakes - each one is made on purpose inside try/catch, and the message that Ring or .NET gives is printed, with the fix
# errors on purpose
load "dotnet.ring"
using {
	"System"
	"System.Text"
	"System.Collections.Generic"
}

func main
	# Every mistake is in a try ... catch ... done block, so that the program goes on and shows the next one. In your own program the same
	# mistake stops the program and prints the same message with the line number.
	oList = new StringList
	oList.Add("pear")
	oList.Add("apple")

	# 1. A class that was not imported: Stopwatch is in System.Diagnostics, and the program did not ask for that namespace.
	try
		oWatch = new Stopwatch
	catch
		show("1","a class that is not imported",cCatchError)
	done
	? "   fix: add the namespace to using { ... }   (the class reference lists the namespace of every class)"
	dnImport("System.Diagnostics")
	oWatch = new Stopwatch
	? '   after using { "System.Diagnostics" } (here dnImport) a Stopwatch exists: ' + classname(oWatch)

	# 2. new Class() with empty parentheses.
	try
		oText = new StringBuilder()
	catch
		show("2","new StringBuilder() with empty parentheses",cCatchError)
	done
	oText = new StringBuilder
	oText = new StringBuilder(NULL)
	? '   fix: write new StringBuilder, or new StringBuilder(NULL), or give the value: new StringBuilder("x")'

	# 3. An overloaded method with no argument.
	try
		oList.Sort()
	catch
		show("3","an overloaded method called with no argument",cCatchError)
	done
	oList.Sort(NULL)
	? "   fix: NULL means no arguments: oList.Sort(NULL) gives " + oList.Item(0) + " first"

	# 4. A name with a typing mistake: a method, and a property.
	try
		oList.Ad("fig")
	catch
		show("4","a method name with a typing mistake",cCatchError)
	done
	try
		? oList.Cuont
	catch
		show("4b","a property name with a typing mistake",cCatchError)
	done
	? "   fix: look the name up in the class reference; Ring does not care about upper and lower case (oList.count is "+ oList.count +", the same as Count)"

	# 5. A .NET exception.
	try
		? oList.Item(9)
	catch
		show("5","an index outside the list (an exception of .NET)",cCatchError)
	done
	? "   the message starts with DotNet Error and the name of the exception; the text after it is the explanation of .NET"

	# 6. A value of the wrong kind.
	try
		? new Math().Sqrt("abc")
	catch
		show("6","a text where a number is needed",cCatchError)
	done
	? "   fix: pass what the parameter is: Sqrt(16) is " + new Math().Sqrt(16) + ". Use the class reference to see the types."

	# 7. A .NET null.
	oVariable = new Environment().GetEnvironmentVariable("NO_SUCH_VARIABLE_FOR_THE_TUTORIAL")
	try
		? "7. the variable is " + oVariable
	catch
		show("7","a text joined with a .NET null (the call returned null, and the answer is an object)",cCatchError)
	done
	? "   fix: ask first: oVariable.isNull() is " + oVariable.isNull()

func show cNumber, cTitle, cMessage
	? cNumber + ". " + cTitle
	? "   message: " + cMessage
