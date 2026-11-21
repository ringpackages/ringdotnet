# The simple syntax: classes with the .NET names, methods, properties and braces (the namespaces are opened with using)
load "dotnet.ring"
using {
	"System"
	"System.Text"
	"System.IO"
	"System.Diagnostics"
}

oConsole = new Console()
oConsole.WriteLine("Hello from .NET")

oMath = new Math()
? "Max(3,9)   = " + oMath.Max(3,9)
? "Sqrt(144)  = " + oMath.Sqrt(144)
? "PI         = " + oMath.PI

oSB = new StringBuilder("Hello") {
	Append(", ")
	Append("Ring!")
}
? oSB.ToString()
? "Length    = " + oSB.Length
oSB.Append("!!").Append("?")        # chained: Append returns a StringBuilder
? oSB.ToString()

oSW = new Stopwatch()
oSW.Start()
oSW.Stop()
? "Elapsed ms >= 0 : " + (oSW.ElapsedMilliseconds >= 0)

oPath = new Path()
? oPath.Combine(["a","b"])
? oPath.GetFileName("c:/x/file.txt")

oEnv = new Environment()
? oEnv.MachineName != ""

oRnd = new Random(42)
? oRnd.@Next([ :minValue = 1, :maxValue = 10 ]) >= 1
