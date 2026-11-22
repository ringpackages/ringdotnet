# LazyCache: a cache whose GetOrAdd takes a delegate that makes the value: the delegate is Ring code (dnCallback), run only on a miss
load "pkg.ring"
pkgUse("lazycache",[["LazyCache","2.4.0"]],[["LazyCache.dll",["LazyCache"]]])
pkgImport("lazycache","LazyCache.dll","LazyCache")

nMade = 0
oCache = new CachingService()

oFirst = dnType("LazyCache.AppCacheExtensions").callGeneric("GetOrAdd",["System.String"],[oCache,"key",dnCallback("makeValue")])
dnAssert("the delegate made the value",oFirst,"made 1")
oSecond = dnType("LazyCache.AppCacheExtensions").callGeneric("GetOrAdd",["System.String"],[oCache,"key",dnCallback("makeValue")])
dnAssert("the cached value is returned",oSecond,"made 1")
dnAssert("the delegate ran once",nMade,1)

dnType("LazyCache.AppCacheExtensions").callGeneric("GetOrAdd",["System.String"],[oCache,"other",dnCallback("makeValue")])
dnAssert("another key runs it again",nMade,2)

dnAssert("a value is found",oCache.callGeneric("Get",["System.String"],["key"]),"made 1")
oCache.Remove("key")
dnAssert("a removed key is the null",dnIsNull(oCache.callGeneric("Get",["System.String"],["key"])),1)

dnTestSummary()

func makeValue aArgs
	nMade++
	return "made " + nMade
