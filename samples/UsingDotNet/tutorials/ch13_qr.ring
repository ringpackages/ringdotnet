# a QR code with a NuGet package - QRCoder makes the code, and the program prints it as text and writes it as a PNG picture
#   (the project is in the folder Qr: Qr.csproj names QRCoder, and Empty.cs is the one source file a project needs)
load "dotnet.ring"
using { "System.IO" }

cHere = currentdir()
cDll = cHere + "/Qr/libs/QRCoder.dll"
cClasses = cHere + "/Qr/classes"

# STEP 1. Get the package (nuget.org the first time) with dotnet publish
if not fexists(cDll)
	? "getting the package..."
	system("dotnet publish Qr -c Release -o Qr/libs -nologo -v q > nul")
ok
if not fexists(cDll)
	? "The package could not be restored. It is downloaded from nuget.org the first time, so the computer needs the internet once."
	bye
ok

# STEP 2. Make Ring classes for the DLL
chdir("../../../tools/dotnettools")
system(exefilename() + " wrapassembly.ring " + cDll + " " + cClasses + " > nul")
chdir(cHere)

# STEP 3. Load the assembly and the classes
dnLoad(cDll)
dnImportFrom(cClasses + "/","QRCoder")

func main
	oGenerator = new QRCodeGenerator()

	# 1. The code of a text. CreateQrCode has several versions, so it takes the names of its parameters; the level of error
	#    correction is an enum, so it is a text: L, M, Q or H.
	oCode = oGenerator.CreateQrCode([ :plainText = "RING", :eccLevel = "L" ])
	? "1. a QR code for RING, as text (a block is a dark module):"

	# The class that draws it as text takes the code (a constructor chosen by the name of its parameter)
	oAscii = new AsciiQRCode().@New([ :data = oCode ])
	? oAscii.GetGraphic(1)

	# 2. A higher level of error correction repeats more data, so the code is bigger. The answer is a List<BitArray> that has no
	#    class, so its Count is read with getProp.
	cText = "https://ring-lang.github.io"
	? "2. the size of the code for " + cText + " (modules on a side, with the empty border):"
	for cLevel in ["L","M","Q","H"]
		oSized = oGenerator.CreateQrCode([ :plainText = cText, :eccLevel = cLevel ])
		? "   level " + cLevel + ": " + oSized.ModuleMatrix.getProp("Count")
	next

	# 3. A picture: PngByteQRCode gives the bytes of a PNG file, and a byte[] that .NET returns is a Ring text
	cPng = new PngByteQRCode().@New([ :data = oCode ]).GetGraphic(8)          # 8 pixels for each module
	cFile = new Path().Combine([new Path().GetTempPath(),"ringdotnet-qr.png"])
	new File().WriteAllBytes(cFile,cPng)
	? nl + "3. the picture is a PNG file: " + (substr(cPng,2,3) = "PNG") + ", written to a file: " + new File().Exists(cFile)
	new File().Delete(cFile)
