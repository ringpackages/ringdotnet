using System;
using System.Collections.Concurrent;
using System.Threading.Tasks;
using Quartz;

namespace QuartzHelpers
{
	/* a job that records its runs; the runs happen on threads of the thread pool, not on the thread of Ring */
	public class CountingJob : IJob
	{
		public static readonly ConcurrentQueue<string> Runs = new ConcurrentQueue<string>();
		public static int ThreadsSeen;
		/* a callback of Ring that the job calls on its own thread (an experiment: Ring handles it on the Ring thread when a call is running) */
		public static Action<string> Handler;

		public Task Execute(IJobExecutionContext context)
		{
			Runs.Enqueue(context.JobDetail.Key.Name + ":" + context.JobDetail.JobDataMap.GetString("label"));
			Handler?.Invoke(context.JobDetail.Key.Name);
			return Task.CompletedTask;
		}
	}

	public static class Scheduling
	{
		public static IScheduler Create()
		{
			return new Quartz.Impl.StdSchedulerFactory().GetScheduler().GetAwaiter().GetResult();
		}

		public static IJobDetail Job(string name, string label)
		{
			return JobBuilder.Create<CountingJob>().WithIdentity(name).UsingJobData("label", label).Build();
		}

		/* a trigger that fires now and then count - 1 more times, every intervalMs milliseconds */
		public static ITrigger Repeating(string name, int count, int intervalMs)
		{
			return TriggerBuilder.Create().WithIdentity(name).StartNow()
				.WithSimpleSchedule(s => s.WithInterval(TimeSpan.FromMilliseconds(intervalMs)).WithRepeatCount(count - 1)).Build();
		}

		/* a trigger that fires in an hour: the job is still there to be paused and deleted */
		public static ITrigger InAnHour(string name)
		{
			return TriggerBuilder.Create().WithIdentity(name).StartAt(DateTimeOffset.Now.AddHours(1)).Build();
		}

		public static void Clear() { string ignored; while (CountingJob.Runs.TryDequeue(out ignored)) { } }
	}
}
