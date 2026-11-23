# Quartz: a scheduler with jobs (a helper project has the job class: Ring cannot implement IJob); Ring schedules, waits, reads what the jobs did on other threads, pauses and stops
load "pkg.ring"
pkgUseProject("quartz","helpers/QuartzHelpers",[["Quartz.dll",["Quartz"]],["QuartzHelpers.dll",["QuartzHelpers"]]])
pkgImport("quartz","Quartz.dll","Quartz")
pkgImport("quartz","QuartzHelpers.dll","QuartzHelpers")
dnImport("System.Threading")

nCalled = 0
dnStatic("QuartzHelpers.Scheduling","Clear",[])
oScheduler = dnStatic("QuartzHelpers.Scheduling","Create",[])
dnAssert("a scheduler",oScheduler.SchedulerName != "",1)
dnAssert("it is not started yet",oScheduler.IsStarted,0)
oScheduler.Start(NULL).Wait(NULL)
dnAssert("it is started",oScheduler.IsStarted,1)

# a job that runs three times, 100 ms apart
oJob = dnStatic("QuartzHelpers.Scheduling","Job",["counting","from Ring"])
oTrigger = dnStatic("QuartzHelpers.Scheduling","Repeating",["every100",3,100])
oScheduler.ScheduleJob([ :jobDetail = oJob, :trigger = oTrigger ]).Wait(NULL)
dnAssert("the job is known",oScheduler.CheckExists([ :jobKey = oJob.Key ]).Result,1)

# wait on the Ring thread while the jobs run on other threads
nWaited = 0
while nWaited < 40 and dnType("QuartzHelpers.CountingJob").getProp("Runs").Count < 3
	dnStatic("System.Threading.Thread","Sleep",[100])
	nWaited++
end
oRuns = dnType("QuartzHelpers.CountingJob").getProp("Runs")
dnAssert("the job ran three times",oRuns.Count,3)
dnAssert("a run has the name and the data of the job",oRuns.ToArray().toList()[1],"counting:from Ring")

# no more runs after the third
dnStatic("System.Threading.Thread","Sleep",[300])
dnAssert("the job did not run again",oRuns.Count,3)

# pause and resume all triggers
oScheduler.PauseAll(NULL).Wait(NULL)
oScheduler.ResumeAll(NULL).Wait(NULL)
dnAssert("the scheduler runs after the pause",oScheduler.IsStarted and not oScheduler.InStandbyMode,1)

# a job that has no trigger left (and is not durable) is removed by the scheduler
dnAssert("the finished job was removed by the scheduler",oScheduler.CheckExists([ :jobKey = oJob.Key ]).Result,0)

# a job that is deleted before it runs: a trigger that starts in an hour
oLater = dnStatic("QuartzHelpers.Scheduling","Job",["later","never"])
oHour = dnStatic("QuartzHelpers.Scheduling","InAnHour",["in-an-hour"])
oScheduler.ScheduleJob([ :jobDetail = oLater, :trigger = oHour ]).Wait(NULL)
oScheduler.PauseJob([ :jobKey = oLater.Key ]).Wait(NULL)
dnAssert("a job that is paused is known",oScheduler.CheckExists([ :jobKey = oLater.Key ]).Result,1)
dnAssert("a job can be deleted",oScheduler.DeleteJob([ :jobKey = oLater.Key ]).Result,1)

# a Ring callback that a job calls on its own thread is ignored with a message (Ring callbacks run on the Ring thread, during a call): the job and the scheduler go on
nCalled = 0
dnType("QuartzHelpers.CountingJob").setProp("Handler",dnCallback("onJobThread"))
dnStatic("QuartzHelpers.Scheduling","Clear",[])
oCallbackJob = dnStatic("QuartzHelpers.Scheduling","Job",["callback","c"])
oScheduler.ScheduleJob([ :jobDetail = oCallbackJob, :trigger = dnStatic("QuartzHelpers.Scheduling","Repeating",["callback-trigger",2,100]) ]).Wait(NULL)
dnStatic("System.Threading.Thread","Sleep",[700])
dnAssert("the job ran although its callback was ignored",dnType("QuartzHelpers.CountingJob").getProp("Runs").Count,2)
dnAssert("the callback of Ring did not run on the thread of the job",nCalled,0)
dnType("QuartzHelpers.CountingJob").setProp("Handler",dnNull())

oScheduler.Shutdown(NULL).Wait(NULL)
dnAssert("the scheduler is shut down",oScheduler.IsShutdown,1)

dnTestSummary()

func onJobThread aArgs

	nCalled++
