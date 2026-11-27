# Extension methods of the library are methods of the classes of the types that they extend (and of the classes that implement an interface that
# they extend), the names that are Ring keywords start with @, and an interface has the members that it inherits.
load "dotnet.ring"

using {
	"System"
	"Microsoft.Extensions.DependencyInjection"
	"Microsoft.Extensions.Caching.Memory"
	"Microsoft.Extensions.Configuration"
	"RingDotNet.Web"                  # the configuration classes are part of the ASP.NET Core runtime: this line starts it
}

nMade = 0

func main

	# dependency injection: ServiceCollection implements IServiceCollection, which the extension methods extend
	oServices = new ServiceCollection
	oServices.AddSingleton([ :serviceType = dnType("System.Collections.ArrayList"), :implementationFactory = dnCallback("makeList") ])
	dnAssert("an extension method with parameter names registers a service",oServices.Count,1)
	oProvider = oServices.BuildServiceProvider(NULL)
	dnAssert("an extension method of an interface is a method of the class that implements it",classname(oProvider),"serviceprovider")
	oScope = oProvider.CreateScope()
	dnAssert("an extension method of IServiceProvider is a method of ServiceProvider",classname(oScope),"iservicescope")
	oScope.Dispose()          # IServiceScope inherits Dispose from IDisposable
	lRefused = false
	try
		oScope.ServiceProvider.callMethod("GetService",[dnType("System.Collections.ArrayList")])
	catch
		lRefused = true
	done
	dnAssert("Dispose, a member that an interface inherits, ended the scope",lRefused,true)

	# the memory cache: Set and GetOrCreate are extension methods
	oCache = new MemoryCache(new MemoryCacheOptions())
	oCache.Set([ :key = "k", :value = "v" ])
	dnAssert("Set (an extension method) stores a value",oCache.TryGetValue("k")[2],"v")
	cFirst = oCache.GetOrCreate([ :key = "report", :factory = dnCallback("makeReport") ])
	cSecond = oCache.GetOrCreate([ :key = "report", :factory = dnCallback("makeReport") ])
	dnAssert("GetOrCreate makes the value once",cFirst + "/" + cSecond + "/" + nMade,"made/made/1")

	# the configuration: AddInMemoryCollection is an extension method of the builder, Item is the indexer of the interface
	oData = dnNewGeneric("System.Collections.Generic.Dictionary",["System.String","System.String"],[])
	oData.Add("App:Name","Demo")
	oBuilder = new ConfigurationBuilder
	oBuilder.AddInMemoryCollection([ :initialData = oData ])
	oConfig = oBuilder.Build()
	dnAssert("the indexer of an interface",oConfig.Item("App:Name"),"Demo")

	# names that are Ring keywords start with @: the constructor method @New, and Random.Next
	oSpan = new TimeSpan().@New([ :hours = 1, :minutes = 2, :seconds = 3 ])
	dnAssert("@New chooses a constructor by the names of its parameters",oSpan.ToString(),"01:02:03")
	oFirst = new Random(42)
	oSecond = new Random(42)
	dnAssert("@Next: the same seed gives the same numbers",oFirst.@Next([ :minValue = 1, :maxValue = 1000 ]),oSecond.@Next([ :minValue = 1, :maxValue = 1000 ]))
	dnAssert("@Next with a range of one number",new Random(7).@Next([ :minValue = 5, :maxValue = 6 ]),5)
	dnTestSummary()

func makeList aArguments

	return new ArrayList()

func makeReport aArguments

	nMade++
	return "made"
