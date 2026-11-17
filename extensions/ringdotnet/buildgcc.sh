gcc -shared -fpic -O2 ring_dotnet.c -o $PWD/../../lib/libring_dotnet.so -I $PWD/../../language/include -L $PWD/../../lib -lring -ldl
(cd bridge && dotnet build -c Release -o $PWD/../../../lib)
