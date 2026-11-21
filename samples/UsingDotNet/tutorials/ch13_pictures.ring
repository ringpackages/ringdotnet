# pictures that work on every system - SkiaSharp draws, saves and reads pictures on Windows, Linux and macOS (System.Drawing is Windows only)
#   (the project is in the folder Skia: Skia.csproj names SkiaSharp and its Linux library, and Empty.cs is the one source file a project needs)
load "dotnet.ring"
using { "System.IO" }

cHere = currentdir()
cDll = cHere + "/Skia/libs/SkiaSharp.dll"
cClasses = cHere + "/Skia/classes"

# STEP 1. Get the package (nuget.org the first time) with dotnet publish: SkiaSharp.dll, and its native library in Skia/libs/runtimes
if not fexists(cDll)
	? "getting the package..."
	system("dotnet publish Skia -c Release -o Skia/libs -nologo -v q > nul")
ok
if not fexists(cDll)
	? "The package could not be restored. It is downloaded from nuget.org the first time, so the computer needs the internet once."
	bye
ok

# STEP 2. Make Ring classes for the namespace SkiaSharp
chdir("../../../tools/dotnettools")
system(exefilename() + " wrapassembly.ring " + cDll + " " + cClasses + " SkiaSharp > nul")
chdir(cHere)

# STEP 3. Load the assembly and the classes
dnLoad(cDll)
dnImportFrom(cClasses + "/","SkiaSharp")

func main
	# 1. A bitmap is a grid of pixels, and a canvas is what draws on it. Colors are values of the type SKColor: Parse reads "#rrggbb".
	oBitmap = new SKBitmap().@New([ :width = 200, :height = 100 ])
	oCanvas = new SKCanvas(oBitmap)
	oBlue = new SKColor().Parse("#2060c0")
	oYellow = new SKColor().Parse("#ffcc00")
	oWhite = new SKColor().Parse("#ffffff")
	oCanvas.Clear(oBlue)

	# 2. A paint says how to draw: its color, and whether the edges are smooth
	oPaint = new SKPaint
	oPaint.Color = oYellow
	oPaint.IsAntialias = true
	oCanvas.DrawCircle([ :cx = 150, :cy = 50, :radius = 30, :paint = oPaint ])
	oPaint.Color = oWhite
	oPaint.TextSize = 28
	oCanvas.DrawText([ :text = "Ring", :x = 15, :y = 62, :paint = oPaint ])
	? "1. the picture is " + oBitmap.Width + " x " + oBitmap.Height + " pixels"

	# 3. Look at pixels: a pixel is an SKColor with Red, Green, Blue and Alpha from 0 to 255
	oCorner = oBitmap.GetPixel(0,0)
	oCenter = oBitmap.GetPixel(150,50)
	? "2. corner (0,0): " + oCorner.Red + ", " + oCorner.Green + ", " + oCorner.Blue
	? "   center of the circle (150,50): " + oCenter.Red + ", " + oCenter.Green + ", " + oCenter.Blue

	# 4. Save as PNG: Encode gives the data of the picture, ToArray its bytes (a Ring text), and File writes them
	cFile = new Path().Combine([new Path().GetTempPath(),"ringdotnet-picture.png"])
	oImage = new SKImage().FromBitmap(oBitmap)
	cPng = oImage.Encode(NULL).ToArray()
	new File().WriteAllBytes(cFile,cPng)
	? "3. a PNG file was written: " + (substr(cPng,2,3) = "PNG") + ", " + new File().Exists(cFile)

	# 5. Read the file back: Decode makes a bitmap again, and the pixels are the same
	oBack = new SKBitmap().Decode(cFile)
	oPixel = oBack.GetPixel(150,50)
	? "4. read back: " + oBack.Width + " x " + oBack.Height + ", center " + oPixel.Red + ", " + oPixel.Green + ", " + oPixel.Blue
	new File().Delete(cFile)
