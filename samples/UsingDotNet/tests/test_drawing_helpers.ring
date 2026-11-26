# RingDotNet.DrawingHelpers.SetPixels: a rectangle of pixels from one text of 3 bytes for each pixel, row after row (needs System.Drawing: Windows only). A bitmap of 32 bits
# for each pixel is written with one copy of its memory, any other bitmap pixel by pixel: both must give the same pixels.
load "dotnet.ring"

if not iswindows()
	? "TESTS: 0 passed, 0 failed (System.Drawing.Bitmap needs Windows)"
	bye
ok
using { "System.Drawing" }

# a rectangle of 3 x 2 pixels in the middle of a bitmap: red, green, blue / white, black, yellow
cRectangle = char(255) + char(0) + char(0) + char(0) + char(255) + char(0) + char(0) + char(0) + char(255)
cRectangle += char(255) + char(255) + char(255) + char(0) + char(0) + char(0) + char(255) + char(255) + char(0)

for cFormat in ["Format32bppArgb","Format24bppRgb"]
	oBitmap = dnNew("System.Drawing.Bitmap",[10,6,cFormat])
	dnStatic("RingDotNet.DrawingHelpers","SetPixels",[oBitmap,2,1,3,2,cRectangle])
	dnAssert(cFormat + ": the first pixel is red",oBitmap.GetPixel(2,1).Name,"ffff0000")
	dnAssert(cFormat + ": the second is green",oBitmap.GetPixel(3,1).Name,"ff00ff00")
	dnAssert(cFormat + ": the third is blue",oBitmap.GetPixel(4,1).Name,"ff0000ff")
	dnAssert(cFormat + ": the second row starts with white",oBitmap.GetPixel(2,2).Name,"ffffffff")
	dnAssert(cFormat + ": black",oBitmap.GetPixel(3,2).Name,"ff000000")
	dnAssert(cFormat + ": yellow",oBitmap.GetPixel(4,2).Name,"ffffff00")
	# what is around the rectangle is not changed (a new bitmap of 32 bits is transparent, one of 24 bits is black)
	if cFormat = "Format32bppArgb"
		cUnset = "0"
	else
		cUnset = "ff000000"
	ok
	dnAssert(cFormat + ": the pixel to the left is not set",oBitmap.GetPixel(1,1).Name,cUnset)
	dnAssert(cFormat + ": the pixel to the right is not set",oBitmap.GetPixel(5,1).Name,cUnset)
	dnAssert(cFormat + ": the pixel above is not set",oBitmap.GetPixel(2,0).Name,cUnset)
	dnAssert(cFormat + ": the pixel below is not set",oBitmap.GetPixel(2,3).Name,cUnset)
next

# a whole bitmap with a gradient, and every byte value
oWhole = new Bitmap(256,2)
cWhole = ""
for nRow = 0 to 1
	for nColumn = 0 to 255
		cWhole += char(nColumn) + char(255 - nColumn) + char((nColumn * 3 + nRow) % 256)
	next
next
dnStatic("RingDotNet.DrawingHelpers","SetPixels",[oWhole,0,0,256,2,cWhole])
dnAssert("the first pixel of a whole bitmap",oWhole.GetPixel(0,0).Name,"ff00ff00")
dnAssert("the last pixel of the first row",oWhole.GetPixel(255,0).Name,"ffff00fd")
dnAssert("a pixel of the second row",oWhole.GetPixel(100,1).Name,"ff649b2d")

# a rectangle with no pixels does nothing
dnStatic("RingDotNet.DrawingHelpers","SetPixels",[oWhole,0,0,0,0,""])
dnAssert("an empty rectangle is accepted",oWhole.GetPixel(0,0).Name,"ff00ff00")

# a text that does not fit the rectangle, and a rectangle outside of the bitmap, are errors
cError = ""
try
	dnStatic("RingDotNet.DrawingHelpers","SetPixels",[oWhole,0,0,2,2,"abc"])
catch
	cError = cCatchError
done
dnAssert("a text that is not 3 bytes for each pixel is an error",substr(cError,"3 bytes for each pixel") > 0,1)
cError = ""
try
	dnStatic("RingDotNet.DrawingHelpers","SetPixels",[oWhole,250,0,10,1,copy(char(1),30)])
catch
	cError = cCatchError
done
dnAssert("a rectangle that is partly outside of the bitmap is an error",len(cError) > 0,1)
dnTestSummary()
