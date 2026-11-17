if isWindows()
	LoadLib("ring_dotnet.dll")
but ismacosx()
	LoadLib("libring_dotnet.dylib")
else
	LoadLib("libring_dotnet.so")
ok
