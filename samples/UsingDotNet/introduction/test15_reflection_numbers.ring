# Big numbers, reflection, encoders and concurrent collections
load "dotnet.ring"
using {
	"System"
	"System.Reflection"
	"System.Numerics"
	"System.Text.Encodings.Web"
	"System.Collections.Concurrent"
	"System.Runtime.InteropServices"
}

# Big integers: factorial of 40
oBig = new BigInteger()
nFactorial = oBig.Parse("1")
for nLoop = 2 to 40
	nFactorial = oBig.Multiply(nFactorial,nLoop)
next
? "40!            : " + nFactorial.ToString()
? "2^200          : " + oBig.Pow(2,200).ToString()
oZ = dnNew("Complex",[ :real = 3, :imaginary = 4 ])
? "|3+4i|         : " + oZ.Magnitude

# Reflection: explore a type
oMath = new Type().GetType([ :typeName = "System.Math" ])
aNames = []
for oMethod in oMath.GetMethods(NULL).toList()
	if find(aNames,oMethod.Name) = 0 aNames + oMethod.Name ok
next
? "Math methods   : " + len(aNames) + " names, e.g. " + aNames[1] + ", " + aNames[2] + ", " + aNames[3]
oAsm = new Assembly().Load_("System.Linq")
? "Assembly       : " + oAsm.GetName(NULL).Name + " " + oAsm.GetName(NULL).Version.ToString()

# Environment and encoders
? "OS             : " + new RuntimeInformation().OSDescription
? "HTML encoded   : " + new HtmlEncoder().Default.Encode("<script>alert('x')</script>")
oQueue = new ConcurrentStringQueue()
oQueue.Enqueue("first")  oQueue.Enqueue("second")
? "Concurrent     : " + oQueue.TryDequeue()[2] + ", left " + oQueue.Count
