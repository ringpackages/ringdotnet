/*
	The .NET namespaces that tools/gendotnet.ring wraps in Ring classes.

	Each entry:
		:namespace   the .NET namespace (also the name used with dnImport("..."))
		:assemblies  assemblies that contain the namespace types (default: System.Private.CoreLib)
		:all         true = wrap every public class/struct of the namespace (default: false)
		:exclude     .NET type names that :all must skip
		:types       extra or explicit types: [.NET type name, (optional) Ring class name, (optional) init() parameters]
		             (closed generic types and nested types are listed here)
		:desktop     true when the namespace needs the Windows Desktop runtime (dnUseDesktop())
*/

aDotNetManifest = [

	[ :namespace = "System",
	  :types = [
		["System.Console"], ["System.Math"], ["System.Environment"], ["System.Random","Random",1],
		["System.Guid"], ["System.DateTime","DateTime",3], ["System.TimeSpan"]
	  ] ],

	[ :namespace = "System.Text",
	  :all = true ],

	[ :namespace = "System.IO",
	  :types = [ ["System.IO.File"], ["System.IO.Directory"], ["System.IO.Path"] ] ],

	[ :namespace = "System.Diagnostics",
	  :assemblies = ["System.Diagnostics.Process","System.Private.CoreLib"],
	  :types = [ ["System.Diagnostics.Stopwatch"] ] ],

	[ :namespace = "System.Net.Http",
	  :assemblies = ["System.Net.Http"],
	  :types = [ ["System.Net.Http.HttpClient"] ] ],

	[ :namespace = "System.Collections.Generic",
	  :types = [
		["System.Collections.Generic.List`1[[System.String]]","StringList",0],
		["System.Collections.Generic.List`1[[System.Double]]","NumberList",0],
		["System.Collections.Generic.List`1[[System.Object]]","ObjectList",0],
		["System.Collections.Generic.Dictionary`2[[System.String],[System.String]]","StringDictionary",0],
		["System.Collections.Generic.Dictionary`2[[System.String],[System.Double]]","NumberDictionary",0],
		["System.Collections.Generic.Dictionary`2[[System.String],[System.Object]]","ObjectDictionary",0],
		["System.Collections.Generic.HashSet`1[[System.String]]","StringSet",0],
		["System.Collections.Generic.Queue`1[[System.String]]","StringQueue",0],
		["System.Collections.Generic.Stack`1[[System.String]]","StringStack",0]
	  ] ],

	[ :namespace = "System.Collections.ObjectModel",
	  :types = [ ["System.Collections.ObjectModel.ObservableCollection`1[[System.String]]","ObservableStringList",0] ] ],

	[ :namespace = "System.Windows.Forms",
	  :desktop = true,
	  :types = [
		["System.Windows.Forms.Application"], ["System.Windows.Forms.MessageBox"],
		["System.Windows.Forms.Form","Form",0], ["System.Windows.Forms.Button","Button",0], ["System.Windows.Forms.Label","Label",0],
		["System.Windows.Forms.TextBox","TextBox",0], ["System.Windows.Forms.CheckBox","CheckBox",0], ["System.Windows.Forms.ListBox","ListBox",0],
		["System.Windows.Forms.Control+ControlCollection"]
	  ] ]

]
