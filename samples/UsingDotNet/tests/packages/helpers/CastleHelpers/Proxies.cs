using System;
using Castle.DynamicProxy;

namespace CastleHelpers
{
	public interface IGreeter
	{
		string Greet(string name);
		int Add(int a, int b);
		void Ping();
	}

	/* an interceptor that Ring controls: the handler is a callback of Ring that gets the name of the method and its arguments and gives the result */
	public class RingInterceptor : IInterceptor
	{
		private readonly Func<string, object[], object> handler;

		public RingInterceptor(Func<string, object[], object> handler) { this.handler = handler; }

		public void Intercept(IInvocation invocation)
		{
			object result = handler(invocation.Method.Name, invocation.Arguments);
			Type returnType = invocation.Method.ReturnType;
			/* Ring numbers are doubles: the result is converted to the type that the method returns */
			if (returnType != typeof(void)) invocation.ReturnValue = result == null ? null : Convert.ChangeType(result, returnType);
		}
	}

	public static class Proxies
	{
		public static IGreeter Greeter(Func<string, object[], object> handler)
		{
			return new ProxyGenerator().CreateInterfaceProxyWithoutTarget<IGreeter>(new RingInterceptor(handler));
		}
	}
}
