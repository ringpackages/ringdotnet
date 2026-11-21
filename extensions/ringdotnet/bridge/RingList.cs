using System.Collections.Generic;

namespace RingDotNet
{
	/* A list that is a RESULT for Ring: the bridge sends it as a Ring list (Encode and NewHandle recognize the type by its name, so the data and web
	   assemblies, which are built without a reference to the bridge, use their own copy of this file). A List<object> that comes from anywhere else, such
	   as ObjectList or a method of a library that returns one, is an object like every other collection. */
	internal sealed class RingList : List<object>
	{
		public RingList() { }
		public RingList(int capacity) : base(capacity) { }
		public RingList(IEnumerable<object> items) : base(items) { }

		public static bool IsResult(object value)
		{
			return value is List<object> && value.GetType().Name == "RingList";
		}
	}

	internal static class RingListExtensions
	{
		public static RingList ToRingList(this IEnumerable<object> items)
		{
			return new RingList(items);
		}
	}
}
