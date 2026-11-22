# BitFaster.Caching: an LRU cache with generic key and value types; add, try get, count, capacity
load "pkg.ring"
pkgUse("bitfaster",[["BitFaster.Caching","2.5.3"]],[["BitFaster.Caching.dll",["BitFaster.Caching.Lru"]]])
pkgImport("bitfaster","BitFaster.Caching.dll","BitFaster.Caching.Lru")

oCache = dnNew("BitFaster.Caching.Lru.ConcurrentLru`2[[System.Int32],[System.String]]",[3])
oCache.AddOrUpdate(1,"one")
oCache.AddOrUpdate(2,"two")
dnAssert("two items",oCache.Count,2)
aFound = oCache.TryGet(1)
dnAssert("found",aFound[1],1)
dnAssert("its value",aFound[2],"one")
dnAssert("a missing key",oCache.TryGet(9)[1],0)

oCache.AddOrUpdate(3,"three")
oCache.AddOrUpdate(4,"four")
oCache.AddOrUpdate(5,"five")
dnAssert("the capacity holds (a warm and a cold part)",oCache.Count <= 3 + 3,1)
dnAssert("the newest is there",oCache.TryGet(5)[2],"five")

dnAssert("remove",oCache.TryRemove(5)[1],1)
oCache.Clear()
dnAssert("cleared",oCache.Count,0)

dnTestSummary()
