# Autofac: a container built from registrations of .NET types (generic extension methods), resolved by type
load "pkg.ring"
pkgUse("autofac",[["Autofac","8.2.0"]],[["Autofac.dll",["Autofac"]]])
pkgImport("autofac","Autofac.dll","Autofac")

oBuilder = new ContainerBuilder()
dnType("Autofac.RegistrationExtensions").callGeneric("RegisterType",["System.Text.StringBuilder"],[oBuilder])
oList = dnNew("System.Collections.Generic.List`1[[System.String]]",[])
oList.Add("registered")
dnType("Autofac.RegistrationExtensions").callMethod("RegisterInstance",[oBuilder,oList])
oContainer = oBuilder.Build(NULL)

oOne = dnType("Autofac.ResolutionExtensions").callGeneric("Resolve",["System.Text.StringBuilder"],[oContainer])
oTwo = dnType("Autofac.ResolutionExtensions").callGeneric("Resolve",["System.Text.StringBuilder"],[oContainer])
dnAssert("a type is made by the container",oOne.Length,0)
oOne.Append("x")
dnAssert("each resolve is a new object",oTwo.Length,0)

oSame = dnType("Autofac.ResolutionExtensions").callGeneric("Resolve",["System.Collections.Generic.List`1[[System.String]]"],[oContainer])
dnAssert("an instance is returned as it was registered",oSame.Item(0),"registered")

dnAssert("a registered type",dnType("Autofac.ResolutionExtensions").callGeneric("IsRegistered",["System.Text.StringBuilder"],[oContainer]),1)
dnAssert("an unregistered type",dnType("Autofac.ResolutionExtensions").callGeneric("IsRegistered",["System.Uri"],[oContainer]),0)

cError = ""
try
	dnType("Autofac.ResolutionExtensions").callGeneric("Resolve",["System.Uri"],[oContainer])
catch
	cError = cCatchError
done
dnAssert("an unregistered type cannot be resolved",len(cError) > 0,1)

oContainer.Dispose()
dnTestSummary()
