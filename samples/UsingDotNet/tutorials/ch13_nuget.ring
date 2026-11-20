# a NuGet package - the project file asks for the package, dotnet publish copies its DLLs, the generator wraps them, and the classes are used
#   (the project is in the folder Packages: Packages.csproj names Newtonsoft.Json, and Empty.cs is the one source file a project needs)
load "dotnet.ring"

cHere = currentdir()
cDll = cHere + "/Packages/libs/Newtonsoft.Json.dll"
cClasses = cHere + "/Packages/classes"

# STEP 1. Get the package. dotnet publish restores the packages that the project names (from nuget.org the first time, from the
# computer afterwards) and copies their DLLs, with the DLLs they need, into one folder: Packages/libs
if not fexists(cDll)
	? "getting the package..."
	system("dotnet publish Packages -c Release -o Packages/libs -nologo -v q > nul")
ok
if not fexists(cDll)
	? "The package could not be restored. It is downloaded from nuget.org the first time, so the computer needs the internet once."
	bye
ok

# STEP 2. Make Ring classes for the DLL of the package (the generator is a Ring program of this package: tools/dotnettools/wrapassembly.ring)
chdir("../../../tools/dotnettools")
system(exefilename() + " wrapassembly.ring " + cDll + " " + cClasses + " > nul")
chdir(cHere)

# STEP 3. Load the assembly and the classes of its namespaces. Newtonsoft.Json.Linq needs Newtonsoft.Json, and the loader finds it.
dnLoad(cDll)
dnImportFrom(cClasses + "/","Newtonsoft.Json.Linq")
dnImportFrom(cClasses + "/","Newtonsoft.Json")

func main
	# STEP 4. Use the classes like any other
	cText = '{"name":"Ann","age":31,"tags":["ring","dotnet"],"address":{"city":"Cairo"}}'
	oObject = new JObject().Parse(cText)                 # Parse is a static method: it is called on an object, as in the tutorial about the C# library
	? "name    : " + oObject.Item("name").ToString()
	? "age     : " + oObject.Item("age").ToString()
	? "city    : " + oObject.SelectToken("address.city").ToString()          # a path into the document
	? "tags    : " + oObject.Item("tags").Count

	# a value is added with the name of the property and a JValue (the overload is chosen by the names of the parameters)
	oObject.Add([ :propertyName = "country", :value = new JValue("Egypt") ])
	? nl + "the document with the new property:"
	? oObject.ToString()

	# the other namespace of the package: JsonConvert turns a value into JSON text
	? nl + "a text as JSON   : " + new JsonConvert().SerializeObject("a b")
	? "a number as JSON : " + new JsonConvert().SerializeObject(42)          # a Ring number is a double, so 42 becomes 42.0
