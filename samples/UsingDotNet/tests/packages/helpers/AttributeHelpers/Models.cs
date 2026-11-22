using System.Collections.Generic;
using CommandLine;
using MessagePack;

namespace AttributeHelpers
{
	[MessagePackObject]
	public class Person
	{
		[Key(0)] public string Name { get; set; }
		[Key(1)] public int Age { get; set; }
		[Key(2)] public List<string> Tags { get; set; } = new List<string>();
	}

	public class Options
	{
		[Option('v', "verbose", Required = false, HelpText = "More output")]
		public bool Verbose { get; set; }

		[Option('n', "name", Required = true, HelpText = "A name")]
		public string Name { get; set; }

		[Option('c', "count", Default = 1)]
		public int Count { get; set; }

		[Value(0, MetaName = "file")]
		public string File { get; set; }
	}
}
