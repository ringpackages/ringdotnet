# dnImportFrom: a loader of a wrapped assembly asks for another namespace of the same assembly (dnImport), and it is found in the folder
# that the program gave to dnImportFrom (Newtonsoft.Json.Linq needs Newtonsoft.Json, for example)
load "dotnet.ring"

using { "System.IO" }

nTestSecondLoaded = 0          # globals: the loaded files set them
nTestFirstLoaded = 0
nTestLazyLoaded = 0

func main

	cFolder = currentdir() + "/import_folder_tmp/"
	new Directory().CreateDirectory(cFolder)
	write(cFolder + "Test.Second.ring","nTestSecondLoaded = 1" + nl)
	write(cFolder + "Test.First.ring",'dnImport("Test.Second")' + nl + "nTestFirstLoaded = 1" + nl)
	# the index of the folder: a type of a namespace that was not imported loads that namespace from the folder when an object of it comes back
	write(cFolder + "classindex.ring",'aDotNetClassIndex + ["Test.Lazy.Thing","Test.Lazy"]' + nl)
	write(cFolder + "Test.Lazy.ring","nTestLazyLoaded = 1" + nl)
	dnImportFrom(cFolder,"Test.First")
	dnAssert("the namespace that the first one needs is loaded from the same folder",nTestSecondLoaded,1)
	dnAssert("the first namespace is loaded",nTestFirstLoaded,1)
	dnAssert("a namespace of the index is not loaded before it is needed",nTestLazyLoaded,0)
	dnFindFactory("Test.Lazy.Thing")
	dnAssert("an object of a type in the index loads its namespace from the folder",nTestLazyLoaded,1)
	nTestSecondLoaded = 0
	dnImportFrom(cFolder,"Test.Second")
	dnAssert("a namespace that was loaded is not loaded again",nTestSecondLoaded,0)
	try
		dnImport("Test.Missing")
		dnAssert("a namespace that is nowhere raises an error",0,1)
	catch
		dnAssert("a namespace that is nowhere raises an error",1,1)
	done
	new Directory().Delete([ :path = cFolder, :recursive = true ])
	dnTestSummary()
