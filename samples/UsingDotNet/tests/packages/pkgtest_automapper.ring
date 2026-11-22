# AutoMapper: the profile (the mapping rules) is written in .NET (a helper project); Ring builds the mapper, maps objects and lists with the type arguments
load "pkg.ring"
pkgUseProject("automapper","helpers/PkgHelpers",[["PkgHelpers.dll",["PkgHelpers"]],["AutoMapper.dll",["AutoMapper"]]])
pkgImport("automapper","PkgHelpers.dll","PkgHelpers")
pkgImport("automapper","AutoMapper.dll","AutoMapper")
dnImport("System.Collections.Generic")

oMapper = dnStatic("PkgHelpers.Mapping","Create",[])
oAnn = new Person()
oAnn.FirstName = "Ann"
oAnn.LastName = "Lee"
oAnn.Age = 31
oAnn.Email = "ann@example.org"
oAnn.Tags.Add("a")
oAnn.Tags.Add("b")

# Map<PersonDto>(person): the destination type is the type argument
oDto = oMapper.Map([ :typeArguments = ["PkgHelpers.PersonDto"], :source = oAnn ])
dnAssert("a destination object",classname(oDto),"persondto")
dnAssert("a member with the same name",oDto.Age,31)
dnAssert("a member with the same name, a text",oDto.Email,"ann@example.org")
dnAssert("a member mapped by a rule (first and last name)",oDto.FullName,"Ann Lee")
dnAssert("a member mapped by a rule (the number of tags)",oDto.TagCount,2)

# a list of objects to a list of objects
oBo = new Person()
oBo.FirstName = "Bo"
oBo.LastName = "Kim"
oBo.Age = 25
oPeople = dnNewGeneric("System.Collections.Generic.List",["PkgHelpers.Person"],[])
oPeople.callMethod("Add",[oAnn])
oPeople.callMethod("Add",[oBo])
oDtos = oMapper.Map([ :typeArguments = ["System.Collections.Generic.List`1[[PkgHelpers.PersonDto, PkgHelpers]]"], :source = oPeople ])
dnAssert("a list is mapped item by item",oDtos.Count,2)
dnAssert("the second item",oDtos.Item(1).FullName,"Bo Kim")

# the mapper changes an existing object
oTarget = new PersonDto()
oTarget.Email = "kept"
oMapper.Map([ :source = oBo, :destination = oTarget ])
dnAssert("an existing object is filled",oTarget.FullName,"Bo Kim")

# a type that has no map is an error
try
	oMapper.Map([ :typeArguments = ["System.Uri"], :source = oAnn ])
	dnAssert("a missing map is an error",1,0)
catch
	dnAssert("a missing map is an error",substr(cCatchError,"Missing type map") > 0 or substr(cCatchError,"AutoMapper") > 0,1)
done

dnTestSummary()
