# caching - MemoryCache, absolute and sliding expiration, remove and update, and when a cache is a bad idea
load "dotnet.ring"
using {
	"System"
	"Microsoft.Extensions.Caching.Memory"
}

nRuns = 0

func main
	# A cache keeps the result of slow work (a database query, a web request, a big calculation) for a while, so the next request
	# gets it at once. MemoryCache keeps the values in memory, with a key for each one and rules for when a value must go.
	oCache = new MemoryCache(new MemoryCacheOptions())

	# 1. Set stores a value under a key. TryGetValue answers [ found, value ].
	cacheSet(oCache,"user:1","Ann",NULL)
	aResult = oCache.TryGetValue("user:1")
	? "1. found: " + aResult[1] + ", value: " + aResult[2]
	? "   a key that was never stored: found = " + oCache.TryGetValue("user:99")[1]
	? "   entries in the cache: " + oCache.Count

	# 2. Absolute expiration: the value lives for a fixed time after it was stored. After that it is gone, even if it was used.
	oOptions = new MemoryCacheEntryOptions()
	oOptions.AbsoluteExpirationRelativeToNow = dnStatic("System.TimeSpan","FromMilliseconds",[500])
	cacheSet(oCache,"price",9.99,oOptions)
	? nl + "2. right after storing, the price is there:  " + oCache.TryGetValue("price")[1]
	sleepMs(900)
	? "   after 900 ms (the limit was 500 ms):   " + oCache.TryGetValue("price")[1]

	# 3. Sliding expiration: the time starts again every time the value is READ. A value that is used often stays, one that is
	#    not used goes. (Good for sessions and for caches of things that are used in bursts.)
	oSliding = new MemoryCacheEntryOptions()
	oSliding.SlidingExpiration = dnStatic("System.TimeSpan","FromMilliseconds",[1000])
	cacheSet(oCache,"session","token-123",oSliding)
	cResult = ""
	for i = 1 to 4
		sleepMs(300)                                  # 300 ms each time: less than 1000, so every read renews the time
		cResult += "" + oCache.TryGetValue("session")[1] + " "
	next
	? nl + "3. read every 300 ms with sliding time of 1000 ms: " + cResult + "(it stays: 1 = found)"
	sleepMs(1500)
	? "   not read for 1500 ms: found = " + oCache.TryGetValue("session")[1]

	# 4. GetOrCreate: "give me the value, and make it if it is missing". The function that makes the value is the slow work: it runs
	#    only on the first request (a Ring function that .NET calls during this call).
	cFirst = oCache.GetOrCreate([ :key = "report", :factory = dnCallback("slowReport") ])
	cSecond = oCache.GetOrCreate([ :key = "report", :factory = dnCallback("slowReport") ])
	? nl + "4. the report was made " + nRuns + " time(s) for two requests: " + cFirst + " / " + cSecond

	# 5. Remove and Clear (Compact removes a part): a value that changed in the database must leave the cache, or the old one is served
	oCache.Remove("user:1")
	? nl + "5. after Remove, user:1 is found: " + oCache.TryGetValue("user:1")[1]
	oCache.Clear()
	? "   after Clear, entries: " + oCache.Count

	# 6. A cache does not know when the real data changes. Two rules: never cache what must be exact (a bank balance), and give every
	#    value an expiration, so that the worst case is a value that is a few seconds old.
	oCache.Dispose()

func sleepMs nMilliseconds
	dnStatic("System.Threading.Thread","Sleep",[nMilliseconds])

func slowReport aArguments
	nRuns++                         # (nRuns is a global variable of the program)
	return "report #" + nRuns

# Set has two forms: with and without the options of the entry
func cacheSet oCache,cKey,xValue,oOptions
	if isNull(oOptions)
		return oCache.Set([ :key = cKey, :value = xValue ])
	ok
	return oCache.Set([ :key = cKey, :value = xValue, :options = oOptions ])
