using AutoMapper;

namespace PkgHelpers
{
	public class PersonProfile : Profile
	{
		public PersonProfile()
		{
			CreateMap<Person, PersonDto>()
				.ForMember(d => d.FullName, o => o.MapFrom(s => s.FirstName + " " + s.LastName))
				.ForMember(d => d.TagCount, o => o.MapFrom(s => s.Tags.Count));
		}
	}

	public static class Mapping
	{
		public static IMapper Create()
		{
			return new MapperConfiguration(c => c.AddProfile<PersonProfile>()).CreateMapper();
		}
	}
}
