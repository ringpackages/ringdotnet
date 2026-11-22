# ZXing.Net: a QR code encoded to a bit matrix, drawn as gray pixel bytes and decoded again (a binary text goes in as a byte array)
load "pkg.ring"
pkgUse("zxing",[["ZXing.Net","0.16.11"]],[["zxing.dll",["ZXing","ZXing.Common"]]])
pkgImport("zxing","zxing.dll","ZXing")
pkgImport("zxing","zxing.dll","ZXing.Common")

oWriter = new BarcodeWriterGeneric()
oWriter.Format = dnStatic("ZXing.BarcodeFormat","QR_CODE",[])
oMatrix = oWriter.Encode("Ring and .NET")
nSize = oMatrix.Width
dnAssert("a square code",oMatrix.Height,nSize)
dnAssert("a size of a QR code",nSize >= 21,1)

# the pixels: 4 modules of each, a quiet zone of 4 modules, black 0 and white 255
nScale = 4
nSide = (nSize + 8) * nScale
cPixels = ""
for y = 0 to nSide - 1
	cRow = ""
	for x = 0 to nSide - 1
		nX = floor(x / nScale) - 4
		nY = floor(y / nScale) - 4
		if nX >= 0 and nX < nSize and nY >= 0 and nY < nSize and oMatrix.Item([nX,nY])
			cRow += char(0)
		else
			cRow += char(255)
		ok
	next
	cPixels += cRow
next
dnAssert("the pixels",len(cPixels),nSide * nSide)

oSource = dnNew("ZXing.RGBLuminanceSource",[cPixels,nSide,nSide,dnStatic("ZXing.RGBLuminanceSource+BitmapFormat","Gray8",[])])
oReader = new BarcodeReaderGeneric()
oResult = oReader.Decode(oSource)
dnAssert("the text is read back",oResult.Text,"Ring and .NET")

dnTestSummary()
