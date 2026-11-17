# Item tags of the wire format shared with the managed bridge (see bridge/Bridge.cs)
C_DOTNET_STRING = "s"
C_DOTNET_NUMBER = "n"
C_DOTNET_BOOL   = "b"
C_DOTNET_NULL   = "z"
C_DOTNET_OBJECT = "o"
C_DOTNET_LIST   = "l"
C_DOTNET_ERROR  = "e"

# Used by the generated classes to wrap an existing .NET object without creating a new one
nDotNetWrapHandle = 0

# Cache of type objects used for static members (type name --> DotNetObject)
aDotNetTypes = []
