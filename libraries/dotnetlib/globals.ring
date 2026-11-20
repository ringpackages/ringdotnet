# Item tags of the wire format shared with the managed bridge (see bridge/Bridge.cs). Each item is <tag><size>:<data>.
# A byte[] is a string item (a Ring text can hold any byte); a number that is not a whole number is a double item (the 8 bytes).
C_DOTNET_STRING = "s"
C_DOTNET_NUMBER = "n"
C_DOTNET_BOOL   = "b"
C_DOTNET_DOUBLE = "d"
C_DOTNET_NULL   = "z"
C_DOTNET_OBJECT = "o"
C_DOTNET_LIST   = "l"
C_DOTNET_ERROR  = "e"
C_DOTNET_CALLBACK = "c"

# The runtime mode that was started: "" (base), "desktop", "web" or "all" (set by dnUseDesktop(), dnUseWeb(), dnUseAll(), and by using { } through them)
cDotNetMode = ""

# Used by the generated classes to wrap an existing .NET object without creating a new one
nDotNetWrapHandle = 0

# Cache of type objects used for static members (type name --> DotNetObject)
aDotNetTypes = []
aDotNetTypeItems = []          # type name --> its wire item (see dnTypeItem)

# Arguments (a list) and result of the Ring callback that .NET is running now;
# callback code can read aDotNetArgs and set xDotNetResult
aDotNetArgs = []
xDotNetResult = ""

# Namespaces loaded by dnImport() and test counters
aDotNetImported = []
nDotNetPass = 0
nDotNetFail = 0

# Generated classes: [.NET type name, Ring class, dummy init arguments] (see dnRegisterClass)
aDotNetClasses = []

# [.NET type name, namespace] of every generated class (generated/classindex.ring): used to import namespaces on demand
aDotNetClassIndex = []

# Hash tables (a list used with a text key is a hash table in Ring: an unknown key reads as ""):
#   aDotNetClassMap[.NET type]   -> the Ring class of the type (registered by the generated files)
#   aDotNetIndexMap[.NET type]   -> the namespace that has a generated class for the type (built from aDotNetClassIndex)
#   aDotNetWrapCache[type chain] -> the factory function that wraps objects of that chain ("-" = a plain DotNetObject); cleared on every import
aDotNetClassMap = []
aDotNetIndexMap = []
aDotNetWrapCache = []
#   aDotNetNameMap[lower case Ring class name] -> its .NET type (used by dnNew("StringBuilder",...))
aDotNetNameMap = []

# Compiled callbacks: [code, function name] (see dnCallback)
aDotNetCallbacks = []

# The object made by the DotNetNew_<Class> function of the class that wraps a returned .NET object
oDotNetNew = ""

# The request being handled by a web handler and the response it produced (see web.ring)
oWebRequest = ""
xWebResponse = ""
