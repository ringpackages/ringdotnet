using System;
using FluentValidation;

namespace PkgHelpers
{
	/* the rules of a library are written in a class that derives from AbstractValidator<T>: Ring cannot derive from it, this class does */
	public class PersonValidator : AbstractValidator<Person>
	{
		public PersonValidator()
		{
			RuleFor(p => p.FirstName).NotEmpty().WithMessage("First name is required");
			RuleFor(p => p.Age).InclusiveBetween(0, 150).WithMessage("Age must be between 0 and 150");
			RuleFor(p => p.Email).EmailAddress().When(p => !string.IsNullOrEmpty(p.Email));
		}
	}

	/* the rules can also come from Ring: Rule(property, check, message) adds a rule whose check is a callback */
	public class RingRules : AbstractValidator<Person>
	{
		public void Rule(string property, Func<object, bool> check, string message)
		{
			var info = typeof(Person).GetProperty(property);
			RuleFor(p => info.GetValue(p)).Must(value => check(value)).WithMessage(message).OverridePropertyName(property);
		}
	}
}
