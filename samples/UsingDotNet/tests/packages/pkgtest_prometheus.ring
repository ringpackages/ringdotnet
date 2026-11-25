# prometheus-net: metrics (a counter, a gauge, a histogram) in a registry, written in the Prometheus text format to a memory stream
load "pkg.ring"
pkgUse("prometheus",[["prometheus-net","8.2.1"]],[["Prometheus.NetStandard.dll",["Prometheus"]]])
pkgImport("prometheus","Prometheus.NetStandard.dll","Prometheus")
using { "System.IO" }

oRegistry = dnStatic("Prometheus.Metrics","NewCustomRegistry",[])
oFactory = dnStatic("Prometheus.Metrics","WithCustomRegistry",[oRegistry])
oCounter = oFactory.callMethod("CreateCounter",["requests_total","Requests that were served"])
oCounter.callMethod("Inc",[])
oCounter.callMethod("Inc",[2])
dnAssert("a counter adds up",oCounter.Value,3)
oGauge = oFactory.callMethod("CreateGauge",["queue_size","Items that wait"])
oGauge.callMethod("Set",[10])
oGauge.callMethod("Dec",[4])
dnAssert("a gauge goes up and down",oGauge.Value,6)

# a counter with labels: each value of the label is its own counter
oRouteConfiguration = new CounterConfiguration()
oRouteConfiguration.LabelNames = ["route"]
oByRoute = oFactory.callMethod("CreateCounter",["hits_total","Hits by route",oRouteConfiguration])
oByRoute.callMethod("WithLabels",["/home"]).callMethod("Inc",[5])
oByRoute.callMethod("WithLabels",["/about"]).callMethod("Inc",[1])
dnAssert("the counter of one label value",oByRoute.callMethod("WithLabels",["/home"]).Value,5)

# a histogram with its own buckets
oLatencyConfiguration = new HistogramConfiguration()
oLatencyConfiguration.Buckets = [0.1,0.5,1]
oHistogram = oFactory.callMethod("CreateHistogram",["latency_seconds","Time of a request",oLatencyConfiguration])
oHistogram.callMethod("Observe",[0.05])
oHistogram.callMethod("Observe",[0.7])
dnAssert("the observations of a histogram",oHistogram.Count,2)
dnAssert("their sum",oHistogram.Sum,0.75)

# the text that a Prometheus server reads
oStream = new MemoryStream()
oRegistry.callMethod("CollectAndExportAsTextAsync",[oStream]).Wait(NULL)
oStream.Position = 0
cText = dnNew("System.IO.StreamReader",[oStream]).ReadToEnd()
dnAssert("the text has the counter",substr(cText,"requests_total 3") > 0,1)
dnAssert("it has the help of a metric",substr(cText,"# HELP queue_size Items that wait") > 0,1)
dnAssert("it has the type of a metric",substr(cText,"# TYPE queue_size gauge") > 0,1)
dnAssert("it has a label",substr(cText,'hits_total{route="/home"} 5') > 0,1)
dnAssert("it has a bucket of the histogram",substr(cText,'latency_seconds_bucket{le="0.5"} 1') > 0,1)
dnAssert("and the sum",substr(cText,"latency_seconds_sum 0.75") > 0,1)

# a name that is not valid is an error
cError = ""
try
	oFactory.callMethod("CreateCounter",["not a valid name","x"])
catch
	cError = cCatchError
done
dnAssert("an invalid metric name is an error",len(cError) > 0,1)
dnTestSummary()
