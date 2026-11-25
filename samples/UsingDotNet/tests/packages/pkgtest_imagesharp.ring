# ImageSharp: images made, changed and saved in memory; the pixel type is a generic argument (Image<Rgba32>), the processing steps of Mutate are a callback
load "pkg.ring"
pkgUse("imagesharp",[["SixLabors.ImageSharp","3.1.12"]],[["SixLabors.ImageSharp.dll",["SixLabors.ImageSharp","SixLabors.ImageSharp.PixelFormats","SixLabors.ImageSharp.Processing","SixLabors.ImageSharp.Formats.Png","SixLabors.ImageSharp.Formats.Jpeg"]]])
pkgImport("imagesharp","SixLabors.ImageSharp.dll","SixLabors.ImageSharp")
pkgImport("imagesharp","SixLabors.ImageSharp.dll","SixLabors.ImageSharp.PixelFormats")
pkgImport("imagesharp","SixLabors.ImageSharp.dll","SixLabors.ImageSharp.Processing")
pkgImport("imagesharp","SixLabors.ImageSharp.dll","SixLabors.ImageSharp.Formats.Png")
pkgImport("imagesharp","SixLabors.ImageSharp.dll","SixLabors.ImageSharp.Formats.Jpeg")
using { "System.IO" }

cImage = "SixLabors.ImageSharp.Image`1[[SixLabors.ImageSharp.PixelFormats.Rgba32, SixLabors.ImageSharp]]"
oImage = dnNew(cImage,[40,30])
dnAssert("the width",oImage.Width,40)
dnAssert("the height",oImage.Height,30)

# a pixel: Rgba32(r,g,b,a); the indexer takes the two indexes as a list
oRed = dnNew("SixLabors.ImageSharp.PixelFormats.Rgba32",[255,0,0,255])
oImage.SetItem([5,6],oRed)
oBack = oImage.Item([5,6])
dnAssert("the red channel of the pixel",oBack.R,255)
dnAssert("the green channel",oBack.G,0)
dnAssert("the alpha channel",oBack.A,255)
dnAssert("a pixel that was not set is transparent",oImage.Item([0,0]).A,0)

# processing steps: Mutate takes a callback that gets the context; the steps are extension methods of the context
dnStatic("SixLabors.ImageSharp.Processing.ProcessingExtensions","Mutate",[oImage,dnCallback("stepResize")])
dnAssert("the width after Resize",oImage.Width,20)
dnAssert("the height after Resize",oImage.Height,15)

# saved in memory as PNG and loaded again
oStream = new MemoryStream()
dnStatic("SixLabors.ImageSharp.ImageExtensions","SaveAsPng",[oImage,oStream])
dnAssert("the PNG has bytes",oStream.Length > 8,1)
oStream.Position = 0
oLoaded = dnStatic("SixLabors.ImageSharp.Image","Load",[oStream])
dnAssert("the loaded width",oLoaded.Width,20)
dnAssert("the loaded height",oLoaded.Height,15)
oStream.Position = 0
dnAssert("the format that is detected in the bytes",dnStatic("SixLabors.ImageSharp.Image","DetectFormat",[oStream]).Name,"PNG")

# more steps: Flip moves a pixel, Grayscale makes the channels equal, Crop changes the size; Clone makes a copy that is not changed by them
oFlip = dnNew(cImage,[10,10])
oFlip.SetItem([2,1],dnNew("SixLabors.ImageSharp.PixelFormats.Rgba32",[200,100,50,255]))
oCopy = oFlip.Clone(NULL)
dnStatic("SixLabors.ImageSharp.Processing.ProcessingExtensions","Mutate",[oFlip,dnCallback("stepFlip")])
dnAssert("the pixel moved to the other side after Flip",oFlip.Item([2,8]).R,200)
dnAssert("the pixel is not at its old place",oFlip.Item([2,1]).A,0)
dnAssert("the copy was not changed",oCopy.Item([2,1]).R,200)
dnStatic("SixLabors.ImageSharp.Processing.ProcessingExtensions","Mutate",[oCopy,dnCallback("stepGray")])
oGray = oCopy.Item([2,1])
dnAssert("Grayscale makes the channels equal",oGray.R = oGray.G and oGray.G = oGray.B,1)
dnAssert("Grayscale keeps the alpha",oGray.A,255)
dnStatic("SixLabors.ImageSharp.Processing.ProcessingExtensions","Mutate",[oFlip,dnCallback("stepCrop")])
dnAssert("the width after Crop",oFlip.Width,6)
dnAssert("the height after Crop",oFlip.Height,4)

# another format, and a text that is not an image
oJpeg = new MemoryStream()
dnStatic("SixLabors.ImageSharp.ImageExtensions","SaveAsJpeg",[oLoaded,oJpeg])
oJpeg.Position = 0
dnAssert("the format of the JPEG",dnStatic("SixLabors.ImageSharp.Image","DetectFormat",[oJpeg]).Name,"JPEG")
cError = ""
try
	dnStatic("SixLabors.ImageSharp.Image","Load",[new MemoryStream().@New([ :buffer = dnBuffer("this is not an image at all") ])])
catch
	cError = cCatchError
done
dnAssert("a text that is not an image is an error",substr(cError,"UnknownImageFormatException") > 0,1)

oImage.Dispose()
dnTestSummary()

func stepFlip aArgs

	dnStatic("SixLabors.ImageSharp.Processing.FlipExtensions","Flip",[aArgs[1],dnStatic("SixLabors.ImageSharp.Processing.FlipMode","Vertical",[])])

func stepGray aArgs

	dnStatic("SixLabors.ImageSharp.Processing.GrayscaleExtensions","Grayscale",[aArgs[1]])

func stepCrop aArgs

	dnStatic("SixLabors.ImageSharp.Processing.CropExtensions","Crop",[aArgs[1],dnNew("SixLabors.ImageSharp.Rectangle",[1,1,6,4])])

func stepResize aArgs

	dnStatic("SixLabors.ImageSharp.Processing.ResizeExtensions","Resize",[aArgs[1],20,15])
