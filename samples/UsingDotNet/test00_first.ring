# The first program: simple syntax, the namespaces are opened with using
load "../../libraries/dotnetlib/dotnetlib.ring"

using {
	"System"
	"System.Text"
}

oSB = new StringBuilder("Hello")
oSB.Append(", ").Append("Ring!")
? oSB.ToString()
? oSB.Length

? new Math().Max(3,9)
? "Running on .NET " + new Environment().Version.ToString()
