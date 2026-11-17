load "../../libraries/dotnetlib/dotnetlib.ring"
using {
	"System"
	"System.Text"
	"System.IO"
	"System.Collections.Generic"
	"System.Diagnostics"
}

# .NET properties and fields are Ring attributes: read and write them directly
oSB = new StringBuilder("Hello")
? "Length    = " + oSB.Length
oSB.Length = 3                              # StringBuilder.Length is read/write
? "Truncated = " + oSB.ToString()

? "Math.PI   = " + new Math().PI
? "Path sep  = " + new Path().DirectorySeparatorChar

oList = new StringList()
oList.Add("a")  oList.Add("b")
? "Count     = " + oList.Count
oList.Capacity = 50
? "Capacity  = " + oList.Capacity

# Read-only properties raise an error when assigned
try
	oList.Count = 10
catch
	? "Caught: " + cCatchError
done

# Chained properties and the { } syntax work too
oRnd = new Random(1)
oSW = new Stopwatch()
oSW { Start() Stop() ? "Running = " + IsRunning }
