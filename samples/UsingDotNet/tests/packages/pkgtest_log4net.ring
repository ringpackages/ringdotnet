# log4net: a repository configured in code with a memory appender and a pattern layout; log events read back
load "pkg.ring"
pkgUse("log4net",[["log4net","3.6.0"]],[["log4net.dll",["log4net","log4net.Appender","log4net.Layout","log4net.Core"]]])
pkgImport("log4net","log4net.dll","log4net")
pkgImport("log4net","log4net.dll","log4net.Appender")
pkgImport("log4net","log4net.dll","log4net.Layout")
pkgImport("log4net","log4net.dll","log4net.Core")

oLayout = new PatternLayout().@New("%level|%logger|%message")
oLayout.ActivateOptions()
oAppender = new MemoryAppender()
oAppender.Layout = oLayout
oAppender.ActivateOptions()

oRepository = dnStatic("log4net.LogManager","CreateRepository",["ring-test-repo"])
dnType("log4net.Config.BasicConfigurator").callMethod("Configure",[oRepository,oAppender])
oLog = dnStatic("log4net.LogManager","GetLogger",["ring-test-repo","ring.test"])

oLog.Info("started")
oLog.Warn("careful")
oLog.Error("failed")
aEvents = oAppender.GetEvents().toList()
dnAssert("three events",len(aEvents),3)
dnAssert("the first message",aEvents[1].RenderedMessage,"started")
dnAssert("the second level",aEvents[2].Level.Name,"WARN")
dnAssert("the third logger",aEvents[3].LoggerName,"ring.test")
dnAssert("is info enabled",oLog.IsInfoEnabled,1)
dnAssert("is debug enabled",oLog.IsDebugEnabled,1)

oAppender.Clear()
dnAssert("cleared",len(oAppender.GetEvents().toList()),0)

dnTestSummary()
