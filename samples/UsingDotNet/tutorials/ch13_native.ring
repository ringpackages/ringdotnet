# a function of a native DLL (Windows API) - a small C# library with [DllImport] gives it to Ring, and Ring uses it like any other class
#   (the library is in the folder Native: Win32.cs and Native.csproj)
load "dotnet.ring"

if not iswindows()
	? "The functions of this lesson are in the DLLs of Windows (kernel32 and user32), so it runs on Windows only."
	bye
ok

cHere = currentdir()
cDll = cHere + "/Native/bin/Native.dll"
cClasses = cHere + "/Native/classes"

# STEP 1. Build the C# library (the .NET SDK is needed for this step only)
if not fexists(cDll)
	? "building the library..."
	system("dotnet build Native -c Release -o Native/bin -nologo -v q > nul")
ok

# STEP 2. Make Ring classes for it (tools/dotnettools/wrapassembly.ring)
chdir("../../../tools/dotnettools")
system(exefilename() + " wrapassembly.ring " + cDll + " " + cClasses + " > nul")
chdir(cHere)

# STEP 3. Load the assembly and the classes
dnLoad(cDll)
dnImportFrom(cClasses + "/","Tutorial.Native")

func main
	# STEP 4. Use the class. Win32 is a static class, and a static method is called on an object, as with Math.
	oWin = new Win32()

	# numbers in, a number out: kernel32.MulDiv(10, 3, 4) is 10 * 3 / 4 rounded
	? "Scale(10,3,4)             : " + oWin.Scale(10,3,4)

	# a text that the function changes in place
	? "UpperCase('ring')         : " + oWin.UpperCase("ring")

	# a function that fills a buffer with a text
	cPath = oWin.Variable("PATH")
	? "the PATH is not empty     : " + (len(cPath) > 0)
	? "a missing variable is ''  : [" + oWin.Variable("NO_SUCH_VARIABLE_FOR_THE_TUTORIAL") + "]"

	# a function that fills a structure
	? "the computer has more than 1 GB of memory : " + (oWin.MemoryMegabytes() > 1024)

	# a number from the system (a yes/no is 1 or 0 in Ring)
	? "the screen is wider than 0 : " + (oWin.ScreenSize(0) > 0)

