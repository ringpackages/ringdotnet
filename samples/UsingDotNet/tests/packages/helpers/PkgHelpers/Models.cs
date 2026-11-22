using System.Collections.Generic;

namespace PkgHelpers
{
	public class Person
	{
		public string FirstName { get; set; } = "";
		public string LastName { get; set; } = "";
		public int Age { get; set; }
		public string Email { get; set; } = "";
		public List<string> Tags { get; set; } = new List<string>();
	}

	public class PersonDto
	{
		public string FullName { get; set; }
		public int Age { get; set; }
		public string Email { get; set; }
		public int TagCount { get; set; }
	}
}
