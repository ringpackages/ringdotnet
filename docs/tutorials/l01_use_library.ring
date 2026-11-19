# using a library written in C# - build it, wrap it, call it
#   (the library is in the folder Greeter: Greeter.cs and Greeter.csproj)
load "dotnet.ring"

nTimes = 0                      # event code can only see globals
cHere = currentdir()
cDll = cHere + "/Greeter/bin/Greeter.dll"
cClasses = cHere + "/Greeter/classes"

# STEP 1. Build the C# project (the .NET SDK is needed for this step only)
if not fexists(cDll)
	? "building the library..."
	system("dotnet build Greeter -c Release -o Greeter/bin -nologo -v q > nul")
ok

# STEP 2. Make Ring classes for it. The generator is a Ring program of this package: tools/wrapassembly.ring
chdir("../../tools")
system(exefilename() + " wrapassembly.ring " + cDll + " " + cClasses + " > nul")
chdir(cHere)

# STEP 3. Load the assembly and the generated classes
dnLoad(cDll)
dnImportFrom(cClasses + "/","Tutorial.Greetings")

func main
	# STEP 4. Use the class like any other
	oGreeter = new Greeter()
	? oGreeter.Hello(NULL)                                      # the overload without parameters
	oGreeter.Name = "Ring"                                      # a property
	? oGreeter.Hello(NULL)
	? oGreeter.Hello([ :name = "Ann", :style = "Casual" ])      # named arguments; the enum is a text
	? oGreeter.Hello([ :name = "Bob", :style = "Shout" ])
	? "Greetings so far: " + oGreeter.Greetings                 # a property that can only be read

	# a static method
	? "Add(20,22)      : " + new Greeter().Add(20,22)

	# an out parameter: the answer is a list [worked, result]
	aAnswer = oGreeter.TryDivide(10,4)
	? "TryDivide(10,4) : worked=" + aAnswer[1] + " result=" + aAnswer[2]
	aAnswer = oGreeter.TryDivide(1,0)
	? "TryDivide(1,0)  : worked=" + aAnswer[1]

	# an event: Ring code runs each time the greeter greets
	oGreeter.setGreetedEvent("nTimes++ ? '  (event: someone was greeted: ' + aDotNetArgs[2] + ')'")
	oGreeter.Hello([ :name = "Cy" ])
	? "The event ran " + nTimes + " time(s)"
