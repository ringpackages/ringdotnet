# SkiaSharp: a 2D graphics library with native code: a bitmap, a canvas, colors, shapes and text drawn in memory, pixels read back, and the picture as a PNG
load "pkg.ring"
pkgUse("skiasharp",[["SkiaSharp","4.158.0"],["SkiaSharp.NativeAssets.Win32","4.158.0"],["SkiaSharp.NativeAssets.Linux.NoDependencies","4.158.0"]],[["SkiaSharp.dll",["SkiaSharp"]]])
pkgImport("skiasharp","SkiaSharp.dll","SkiaSharp")

oInfo = (new SKImageInfo).@New([ :width = 40, :height = 30 ])
dnAssert("the size of the picture",oInfo.Width * 100 + oInfo.Height,4030)

oBitmap = (new SKBitmap).@New([ :info = oInfo ])
oCanvas = new SKCanvas(oBitmap)
oColors = new SKColors()
oCanvas.Clear(oColors.White)
oPixel = oBitmap.GetPixel(5,5)
dnAssert("a cleared bitmap is white (red)",oPixel.Red,255)
dnAssert("a cleared bitmap is white (blue)",oPixel.Blue,255)

# a filled rectangle: a paint with a color
oPaint = new SKPaint()
oPaint.Color = oColors.Red
oCanvas.DrawRect([ :x = 10, :y = 5, :w = 20, :h = 20, :paint = oPaint ])
oInside = oBitmap.GetPixel(20,15)
dnAssert("the rectangle is red (red)",oInside.Red,255)
dnAssert("the rectangle is red (green)",oInside.Green,0)
oOutside = oBitmap.GetPixel(2,2)
dnAssert("outside the rectangle it is still white",oOutside.Green,255)

# a circle of another color on top of it
oBlue = new SKPaint()
oBlue.Color = oColors.Blue
oCanvas.DrawCircle([ :cx = 20, :cy = 15, :radius = 4, :paint = oBlue ])
oCenter = oBitmap.GetPixel(20,15)
dnAssert("the circle is blue (blue)",oCenter.Blue,255)
dnAssert("the circle is blue (red)",oCenter.Red,0)
oEdge = oBitmap.GetPixel(12,7)
dnAssert("the rectangle is still red next to the circle",oEdge.Red,255)

# the picture as a PNG
oImage = new SKImage()
oPicture = oImage.FromBitmap(oBitmap)
dnAssert("the image has the size of the bitmap",oPicture.Width * 100 + oPicture.Height,4030)
oData = oPicture.Encode(NULL)
cPng = oData.callMethod("ToArray",[])
dnAssert("a PNG starts with the PNG signature",substr(cPng,2,3),"PNG")
dnAssert("the PNG is the size that the data says",len(cPng),oData.Size)

# and back: the PNG is decoded into a bitmap with the same colors
oDecoded = dnStatic("SkiaSharp.SKBitmap","Decode",[cPng])
oBack = oDecoded.GetPixel(20,15)
dnAssert("the decoded bitmap has the blue circle",oBack.Blue,255)

dnTestSummary()
