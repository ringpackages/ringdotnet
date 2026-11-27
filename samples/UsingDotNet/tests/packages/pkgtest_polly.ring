# Polly: a resilience pipeline with a retry; a Ring function is the work, and a callback that fails twice then succeeds
load "pkg.ring"
pkgUse("polly",[["Polly.Core","8.9.1"]],[["Polly.Core.dll",["Polly","Polly.Retry"]]])
pkgImport("polly","Polly.Core.dll","Polly")
pkgImport("polly","Polly.Core.dll","Polly.Retry")
dnImport("System")

nAttempts = 0
oBuilder = new ResiliencePipelineBuilder()
oOptions = new RetryStrategyOptions()
oOptions.MaxRetryAttempts = 3
oDelay = new TimeSpan().FromMilliseconds(10)
oOptions.Delay = oDelay
dnAssert("an option is set",oOptions.MaxRetryAttempts,3)
oBuilder.AddRetry(oOptions)
oPipeline = oBuilder.Build()
dnAssert("the pipeline",classname(oPipeline),"resiliencepipeline")
oPipeline.Execute(dnCallback("pollyWork"))
dnAssert("the work was tried until it worked",nAttempts,3)

# more failures than retries: the error comes out
nAttempts = -10
try
	oPipeline.Execute(dnCallback("pollyWork"))
	dnAssert("too many failures are an error",1,0)
catch
	dnAssert("too many failures are an error",substr(cCatchError,"boom") > 0,1)
done
dnAssert("it was tried once and three times again",nAttempts,-6)

dnTestSummary()

func pollyWork aArgs

	nAttempts++
	if nAttempts < 3
		raise("boom")
	ok
	return nAttempts
