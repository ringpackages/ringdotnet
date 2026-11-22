# Microsoft.Extensions.Caching.Memory: a cache made from options; set, get, try get (out value), remove, expiry
load "pkg.ring"
pkgUse("memorycache",[["Microsoft.Extensions.Caching.Memory","9.0.0"]],[["Microsoft.Extensions.Caching.Memory.dll",["Microsoft.Extensions.Caching.Memory"]],["Microsoft.Extensions.Caching.Abstractions.dll",[]],["Microsoft.Extensions.Options.dll",[]],["Microsoft.Extensions.Primitives.dll",[]],["Microsoft.Extensions.DependencyInjection.Abstractions.dll",[]],["Microsoft.Extensions.Logging.Abstractions.dll",[]]])
pkgImport("memorycache","Microsoft.Extensions.Caching.Memory.dll","Microsoft.Extensions.Caching.Memory")

oMemoryOptions = new MemoryCacheOptions()
oOptions = dnType("Microsoft.Extensions.Options.Options").callGeneric("Create",["Microsoft.Extensions.Caching.Memory.MemoryCacheOptions"],[oMemoryOptions])
oCache = new MemoryCache(oOptions)
dnAssert("a new cache is empty",oCache.Count,0)

dnType("Microsoft.Extensions.Caching.Memory.CacheExtensions").callGeneric("Set",["System.String"],[oCache,"greeting","hello"])
dnAssert("one entry",oCache.Count,1)
aGot = oCache.TryGetValue("greeting")
dnAssert("TryGetValue: found",aGot[1],1)
dnAssert("TryGetValue: the value",aGot[2],"hello")
dnAssert("TryGetValue: a missing key",oCache.TryGetValue("nothing")[1],0)

oCache.Remove("greeting")
dnAssert("removed",oCache.Count,0)

# an entry that expires
oLifetime = dnStatic("System.TimeSpan","FromMilliseconds",[200])
dnType("Microsoft.Extensions.Caching.Memory.CacheExtensions").callGeneric("Set",["System.Int32"],[oCache,"short",42,oLifetime])
dnAssert("an entry with an expiry is there",oCache.TryGetValue("short")[2],42)
dnStatic("System.Threading.Thread","Sleep",[400])
dnAssert("and gone after it",oCache.TryGetValue("short")[1],0)

oCache.Dispose()
dnTestSummary()
