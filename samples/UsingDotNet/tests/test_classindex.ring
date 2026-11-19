# The index of the generated classes (generated/classindex.ring: .NET type --> namespace) is complete.
# It lets the library import a namespace when an object of one of its types is returned. A generator run that writes only some of the
# namespaces must not replace it (it is written by a run for every namespace).
load "dotnet.ring"

dnBuildIndexMap()
dnAssert("the index has the classes of every namespace",len(aDotNetClassIndex) > 4000,True)
dnAssert("a class of the framework",aDotNetIndexMap["System.IO.FileInfo"],"System.IO")
dnAssert("a class of Windows Forms",aDotNetIndexMap["System.Windows.Forms.Form"],"System.Windows.Forms")
dnAssert("a class of WPF",aDotNetIndexMap["System.Windows.Controls.Button"],"System.Windows.Controls")
dnAssert("a class of ASP.NET Core",aDotNetIndexMap["Microsoft.AspNetCore.Http.HttpContext"],"Microsoft.AspNetCore.Http")
dnAssert("a class of Entity Framework Core",aDotNetIndexMap["Microsoft.EntityFrameworkCore.DbContext"],"Microsoft.EntityFrameworkCore")

nFail = dnTestSummary()
