# Microsoft.Extensions.DependencyInjection (the library has the classes of this namespace itself: the DLLs are only loaded): a service collection and a provider; singletons, transients made by a Ring callback, scopes, generic extension methods
load "pkg.ring"
pkgUse("di",[["Microsoft.Extensions.DependencyInjection","9.0.23"]],[["Microsoft.Extensions.DependencyInjection.dll",[]],["Microsoft.Extensions.DependencyInjection.Abstractions.dll",[]]])
dnImport("System.Text")
nMade = 0          # how many objects the callback made

oServices = dnNew("Microsoft.Extensions.DependencyInjection.ServiceCollection",[])
dnAssert("an empty collection",oServices.Count,0)

# a singleton: one instance for every request
oShared = new StringBuilder("shared")
cExtensions = "Microsoft.Extensions.DependencyInjection.ServiceCollectionServiceExtensions"
oSbType = dnType("System.Text.StringBuilder")
dnRequest("call",[dnType(cExtensions),"AddSingleton",oServices,oSbType,oShared])
dnAssert("a service was added",oServices.Count,1)

# a transient made by a callback: a new object each time
dnRequest("call",[dnType(cExtensions),"AddTransient",oServices,dnType("System.Text.StringBuilder"),dnCallback("makeBuilder")])
dnAssert("a second descriptor for the type",oServices.Count,2)

oProvider = dnRequest("call",[dnType("Microsoft.Extensions.DependencyInjection.ServiceCollectionContainerBuilderExtensions"),"BuildServiceProvider",oServices])
dnAssert("a provider",isobject(oProvider),1)

# the last registration wins: the callback
oFirst = oProvider.GetService(oSbType)
oSecond = oProvider.GetService(oSbType)
dnAssert("the callback made the first object",oFirst.ToString(),"made 1")
dnAssert("a transient is a new object each time",oSecond.ToString(),"made 2")

# all the registrations of a type, in order of registration
aAll = dnRequest("call",[dnType("Microsoft.Extensions.DependencyInjection.ServiceProviderServiceExtensions"),"GetServices",oProvider,oSbType]).toList()
dnAssert("GetServices gives both registrations",len(aAll),2)
dnAssert("the first registration is the singleton",aAll[1].ToString(),"shared")

# a generic extension method: the type argument says what is asked
oTyped = dnType("Microsoft.Extensions.DependencyInjection.ServiceProviderServiceExtensions").callGeneric("GetRequiredService",["System.Text.StringBuilder"],[oProvider])
dnAssert("GetRequiredService<T>",oTyped.ToString() != "",1)

# a type that was not registered
dnAssert("GetService of an unknown type is null",oProvider.GetService(dnType("System.Uri")).isNull(),1)
try
	dnType("Microsoft.Extensions.DependencyInjection.ServiceProviderServiceExtensions").callGeneric("GetRequiredService",["System.Uri"],[oProvider])
	dnAssert("GetRequiredService of an unknown type is an error",1,0)
catch
	dnAssert("GetRequiredService of an unknown type is an error",substr(cCatchError,"No service for type") > 0,1)
done

# a scope
oScope = oProvider.CreateScope()
dnAssert("a scope has its own provider",isobject(oScope.ServiceProvider),1)
oScope.Dispose()

dnTestSummary()

func makeBuilder aArgs
	nMade++
	return new StringBuilder("made " + nMade)
