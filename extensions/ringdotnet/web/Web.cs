/*
**  RingDotNet.Web - a Kestrel web server whose requests are handled by Ring code.
**
**  Kestrel runs on thread pool threads, but Ring code may only run on the Ring thread. So every request is put in a
**  queue and the Ring program takes them out with RingWebServer.Next() (see libraries/dotnetlib/web.ring).
*/

using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace RingDotNet
{
	/* One HTTP request waiting for a Ring handler */
	public sealed class RingRequest
	{
		public HttpContext Context { get; }
		public string Method { get; }
		public string Path { get; }
		public string QueryString { get; }
		public string Body { get; internal set; }
		public string ContentType { get; }
		internal TaskCompletionSource<bool> Done = new TaskCompletionSource<bool>(TaskCreationOptions.RunContinuationsAsynchronously);
		internal int Status = 200;
		internal string ResponseType = "text/plain";
		internal byte[] ResponseBytes = Array.Empty<byte>();
		internal Dictionary<string, string> ResponseHeaders = new Dictionary<string, string>();

		internal RingRequest(HttpContext context)
		{
			Context = context;
			Method = context.Request.Method;
			Path = context.Request.Path.Value;
			QueryString = context.Request.QueryString.Value;
			ContentType = context.Request.ContentType;
		}

		public string Query(string name) { return Context.Request.Query[name].ToString(); }
		public string Header(string name) { return Context.Request.Headers[name].ToString(); }
		public string Form(string name) { return Context.Request.HasFormContentType ? Context.Request.Form[name].ToString() : ""; }
		public string RouteValue(string name) { return Context.Request.RouteValues.TryGetValue(name, out object v) ? v?.ToString() : ""; }
		public void SetHeader(string name, string value) { ResponseHeaders[name] = value; }

		/* Send the response (text) and let the request finish */
		public void Respond(int status, string contentType, string body)
		{
			Status = status;
			ResponseType = contentType;
			ResponseBytes = Encoding.UTF8.GetBytes(body ?? "");
			Done.TrySetResult(true);
		}

		public void RespondBytes(int status, string contentType, byte[] body)
		{
			Status = status;
			ResponseType = contentType;
			ResponseBytes = body ?? Array.Empty<byte>();
			Done.TrySetResult(true);
		}
	}

	public sealed class RingWebServer
	{
		private WebApplication app;
		private readonly BlockingCollection<RingRequest> queue = new BlockingCollection<RingRequest>();
		public string Url { get; private set; }

		/* Start listening on a URL such as http://localhost:5000 (port 0 = any free port) */
		public static RingWebServer Start(string url)
		{
			RingWebServer server = new RingWebServer();
			/* the process has no entry assembly (the runtime is hosted by Ring): give the host its paths */
			WebApplicationBuilder builder = WebApplication.CreateSlimBuilder(new WebApplicationOptions
			{
				ContentRootPath = Directory.GetCurrentDirectory(),
				ApplicationName = "RingDotNet.Web"
			});
			builder.Logging.ClearProviders();
			server.app = builder.Build();
			server.app.Urls.Add(url);
			server.app.Run(server.Handle);
			server.app.StartAsync().GetAwaiter().GetResult();
			server.Url = server.app.Urls.Count > 0 ? new List<string>(server.app.Urls)[0] : url;
			return server;
		}

		private async Task Handle(HttpContext context)
		{
			RingRequest request = new RingRequest(context);
			using (StreamReader reader = new StreamReader(context.Request.Body))
			{
				request.Body = await reader.ReadToEndAsync();
			}
			queue.Add(request);
			await request.Done.Task;
			context.Response.StatusCode = request.Status;
			context.Response.ContentType = request.ResponseType.Contains("charset") ? request.ResponseType : request.ResponseType + "; charset=utf-8";
			foreach (KeyValuePair<string, string> h in request.ResponseHeaders)
			{
				context.Response.Headers[h.Key] = h.Value;
			}
			await context.Response.Body.WriteAsync(request.ResponseBytes, 0, request.ResponseBytes.Length);
		}

		/* The next request, or null after timeoutMs milliseconds */
		public RingRequest Next(int timeoutMs)
		{
			return queue.TryTake(out RingRequest request, timeoutMs) ? request : null;
		}

		public void Stop()
		{
			if (app != null)
			{
				app.StopAsync().GetAwaiter().GetResult();
				app.DisposeAsync().AsTask().GetAwaiter().GetResult();
				app = null;
			}
		}
	}
}
