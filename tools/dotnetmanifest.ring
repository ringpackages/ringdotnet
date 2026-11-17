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
		:uses        namespaces to import together with this one (their classes are returned by its methods)
		:extra       Ring files (relative to the generated folder) that the namespace loader also loads
		:prefix      prefix of the class names that clash with a class of another namespace (default: the last part of the namespace)
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
	  :uses = ["System.IO"],
	  :assemblies = ["System.IO.Compression","System.IO.Compression.ZipFile","System.IO.Compression.Brotli"],
	  :all = true ],

	[ :namespace = "System.Text.RegularExpressions",
	  :assemblies = ["System.Text.RegularExpressions"],
	  :all = true ],



	[ :namespace = "System.Linq",
	  :uses = ["System.Collections.Generic"],
	  :assemblies = ["System.Linq"],
	  :all = true,
	  :extra = ["../linq.ring"] ],

	[ :namespace = "System.Threading",
	  :uses = ["System.Threading.Tasks"],
	  :assemblies = ["System.Private.CoreLib","System.Threading","System.Threading.Thread","System.Threading.ThreadPool"],
	  :all = true,
	  :types = [ ["System.Threading.Thread","Thread",0] ] ],

	[ :namespace = "System.Threading.Tasks",
	  :uses = ["System.Threading"],
	  :assemblies = ["System.Private.CoreLib","System.Threading.Tasks.Parallel","System.Threading.Tasks"],
	  :all = true,
	  :types = [
		["System.Threading.Tasks.Task","Task",0],
		["System.Threading.Tasks.Task`1[[System.String]]","StringTask"],
		["System.Threading.Tasks.Task`1[[System.Object]]","ObjectTask"],
		["System.Threading.Tasks.Task`1[[System.Double]]","NumberTask"],
		["System.Threading.Tasks.Task`1[[System.Int32]]","IntTask"],
		["System.Threading.Tasks.Task`1[[System.Boolean]]","BoolTask"],
		["System.Threading.Tasks.Task`1[[System.Byte[]]]","BytesTask"]
	  ] ],

	[ :namespace = "System.Net",
	  :uses = ["System.IO","System.Collections.Specialized","System.Security.Cryptography"],
	  :assemblies = ["System.Net.Primitives","System.Net.NameResolution","System.Net.HttpListener","System.Net.Requests","System.Net.WebClient","System.Net.WebHeaderCollection","System.Net.Security","System.Private.Uri","System.Private.CoreLib","System.Net.Http"],
	  :all = true,
	  :types = [ ["System.Net.IPAddress","IPAddress",0] ] ],

	[ :namespace = "System.Net.Http",
	  :uses = ["System.IO","System.Net","System.Threading.Tasks"],
	  :assemblies = ["System.Net.Http"],
	  :all = true ],

	[ :namespace = "System.Net.Sockets",
	  :uses = ["System.IO","System.Net"],
	  :assemblies = ["System.Net.Sockets"],
	  :all = true,
	  :prefer = ["System.Net.Sockets.TcpClient.Connect=2","System.Net.Sockets.UdpClient.Connect=2","System.Net.Sockets.UdpClient.Send=2"],
	  :types = [ ["System.Net.Sockets.TcpListener","TcpListener",2] ] ],

	[ :namespace = "System.Net.NetworkInformation",
	  :uses = ["System.Net"],
	  :assemblies = ["System.Net.NetworkInformation","System.Net.Ping"],
	  :all = true ],

	[ :namespace = "System.Globalization",
	  :assemblies = ["System.Private.CoreLib"],
	  :all = true ],

	[ :namespace = "System.Security.Cryptography",
	  :uses = ["System.IO"],
	  :assemblies = ["System.Security.Cryptography","System.Private.CoreLib"],
	  :all = true ],

	[ :namespace = "System.Diagnostics",
	  :uses = ["System.IO","System.Collections.Specialized"],
	  :assemblies = ["System.Diagnostics.Process","System.Private.CoreLib","System.ComponentModel.Primitives","System.Diagnostics.StackTrace","System.Diagnostics.TraceSource"],
	  :all = true ],

	[ :namespace = "System.Xml",
	  :assemblies = ["System.Private.Xml","System.Xml.ReaderWriter"],
	  :uses = ["System.IO","System.Xml.XPath"],
	  :all = true ],

	[ :namespace = "System.Xml.XPath",
	  :assemblies = ["System.Private.Xml","System.Xml.XPath"],
	  :uses = ["System.Xml"],
	  :all = true ],

	[ :namespace = "System.Xml.Linq",
	  :assemblies = ["System.Private.Xml.Linq","System.Xml.XDocument"],
	  :uses = ["System.Xml","System.IO"],
	  :all = true,
	  :types = [ ["System.Xml.Linq.XElement","XElement",2], ["System.Xml.Linq.XAttribute","XAttribute",2] ] ],

	[ :namespace = "System.Xml.Schema",
	  :assemblies = ["System.Private.Xml"],
	  :uses = ["System.Xml"],
	  :all = true ],

	[ :namespace = "System.Xml.Serialization",
	  :assemblies = ["System.Private.Xml"],
	  :uses = ["System.Xml","System.IO"],
	  :all = true ],

	[ :namespace = "System.Xml.Xsl",
	  :assemblies = ["System.Private.Xml"],
	  :uses = ["System.Xml","System.Xml.XPath","System.IO"],
	  :all = true ],

	[ :namespace = "System.Text.Json",
	  :assemblies = ["System.Text.Json"],
	  :uses = ["System.IO"],
	  :all = true ],

	[ :namespace = "System.Text.Json.Nodes",
	  :assemblies = ["System.Text.Json"],
	  :uses = ["System.Text.Json"],
	  :all = true ],

	[ :namespace = "System.Data",
	  :assemblies = ["System.Data.Common","System.Private.CoreLib"],
	  :uses = ["System.Data.Common","System.Xml"],
	  :all = true ],

	[ :namespace = "System.Data.Common",
	  :assemblies = ["System.Data.Common"],
	  :uses = ["System.Data","System.IO"],
	  :all = true ],

	[ :namespace = "System.Data.SqlTypes",
	  :assemblies = ["System.Data.Common"],
	  :all = true ],

	[ :namespace = "System.ComponentModel",
	  :assemblies = ["System.ComponentModel.Primitives","System.ComponentModel.TypeConverter","System.ComponentModel","System.Private.CoreLib","System.ComponentModel.EventBasedAsync"],
	  :uses = ["System.Collections.Specialized"],
	  :all = true ],

	[ :namespace = "System.Reflection",
	  :assemblies = ["System.Private.CoreLib","System.Reflection","System.Reflection.Primitives","System.Reflection.Extensions"],
	  :uses = ["System.Collections.Generic"],
	  :all = true ],

	[ :namespace = "System.Runtime.InteropServices",
	  :assemblies = ["System.Private.CoreLib","System.Runtime.InteropServices","System.Runtime.InteropServices.RuntimeInformation"],
	  :all = true ],

	[ :namespace = "System.Runtime.Loader",
	  :assemblies = ["System.Runtime.Loader","System.Private.CoreLib"],
	  :uses = ["System.Reflection"],
	  :all = true ],

	[ :namespace = "System.Timers",
	  :assemblies = ["System.ComponentModel.TypeConverter","System.ComponentModel.Primitives","System.Timers"],
	  :uses = ["System.ComponentModel"],
	  :all = true ],

	[ :namespace = "System.IO.Pipes",
	  :assemblies = ["System.IO.Pipes","System.IO.Pipes.AccessControl"],
	  :uses = ["System.IO"],
	  :types = [ ["System.IO.Pipes.NamedPipeClientStream","NamedPipeClientStream",2] ],
	  :all = true ],

	[ :namespace = "System.IO.MemoryMappedFiles",
	  :assemblies = ["System.IO.MemoryMappedFiles"],
	  :uses = ["System.IO"],
	  :all = true ],

	[ :namespace = "System.Security.Principal",
	  :assemblies = ["System.Security.Principal.Windows","System.Security.Principal","System.Private.CoreLib"],
	  :types = [ ["System.Security.Principal.WindowsIdentity","WindowsIdentity",0] ],
	  :all = true ],

	[ :namespace = "System.Security.Claims",
	  :assemblies = ["System.Security.Claims","System.Security.Principal","System.Private.CoreLib"],
	  :uses = ["System.Security.Principal"],
	  :all = true ],

	[ :namespace = "System.Security.Cryptography.X509Certificates",
	  :assemblies = ["System.Security.Cryptography.X509Certificates","System.Security.Cryptography","System.Private.CoreLib"],
	  :uses = ["System.Security.Cryptography"],
	  :all = true ],

	[ :namespace = "Microsoft.Win32",
	  :assemblies = ["Microsoft.Win32.Registry","Microsoft.Win32.Primitives","System.Private.CoreLib"],
	  :all = true ],

	[ :namespace = "System.Numerics",
	  :assemblies = ["System.Runtime.Numerics","System.Numerics.Vectors","System.Private.CoreLib"],
	  :all = true ],

	[ :namespace = "System.Net.Mail",
	  :assemblies = ["System.Net.Mail"],
	  :uses = ["System.Net","System.IO"],
	  :all = true ],

	[ :namespace = "System.Net.Mime",
	  :assemblies = ["System.Net.Mail"],
	  :all = true ],

	[ :namespace = "System.Net.WebSockets",
	  :assemblies = ["System.Net.WebSockets","System.Net.WebSockets.Client"],
	  :uses = ["System.Threading.Tasks"],
	  :all = true ],

	[ :namespace = "System.Net.Security",
	  :assemblies = ["System.Net.Security"],
	  :uses = ["System.IO","System.Security.Cryptography.X509Certificates"],
	  :all = true ],

	[ :namespace = "System.Net.Http.Headers",
	  :assemblies = ["System.Net.Http"],
	  :uses = ["System.Net.Http"],
	  :all = true ],

	[ :namespace = "System.Text.Encodings.Web",
	  :assemblies = ["System.Text.Encodings.Web"],
	  :all = true ],

	[ :namespace = "System.Text.Unicode",
	  :assemblies = ["System.Text.Encodings.Web","System.Private.CoreLib"],
	  :all = true ],

	[ :namespace = "System.Formats.Tar",
	  :assemblies = ["System.Formats.Tar"],
	  :uses = ["System.IO"],
	  :all = true ],

	[ :namespace = "System.Resources",
	  :assemblies = ["System.Resources.ResourceManager","System.Private.CoreLib"],
	  :all = true ],

	[ :namespace = "System.Collections.Concurrent",
	  :assemblies = ["System.Collections.Concurrent"],
	  :types = [
		["System.Collections.Concurrent.ConcurrentQueue`1[[System.String]]","ConcurrentStringQueue",0],
		["System.Collections.Concurrent.ConcurrentQueue`1[[System.Object]]","ConcurrentObjectQueue",0],
		["System.Collections.Concurrent.ConcurrentStack`1[[System.Object]]","ConcurrentObjectStack",0],
		["System.Collections.Concurrent.ConcurrentBag`1[[System.Object]]","ConcurrentObjectBag",0],
		["System.Collections.Concurrent.ConcurrentDictionary`2[[System.String],[System.Object]]","ConcurrentObjectDictionary",0],
		["System.Collections.Concurrent.ConcurrentDictionary`2[[System.String],[System.String]]","ConcurrentStringDictionary",0],
		["System.Collections.Concurrent.BlockingCollection`1[[System.Object]]","BlockingObjectCollection",0]
	  ],
	  :all = true ],

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

	[ :namespace = "System.Drawing",
	  :assemblies = ["System.Drawing.Common","System.Drawing.Primitives","System.Private.CoreLib"],
	  :desktop = true,
	  :uses = ["System.ComponentModel"],
	  :all = true,
	  :types = [ ["System.Drawing.Point","Point",2], ["System.Drawing.PointF","PointF",2], ["System.Drawing.Size","Size",2],
		["System.Drawing.SizeF","SizeF",2], ["System.Drawing.Rectangle","Rectangle",4], ["System.Drawing.RectangleF","RectangleF",4],
		["System.Drawing.Font","Font",2], ["System.Drawing.Bitmap","Bitmap",2], ["System.Drawing.Pen","Pen",1],
		["System.Drawing.SolidBrush","SolidBrush",1] ] ],

	[ :namespace = "System.Drawing.Drawing2D",
	  :assemblies = ["System.Drawing.Common","System.Drawing.Primitives"],
	  :desktop = true,
	  :uses = ["System.Drawing"],
	  :all = true ],

	[ :namespace = "System.Drawing.Imaging",
	  :assemblies = ["System.Drawing.Common","System.Drawing.Primitives"],
	  :desktop = true,
	  :uses = ["System.Drawing"],
	  :all = true,
	  :types = [ ["System.Drawing.Imaging.ImageFormat","ImageFormat",0] ] ],

	[ :namespace = "System.Drawing.Text",
	  :assemblies = ["System.Drawing.Common","System.Drawing.Primitives"],
	  :desktop = true,
	  :uses = ["System.Drawing"],
	  :all = true ],

	[ :namespace = "System.Drawing.Printing",
	  :assemblies = ["System.Drawing.Common","System.Drawing.Primitives"],
	  :desktop = true,
	  :uses = ["System.Drawing"],
	  :all = true ],

	[ :namespace = "System.Windows.Forms",
	  :assemblies = ["System.Windows.Forms","System.Windows.Forms.Primitives"],
	  :desktop = true,
	  :uses = ["System.Drawing","System.ComponentModel","System.Collections","System.Collections.Specialized","System.IO"],
	  :all = true,
	  :extra = ["../gui.ring"],
	  :prefer = ["System.Windows.Forms.Application.Run=1","System.Windows.Forms.MessageBox.Show=1"],
	  :types = [
		["System.Windows.Forms.Control+ControlCollection","ControlCollection"],
		["System.Windows.Forms.ListBox+ObjectCollection","ListBoxObjectCollection"],
		["System.Windows.Forms.ListBox+SelectedObjectCollection","ListBoxSelectedObjectCollection"],
		["System.Windows.Forms.ComboBox+ObjectCollection","ComboBoxObjectCollection"],
		["System.Windows.Forms.ListView+ListViewItemCollection","ListViewItemCollection"],
		["System.Windows.Forms.ListView+ColumnHeaderCollection","ColumnHeaderCollection"],
		["System.Windows.Forms.ListView+SelectedListViewItemCollection","SelectedListViewItemCollection"],
		["System.Windows.Forms.DataGridView+HitTestInfo","DataGridViewHitTestInfo"],
		["System.Windows.Forms.ListViewItem+ListViewSubItem","ListViewSubItem"],
		["System.Windows.Forms.ListViewItem+ListViewSubItemCollection","ListViewSubItemCollection"],
		["System.Windows.Forms.TabControl+TabPageCollection","TabPageCollection"],
		["System.Windows.Forms.ImageList+ImageCollection","ImageCollection"],
		["System.Windows.Forms.CheckedListBox+ObjectCollection","CheckedListBoxObjectCollection"],
		["System.Windows.Forms.CheckedListBox+CheckedItemCollection","CheckedItemCollection"],
		["System.Windows.Forms.CheckedListBox+CheckedIndexCollection","CheckedIndexCollection"]
	  ] ],

	[ :namespace = "System.Windows.Forms.VisualStyles",
	  :assemblies = ["System.Windows.Forms","System.Windows.Forms.Primitives"],
	  :desktop = true,
	  :uses = ["System.Drawing"],
	  :all = true ],

	[ :namespace = "System.Windows.Forms.Layout",
	  :assemblies = ["System.Windows.Forms","System.Windows.Forms.Primitives"],
	  :desktop = true,
	  :uses = ["System.Windows.Forms"],
	  :all = true ],

	[ :namespace = "System.Windows",
	  :assemblies = ["PresentationFramework","PresentationCore","WindowsBase","System.Xaml"],
	  :desktop = true,
	  :prefix = "Wpf",
	  :uses = ["System.Windows.Media","System.Windows.Input","System.Collections"],
	  :extra = ["../wpf.ring"],
	  :prefer = ["System.Windows.Application.Run=1","System.Windows.MessageBox.Show=1"],
	  :types = [ ["System.Windows.Size","WpfSize",2], ["System.Windows.Point","WpfPoint",2], ["System.Windows.Rect","Rect",4],
		["System.Windows.Thickness","Thickness",4], ["System.Windows.Vector","WpfVector",2], ["System.Windows.CornerRadius","CornerRadius",4],
		["System.Windows.GridLength","GridLength",1], ["System.Windows.Window","Window",0] ],
	  :all = true ],

	[ :namespace = "System.Windows.Controls",
	  :assemblies = ["PresentationFramework","PresentationCore","WindowsBase","System.Xaml"],
	  :desktop = true,
	  :prefix = "Wpf",
	  :uses = ["System.Windows","System.Windows.Controls.Primitives","System.Windows.Media","System.Windows.Documents"],
	  :all = true ],

	[ :namespace = "System.Windows.Controls.Primitives",
	  :assemblies = ["PresentationFramework","PresentationCore","WindowsBase","System.Xaml"],
	  :desktop = true,
	  :prefix = "Wpf",
	  :uses = ["System.Windows","System.Windows.Controls"],
	  :all = true ],

	[ :namespace = "System.Windows.Shapes",
	  :assemblies = ["PresentationFramework","PresentationCore","WindowsBase","System.Xaml"],
	  :desktop = true,
	  :prefix = "Wpf",
	  :uses = ["System.Windows","System.Windows.Media"],
	  :all = true ],

	[ :namespace = "System.Windows.Media",
	  :assemblies = ["PresentationFramework","PresentationCore","WindowsBase","System.Xaml"],
	  :desktop = true,
	  :prefix = "Wpf",
	  :uses = ["System.Windows","System.Windows.Media.Imaging"],
	  :all = true ],

	[ :namespace = "System.Windows.Media.Imaging",
	  :assemblies = ["PresentationFramework","PresentationCore","WindowsBase","System.Xaml"],
	  :desktop = true,
	  :prefix = "Wpf",
	  :uses = ["System.Windows.Media","System.IO"],
	  :all = true ],

	[ :namespace = "System.Windows.Media.Animation",
	  :assemblies = ["PresentationFramework","PresentationCore","WindowsBase","System.Xaml"],
	  :desktop = true,
	  :prefix = "Wpf",
	  :uses = ["System.Windows","System.Windows.Media"],
	  :all = true ],

	[ :namespace = "System.Windows.Input",
	  :assemblies = ["PresentationFramework","PresentationCore","WindowsBase","System.Xaml"],
	  :desktop = true,
	  :prefix = "Wpf",
	  :uses = ["System.Windows"],
	  :all = true ],

	[ :namespace = "System.Windows.Data",
	  :assemblies = ["PresentationFramework","PresentationCore","WindowsBase","System.Xaml"],
	  :desktop = true,
	  :prefix = "Wpf",
	  :uses = ["System.Windows"],
	  :all = true ],

	[ :namespace = "System.Windows.Documents",
	  :assemblies = ["PresentationFramework","PresentationCore","WindowsBase","System.Xaml"],
	  :desktop = true,
	  :prefix = "Wpf",
	  :uses = ["System.Windows","System.Windows.Media"],
	  :all = true ],

	[ :namespace = "System.Windows.Markup",
	  :assemblies = ["PresentationFramework","PresentationCore","WindowsBase","System.Xaml"],
	  :desktop = true,
	  :prefix = "Wpf",
	  :uses = ["System.Windows","System.IO","System.Xml"],
	  :all = true ],

	[ :namespace = "System.Windows.Threading",
	  :assemblies = ["PresentationFramework","PresentationCore","WindowsBase","System.Xaml"],
	  :desktop = true,
	  :prefix = "Wpf",
	  :uses = ["System.Windows"],
	  :all = true ],

	[ :namespace = "System.Windows.Navigation",
	  :assemblies = ["PresentationFramework","PresentationCore","WindowsBase","System.Xaml"],
	  :desktop = true,
	  :prefix = "Wpf",
	  :uses = ["System.Windows","System.Windows.Controls"],
	  :all = true ],

	[ :namespace = "System.Windows.Media.Effects",
	  :assemblies = ["PresentationFramework","PresentationCore","WindowsBase","System.Xaml"],
	  :desktop = true,
	  :prefix = "Wpf",
	  :uses = ["System.Windows.Media"],
	  :all = true ],

	[ :namespace = "System.Windows.Media.Media3D",
	  :assemblies = ["PresentationFramework","PresentationCore","WindowsBase","System.Xaml"],
	  :desktop = true,
	  :prefix = "Wpf",
	  :uses = ["System.Windows.Media"],
	  :all = true ],

	[ :namespace = "System.Windows.Ink",
	  :assemblies = ["PresentationFramework","PresentationCore","WindowsBase","System.Xaml"],
	  :desktop = true,
	  :prefix = "Wpf",
	  :uses = ["System.Windows.Media","System.Windows.Input"],
	  :all = true ]

]
