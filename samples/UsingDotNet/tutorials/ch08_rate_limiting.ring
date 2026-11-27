# rate limiting - a token bucket, a concurrency limiter with leases, statistics, and one limiter for each client
load "dotnet.ring"

using {
	"System.Threading.RateLimiting"
	"System"
	"System.Threading"
	"RingDotNet.Web"                  # System.Threading.RateLimiting is part of the ASP.NET Core runtime: this line starts it
}


func main

	# A rate limiter protects a service from too many requests: a client that asks 1000 times a second, a script with a bug, an attack.
	# It says YES or NO to each request at once (AttemptAcquire), without waiting. The program decides what NO means (an error 429
	# "Too Many Requests", a pause, a message).

	# 1. TOKEN BUCKET: a bucket that holds up to 3 tokens. Each request takes one. Tokens come back one at a time at a fixed pace.
	#    A client can make a short burst (3 requests at once) but not more than the pace in the long run.
	#    AutoReplenishment is off here: the program adds the tokens itself with TryReplenish, which adds one only when the period (here
	#    100 ms) has passed since the last time. (With AutoReplenishment on, a timer of the limiter does it.)
	oBucket = makeBucket(3,100)
	? "1. a bucket of 3 tokens, 5 requests at once:"
	for nRequest = 1 to 5
		oLease = oBucket.AttemptAcquire(1)
		? "   request " + nRequest + ": " + answer(oLease.IsAcquired)
	next
	new Thread().Sleep(300)      # more than the period of 100 ms
	? "   after the period, TryReplenish adds a token: " + oBucket.TryReplenish()
	? "   the next request: " + answer(oBucket.AttemptAcquire(1).IsAcquired) + "   (how many tokens come back depends on how long the pause was)"

	# 2. Statistics: how many tokens are left, how many requests were granted and how many refused
	oStatistics = oBucket.GetStatistics()
	? nl + "2. tokens left (not more than the bucket holds): " + (oStatistics.CurrentAvailablePermits <= 3) + ", granted in total: " + oStatistics.TotalSuccessfulLeases + ", refused in total: " + oStatistics.TotalFailedLeases

	# 3. CONCURRENCY LIMITER: at most 2 requests are being handled at the same time. A request gets a LEASE and gives it back when it is
	#    finished (Dispose). While two leases are out, the third request is refused. This protects a slow resource (a database connection).
	oConcurrency = new ConcurrencyLimiter(makeConcurrencyOptions(2))
	oLeaseA = oConcurrency.AttemptAcquire(1)
	oLeaseB = oConcurrency.AttemptAcquire(1)
	oLeaseC = oConcurrency.AttemptAcquire(1)
	? nl + "3. three requests at once, 2 allowed: " + answer(oLeaseA.IsAcquired) + ", " + answer(oLeaseB.IsAcquired) + ", " + answer(oLeaseC.IsAcquired)
	oLeaseA.Dispose()                  # the first request is finished: its place is free
	oLeaseD = oConcurrency.AttemptAcquire(1)
	? "   after the first one finished, a new request: " + answer(oLeaseD.IsAcquired)

	# 4. Why a request was refused: a refused lease can carry the time to wait (the metadata RETRY_AFTER). The answer to the client
	#    ("try again in 5 seconds") is better than only "no".
	oSlow = makeBucket(1,5000)
	oSlow.AttemptAcquire(1)
	oRefused = oSlow.AttemptAcquire(1)
	aRetry = oRefused.TryGetMetadata("RETRY_AFTER")
	? nl + "4. the bucket is empty: refused, a retry time is offered: " + aRetry[1]
	if aRetry[1]
		? "   try again after about " + floor(aRetry[2].TotalSeconds + 0.5) + " seconds"
	ok

	# 5. One limiter for each client: a Ring list keeps a bucket for every client name (an IP address, a user id), so that one noisy
	#    client does not use up the allowance of the others.
	aClients = []
	for cClient in ["10.0.0.1","10.0.0.2"]
		aClients + [cClient,makeBucket(2,5000)]
	next
	? nl + "5. two clients with 2 requests each; the first client asks 4 times, the second twice:"
	? "   10.0.0.1: " + asks(aClients[1][2],4)
	? "   10.0.0.2: " + asks(aClients[2][2],2)

func makeBucket nTokens,nPeriodMs

	oOptions = new TokenBucketRateLimiterOptions
	oOptions.TokenLimit = nTokens
	oOptions.TokensPerPeriod = 1
	oPeriod = new TimeSpan().FromMilliseconds(nPeriodMs)
	oOptions.ReplenishmentPeriod = oPeriod
	oOptions.AutoReplenishment = False
	oOptions.QueueLimit = 0
	return new TokenBucketRateLimiter(oOptions)

func makeConcurrencyOptions nLimit

	oOptions = new ConcurrencyLimiterOptions
	oOptions.PermitLimit = nLimit
	oOptions.QueueLimit = 0
	return oOptions

# the answers of one client for n requests, as a text of yes and no
func asks oBucket,nCount

	cText = ""
	for i = 1 to nCount
		cText += answer(oBucket.AttemptAcquire(1).IsAcquired) + " "
	next
	return cText

func answer lYes

	if lYes
		return "allowed"
	ok
	return "refused"
