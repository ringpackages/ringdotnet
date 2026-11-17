clang -dynamiclib -O2 ring_dotnet.c -o $PWD/../../lib/libring_dotnet.dylib -I $PWD/../../language/include -L $PWD/../../lib -lring
(cd bridge && dotnet build -c Release -o $PWD/../../../lib)
