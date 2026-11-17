/*
	The .NET namespaces that tools/gendotnet.ring wraps in Ring classes.

	Each entry:
		:namespace   the .NET namespace (also the name used with dnImport("..."))
		:assemblies  assemblies that contain the namespace types (default: System.Private.CoreLib)
		:all         true = wrap every public class/struct of the namespace (default: false)
		:exclude     .NET type names that :all must skip
		:types       extra or explicit types: [.NET type name, (optional) Ring class name, (optional) init() parameters]
		             (closed generic types and nested types are listed here)
		:prefer      ["Namespace.Type.Method=arity", ...]: the overload that gets the plain method name (the others are Name_N)
		:extra       Ring files (relative to the generated folder) that the namespace loader also loads
		:desktop     true when the namespace needs the Windows Desktop runtime (dnUseDesktop())
*/

aDotNetManifest = [

	[ :namespace = "System",
	  :assemblies = ["System.Private.CoreLib","System.Private.Uri","System.Console"],
	  :all = true,
	  :types = [ ["System.Random","Random",1], ["System.DateTime","DateTime",3], ["System.String","String",0], ["System.Guid","Guid",0], ["System.Version","Version",1], ["System.DateOnly","DateOnly",3] ] ],

	[ :namespace = "System.Text",
	  :all = true,
	  :types = [ ["System.Text.StringBuilder","StringBuilder",1] ] ],

	[ :namespace = "System.IO",
	  :assemblies = ["System.Private.CoreLib","System.IO.FileSystem.Watcher","System.Runtime"],
	  :all = true ],

	[ :namespace = "System.IO.Compression",
	  :assemblies = ["System.IO.Compression","System.IO.Compression.ZipFile","System.IO.Compression.Brotli"],
	  :all = true ],

	[ :namespace = "System.Text.RegularExpressions",
	  :assemblies = ["System.Text.RegularExpressions"],
	  :all = true ],

	[ :namespace = "System.Diagnostics",
	  :assemblies = ["System.Diagnostics.Process","System.Private.CoreLib"],
	  :types = [ ["System.Diagnostics.Stopwatch"] ] ],

	[ :namespace = "System.Net.Http",
	  :assemblies = ["System.Net.Http"],
	  :types = [ ["System.Net.Http.HttpClient"] ] ],

	[ :namespace = "System.Linq",
	  :assemblies = ["System.Linq"],
	  :all = true,
	  :extra = ["../linq.ring"] ],

	[ :namespace = "System.Collections",
	  :assemblies = ["System.Private.CoreLib","System.Collections","System.Collections.NonGeneric"],
	  :all = true ],

	[ :namespace = "System.Collections.Specialized",
	  :assemblies = ["System.Collections.Specialized","System.Collections.NonGeneric","System.Collections"],
	  :all = true,
	  :prefer = ["System.Collections.Specialized.NameValueCollection.Add=2","System.Collections.Specialized.NameValueCollection.Set=2"] ],

	[ :namespace = "System.Collections.Generic",
	  :types = [
		["System.Collections.Generic.List`1[[System.String]]","StringList",0],
		["System.Collections.Generic.List`1[[System.Double]]","NumberList",0],
		["System.Collections.Generic.List`1[[System.Int32]]","IntList",0],
		["System.Collections.Generic.List`1[[System.Object]]","ObjectList",0],
		["System.Collections.Generic.Dictionary`2[[System.String],[System.String]]","StringDictionary",0],
		["System.Collections.Generic.Dictionary`2[[System.String],[System.Double]]","NumberDictionary",0],
		["System.Collections.Generic.Dictionary`2[[System.String],[System.Object]]","ObjectDictionary",0],
		["System.Collections.Generic.Dictionary`2[[System.Double],[System.Object]]","NumberKeyDictionary",0],
		["System.Collections.Generic.SortedDictionary`2[[System.String],[System.String]]","SortedStringDictionary",0],
		["System.Collections.Generic.SortedDictionary`2[[System.String],[System.Object]]","SortedObjectDictionary",0],
		["System.Collections.Generic.SortedList`2[[System.String],[System.Object]]","SortedObjectList",0],
		["System.Collections.Generic.HashSet`1[[System.String]]","StringSet",0],
		["System.Collections.Generic.HashSet`1[[System.Double]]","NumberSet",0],
		["System.Collections.Generic.SortedSet`1[[System.String]]","SortedStringSet",0],
		["System.Collections.Generic.SortedSet`1[[System.Double]]","SortedNumberSet",0],
		["System.Collections.Generic.Queue`1[[System.String]]","StringQueue",0],
		["System.Collections.Generic.Queue`1[[System.Object]]","ObjectQueue",0],
		["System.Collections.Generic.Stack`1[[System.String]]","StringStack",0],
		["System.Collections.Generic.Stack`1[[System.Object]]","ObjectStack",0],
		["System.Collections.Generic.LinkedList`1[[System.String]]","StringLinkedList",0],
		["System.Collections.Generic.LinkedList`1[[System.Object]]","ObjectLinkedList",0],
		["System.Collections.Generic.PriorityQueue`2[[System.String],[System.Double]]","StringPriorityQueue",0],
		["System.Collections.Generic.KeyValuePair`2[[System.String],[System.String]]","StringPair"],
		["System.Collections.Generic.KeyValuePair`2[[System.String],[System.Object]]","ObjectPair"],
		["System.Collections.Generic.KeyValuePair`2[[System.String],[System.Double]]","NumberPair"]
	  ] ],

	[ :namespace = "System.Collections.ObjectModel",
	  :types = [ ["System.Collections.ObjectModel.ObservableCollection`1[[System.String]]","ObservableStringList",0],
		["System.Collections.ObjectModel.ObservableCollection`1[[System.Object]]","ObservableObjectList",0],
		["System.Collections.ObjectModel.ReadOnlyCollection`1[[System.String]]","ReadOnlyStringList"],
		["System.Collections.ObjectModel.Collection`1[[System.String]]","StringCollectionList",0] ] ],

	[ :namespace = "System.Windows.Forms",
	  :desktop = true,
	  :types = [
		["System.Windows.Forms.Application"], ["System.Windows.Forms.MessageBox"],
		["System.Windows.Forms.Form","Form",0], ["System.Windows.Forms.Button","Button",0], ["System.Windows.Forms.Label","Label",0],
		["System.Windows.Forms.TextBox","TextBox",0], ["System.Windows.Forms.CheckBox","CheckBox",0], ["System.Windows.Forms.ListBox","ListBox",0],
		["System.Windows.Forms.Control+ControlCollection"]
	  ] ]

]
