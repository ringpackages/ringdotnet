# System.Threading.RateLimiting: a token bucket and a fixed window limiter made from options; leases and counts
load "pkg.ring"
pkgUse("ratelimiting",[["System.Threading.RateLimiting","9.0.0"]],[["System.Threading.RateLimiting.dll",["System.Threading.RateLimiting"]]])
pkgImport("ratelimiting","System.Threading.RateLimiting.dll","System.Threading.RateLimiting")

oOptions = new FixedWindowRateLimiterOptions()
oOptions.PermitLimit = 3
oOptions.Window = dnStatic("System.TimeSpan","FromSeconds",[60])
oOptions.QueueLimit = 0
oLimiter = new FixedWindowRateLimiter(oOptions)

nOk = 0
for i = 1 to 5
	oLease = oLimiter.AttemptAcquire(NULL)
	if oLease.IsAcquired
		nOk++
	ok
next
dnAssert("three of five were let through",nOk,3)
dnAssert("the statistics count them",oLimiter.GetStatistics().TotalSuccessfulLeases,3)
dnAssert("and the failed ones",oLimiter.GetStatistics().TotalFailedLeases,2)
oLimiter.Dispose()

oBucket = new TokenBucketRateLimiterOptions()
oBucket.TokenLimit = 2
oBucket.TokensPerPeriod = 1
oBucket.ReplenishmentPeriod = dnStatic("System.TimeSpan","FromMilliseconds",[200])
oBucket.QueueLimit = 0
oBucket.AutoReplenishment = 0
oTokens = new TokenBucketRateLimiter(oBucket)
dnAssert("a token",oTokens.AttemptAcquire(1).IsAcquired,1)
dnAssert("another token",oTokens.AttemptAcquire(1).IsAcquired,1)
dnAssert("none left",oTokens.AttemptAcquire(1).IsAcquired,0)
dnStatic("System.Threading.Thread","Sleep",[500])
oTokens.TryReplenish()
dnAssert("one back after a replenish",oTokens.AttemptAcquire(1).IsAcquired,1)
oTokens.Dispose()

dnTestSummary()
