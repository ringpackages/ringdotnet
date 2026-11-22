# AutoFixture: test data made for any type; generic extension methods of an interface (Create<T>, CreateMany<T>)
load "pkg.ring"
pkgUse("autofixture",[["AutoFixture","4.18.1"]],[["AutoFixture.dll",["AutoFixture"]]])
pkgImport("autofixture","AutoFixture.dll","AutoFixture")

oFixture = new Fixture()
nNumber = oFixture.callGeneric("Create",["System.Int32"],[])
dnAssert("a number",nNumber > 0,1)

cText = oFixture.callGeneric("Create",["System.String"],[])
dnAssert("a text is made",len(cText) > 10,1)
cOther = oFixture.callGeneric("Create",["System.String"],[])
dnAssert("another text is different",cText != cOther,1)


aMany = oFixture.callGeneric("CreateMany",["System.Int32"],[]).toList()
dnAssert("three numbers by default",len(aMany),3)
aFive = oFixture.callGeneric("CreateMany",["System.Int32"],[5]).toList()
dnAssert("five numbers",len(aFive),5)

oGuid = oFixture.callGeneric("Create",["System.Guid"],[])
dnAssert("a guid",len(oGuid.ToString()),36)
oDate = oFixture.callGeneric("Create",["System.DateTime"],[])
dnAssert("a date",oDate.Year > 0,1)

dnTestSummary()
