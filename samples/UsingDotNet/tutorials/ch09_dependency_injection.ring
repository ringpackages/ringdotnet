# dependency injection - a service container, the three lifetimes (singleton, transient, scoped) and services that need other services
load "dotnet.ring"
using {
	"System"
	"System.Collections"
	"System.IO"
	"Microsoft.Extensions.DependencyInjection"
}

nSingletons = 0
nTransients = 0
nScoped = 0

func main
	# Dependency injection (DI) means: a part of a program does not create the things it needs, it ASKS for them. A container makes them,
	# and decides how long each one lives. That makes the parts easy to replace and to test, and it is how every ASP.NET program is built.
	# The container works with .NET types as the keys. Here three plain types stand for three services, and a Ring function makes each one
	# (the "factory"): ArrayList = a long-lived service, Random = a new one each time, MemoryStream = one for each request.
	oServices = new ServiceCollection
	oServices.AddSingleton([ :serviceType = dnType("System.Collections.ArrayList"), :implementationFactory = dnCallback("makeSingleton") ])
	oServices.AddTransient([ :serviceType = dnType("System.Random"), :implementationFactory = dnCallback("makeTransient") ])
	oServices.AddScoped([ :serviceType = dnType("System.IO.MemoryStream"), :implementationFactory = dnCallback("makeScoped") ])
	oProvider = oServices.BuildServiceProvider(NULL)
	? "1. " + oServices.Count + " services are registered; the provider is built"

	# 2. SINGLETON: one object for the whole program. It is made the first time somebody asks.
	oArrayList = dnType("System.Collections.ArrayList")
	oFirst = oProvider.GetService(oArrayList)
	oSecond = oProvider.GetService(oArrayList)
	? nl + "2. singleton: asked twice, made " + nSingletons + " time(s), the same object: " + oFirst.Equals(oSecond)

	# 3. TRANSIENT: a new object every time. Good for light things that must not share state.
	oRandom = dnType("System.Random")
	oOne = oProvider.GetService(oRandom)
	oTwo = oProvider.GetService(oRandom)
	? nl + "3. transient: asked twice, made " + nTransients + " time(s), the same object: " + oOne.Equals(oTwo)

	# 4. SCOPED: one object for each SCOPE. A scope is one unit of work: in a web server, one request. Inside a scope the same object comes
	#    back; another scope gets its own.
	oStream = dnType("System.IO.MemoryStream")
	oScope1 = oProvider.CreateScope()
	oScope2 = oProvider.CreateScope()
	oInScope1a = oScope1.ServiceProvider.callMethod("GetService",[oStream])
	oInScope1b = oScope1.ServiceProvider.callMethod("GetService",[oStream])
	oInScope2 = oScope2.ServiceProvider.callMethod("GetService",[oStream])
	? nl + "4. scoped: made " + nScoped + " time(s) for 2 scopes"
	? "   twice in the same scope, the same object: " + oInScope1a.Equals(oInScope1b)
	? "   in another scope, the same object:        " + oInScope1a.Equals(oInScope2)

	# 5. The factory receives the provider, so a service can ask for the services it needs: the scoped MemoryStream asks for the singleton
	#    ArrayList and writes its name in it. Every scope reaches the SAME list: that is how a singleton shares data.
	? nl + "5. the singleton list now says: " + oFirst.Count + " entries, from the " + oFirst.Item(0) + " and the " + oFirst.Item(1)
	oScope1.callMethod("Dispose",[])
	oScope2.callMethod("Dispose",[])

	# 6. The rules of thumb. A service must not keep a shorter-lived service inside it (a singleton that holds a scoped object would keep it
	#    for ever, and share it between requests). Things that hold a file, a connection or a lot of memory are disposed when their scope ends.
	? nl + "6. total made: singleton " + nSingletons + ", transient " + nTransients + ", scoped " + nScoped

func makeSingleton aArguments
	nSingletons++
	return new ArrayList

func makeTransient aArguments
	nTransients++
	return new Random

# the first value of the arguments is the provider of the scope: it can give other services
func makeScoped aArguments
	nScoped++
	oProvider = aArguments[1]
	oList = oProvider.callMethod("GetService",[dnType("System.Collections.ArrayList")])
	if nScoped = 1
		oList.Add("first scope")
	else
		oList.Add("second scope")
	ok
	return new MemoryStream
