# SimpleInjector: a container with registrations (generic methods of the container itself; a type with several constructors is made by a Ring delegate), singletons, verification
load "pkg.ring"
pkgUse("simpleinjector",[["SimpleInjector","5.5.0"]],[["SimpleInjector.dll",["SimpleInjector"]]])
pkgImport("simpleinjector","SimpleInjector.dll","SimpleInjector")

oContainer = new SimpleInjectorContainer()
oContainer.callGeneric("Register",["System.Text.StringBuilder"],[dnCallback("makeBuilder")])
oList = dnNew("System.Collections.Generic.List`1[[System.String]]",[])
oList.Add("registered")
oContainer.callGeneric("RegisterInstance",["System.Collections.Generic.List`1[[System.String]]"],[oList])
oContainer.callGeneric("RegisterSingleton",["System.Uri"],[dnNew("System.Uri",["https://example.com/"])])
oContainer.Verify(NULL)

oOne = oContainer.callGeneric("GetInstance",["System.Text.StringBuilder"],[])
oTwo = oContainer.callGeneric("GetInstance",["System.Text.StringBuilder"],[])
dnAssert("a transient type is made each time",dnStatic("System.Object","ReferenceEquals",[oOne,oTwo]),0)

dnAssert("an instance is returned as it was registered",oContainer.callGeneric("GetInstance",["System.Collections.Generic.List`1[[System.String]]"],[]).Item(0),"registered")

oUri = oContainer.callGeneric("GetInstance",["System.Uri"],[])
dnAssert("a registered singleton",oUri.Host,"example.com")
dnAssert("is the same each time",dnStatic("System.Object","ReferenceEquals",[oUri,oContainer.callGeneric("GetInstance",["System.Uri"],[])]),1)

cError = ""
try
	oContainer.callGeneric("GetInstance",["System.Version"],[])
catch
	cError = cCatchError
done
dnAssert("an unregistered type raises an error",len(cError) > 0,1)

dnTestSummary()

# the delegate that makes a transient object: Ring code that SimpleInjector calls
func makeBuilder aArgs
	return dnNew("System.Text.StringBuilder",[])
