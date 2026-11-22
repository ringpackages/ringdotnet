# Serilog: a logger that writes to a file (the sink is a package), levels, message templates, properties, and closing the logger
load "pkg.ring"
pkgUse("serilog",[["Serilog","4.4.0"],["Serilog.Sinks.File","7.0.0"]],[["Serilog.dll",["Serilog","Serilog.Events","Serilog.Configuration","Serilog.Core"]],["Serilog.Sinks.File.dll",[]]])
pkgImport("serilog","Serilog.dll","Serilog")
pkgImport("serilog","Serilog.dll","Serilog.Events")
pkgImport("serilog","Serilog.dll","Serilog.Configuration")
pkgImport("serilog","Serilog.dll","Serilog.Core")
dnImport("System.IO")

cLog = currentdir() + "/.cache/serilog-test.log"
if fexists(cLog)
	remove(cLog)
ok

oConfig = new LoggerConfiguration()
oConfig.MinimumLevel.Debug()
# the File sink is an extension method of another package (that DLL is only loaded): its static class takes the configuration as the first argument, by name
dnRequest("callnamed",[dnType("Serilog.FileLoggerConfigurationExtensions"),"File",[ ["sinkConfiguration",oConfig.WriteTo], ["path",cLog], ["outputTemplate","{Level:u3} {Message:lj}{NewLine}"] ]])
oLogger = oConfig.CreateLogger()
dnAssert("the logger",classname(oLogger),"logger")

oLogger.Information("started")
oLogger.Warning("low disk")
oLogger.Debug("a detail")
oLogger.Error("failed")
dnAssert("the minimum level is on",oLogger.IsEnabled(dnStatic("Serilog.Events.LogEventLevel","Debug",[])),1)
dnAssert("a level below the minimum is off",oLogger.IsEnabled(dnStatic("Serilog.Events.LogEventLevel","Verbose",[])),0)
oLogger.Dispose()

cText = read(cLog)
dnAssert("the information line",substr(cText,"INF started") > 0,1)
dnAssert("the warning line",substr(cText,"WRN low disk") > 0,1)
dnAssert("the debug line",substr(cText,"DBG a detail") > 0,1)
dnAssert("the error line",substr(cText,"ERR failed") > 0,1)
remove(cLog)

dnTestSummary()
