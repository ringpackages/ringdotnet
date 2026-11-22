using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.DependencyInjection;

namespace PkgHelpers
{
	public record Ping(string Text) : IRequest<string>;

	public class PingHandler : IRequestHandler<Ping, string>
	{
		public Task<string> Handle(Ping request, CancellationToken cancellationToken)
		{
			return Task.FromResult("pong: " + request.Text);
		}
	}

	public record Added(string Name) : INotification;

	public class AddedLog : INotificationHandler<Added>
	{
		public static readonly List<string> Seen = new List<string>();

		public Task Handle(Added notification, CancellationToken cancellationToken)
		{
			lock (Seen) Seen.Add(notification.Name);
			return Task.CompletedTask;
		}
	}

	public static class Mediation
	{
		public static IMediator Build()
		{
			var services = new ServiceCollection();
			services.AddMediatR(c => c.RegisterServicesFromAssemblyContaining<Ping>());
			return services.BuildServiceProvider().GetRequiredService<IMediator>();
		}
	}
}
