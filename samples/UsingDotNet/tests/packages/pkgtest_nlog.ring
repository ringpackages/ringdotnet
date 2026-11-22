# NLog: a configuration made in code, a memory target, and log calls whose lines are read back
load "pkg.ring"
pkgUse("nlog",[["NLog","6.2.2"]],[["NLog.dll",["NLog","NLog.Config","NLog.Targets"]]])
pkgImport("nlog","NLog.dll","NLog")
pkgImport("nlog","NLog.dll","NLog.Config")
pkgImport("nlog","NLog.dll","NLog.Targets")

oConfig = new LoggingConfiguration()
oMemory = new MemoryTarget()
oMemory.Layout = "${level:uppercase=true}|${logger}|${message}"
oConfig.AddRuleForAllLevels(oMemory)
oFactory = new LogFactory()
oFactory.Configuration = oConfig
oLogger = oFactory.GetLogger("ring.test")

oLogger.Info("started")
oLogger.Warn("careful")
oLogger.Error("failed")
oFactory.Flush(NULL)

aLogs = oMemory.Logs.toList()
dnAssert("three lines",len(aLogs),3)
dnAssert("an info line",aLogs[1],"INFO|ring.test|started")
dnAssert("a warning line",aLogs[2],"WARN|ring.test|careful")
dnAssert("an error line",aLogs[3],"ERROR|ring.test|failed")

# a message with text that is not English
oLogger.Info("مرحبا 💍")
dnAssert("text that is not English",oMemory.Logs.toList()[4],"INFO|ring.test|مرحبا 💍")

# the minimum level of a rule
oConfig2 = new LoggingConfiguration()
oMemory2 = new MemoryTarget()
oMemory2.Layout = "${message}"
oConfig2.AddRule([ :minLevel = dnStatic("NLog.LogLevel","Warn",[]), :maxLevel = dnStatic("NLog.LogLevel","Fatal",[]), :target = oMemory2 ])
oFactory2 = new LogFactory()
oFactory2.Configuration = oConfig2
oLog2 = oFactory2.GetLogger("x")
oLog2.Info("hidden")
oLog2.Warn("shown")
dnAssert("a minimum level",len(oMemory2.Logs.toList()),1)

oFactory.Dispose()
oFactory2.Dispose()
dnTestSummary()
