# Microsoft.Extensions.ObjectPool: a pool of reusable objects; the pool is a generic object made by a provider with the type of the object, Get and Return
# hand the objects out and take them back (Get and Return are words of Ring, so they are called with callMethod)
load "pkg.ring"
pkgUse("objectpool",[["Microsoft.Extensions.ObjectPool","10.0.15"]],[["Microsoft.Extensions.ObjectPool.dll",["Microsoft.Extensions.ObjectPool"]]])
pkgImport("objectpool","Microsoft.Extensions.ObjectPool.dll","Microsoft.Extensions.ObjectPool")

oProvider = new DefaultObjectPoolProvider()
oPool = oProvider.callGeneric("Create",["System.Text.StringBuilder"],[])
oFirst = oPool.callMethod("Get",[])
oFirst.Append("hello")
dnAssert("an object from the pool",oFirst.ToString(),"hello")
oPool.callMethod("Return",[oFirst])
oSecond = oPool.callMethod("Get",[])
dnAssert("the object that was returned is handed out again",oSecond.Equals(oFirst),1)
dnAssert("the default policy does not reset it",oSecond.Length,5)
oThird = oPool.callMethod("Get",[])
dnAssert("a second object while the first is out is another one",oThird.Equals(oSecond),0)
oPool.callMethod("Return",[oSecond])
oPool.callMethod("Return",[oThird])

# the pool of StringBuilder that the extension makes resets the objects that come back
oBuilders = dnStatic("Microsoft.Extensions.ObjectPool.ObjectPoolProviderExtensions","CreateStringBuilderPool",[oProvider])
oBuilder = oBuilders.callMethod("Get",[])
oBuilder.Append("text")
oBuilders.callMethod("Return",[oBuilder])
dnAssert("a StringBuilder that came back is empty",oBuilders.callMethod("Get",[]).Length,0)

# a pool of lists
oLists = oProvider.callGeneric("Create",["System.Collections.Generic.List`1[[System.Int32]]"],[])
oList = oLists.callMethod("Get",[])
oList.Add(5)
dnAssert("a list from a pool",oList.Count,1)
oLists.callMethod("Return",[oList])
dnAssert("a list that was returned keeps its items (no reset policy)",oLists.callMethod("Get",[]).Count,1)

# a limit on the size of the pool
oSmall = dnNew("Microsoft.Extensions.ObjectPool.DefaultObjectPoolProvider",[])
oSmall.MaximumRetained = 1
dnAssert("the number of objects that are kept",oSmall.MaximumRetained,1)
dnTestSummary()
