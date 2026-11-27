# Net.Codecrete.QrCodeGenerator: a QR code made in memory (the modules as a grid, an SVG text, a PNG as bytes), with the size and version that the standard gives
load "pkg.ring"
pkgUse("qrcodegen",[["Net.Codecrete.QrCodeGenerator","3.2.1"]],[["QrCodeGenerator.dll",["Net.Codecrete.QrCodeGenerator"]]])
pkgImport("qrcodegen","QrCodeGenerator.dll","Net.Codecrete.QrCodeGenerator")

oQr = dnStatic("Net.Codecrete.QrCodeGenerator.QrCode","EncodeText",["Hello, Ring!","Medium"])
dnAssert("version 1 of the standard is a 21 x 21 grid",oQr.Size,21)
dnAssert("the version",oQr.Version,1)
dnAssert("the error correction level",oQr.ErrorCorrectionLevel,"Medium")

# every code has a dark square in its top left corner (the finder pattern), and a light line after it (the separator)
dnAssert("a dark module of the finder pattern",oQr.GetModule(0,0),1)
dnAssert("the middle of the finder pattern is dark",oQr.GetModule(3,3),1)
dnAssert("the separator is light",oQr.GetModule(7,0),0)

# the same text always makes the same code
oAgain = dnStatic("Net.Codecrete.QrCodeGenerator.QrCode","EncodeText",["Hello, Ring!","Medium"])
nSame = 0
nDark = 0
for nY = 0 to oQr.Size - 1
	for nX = 0 to oQr.Size - 1
		if oQr.GetModule(nX,nY) = oAgain.GetModule(nX,nY)
			nSame++
		ok
		if oQr.GetModule(nX,nY)
			nDark++
		ok
	next
next
dnAssert("the same text, the same modules",nSame,441)
dnAssert("a code has dark and light modules",nDark > 100 and nDark < 341,1)

# a longer text needs a bigger version
oBig = dnStatic("Net.Codecrete.QrCodeGenerator.QrCode","EncodeText",["The quick brown fox jumps over the lazy dog, again and again and again.","Medium"])
dnAssert("a longer text makes a bigger grid",oBig.Size > 21,1)

# an SVG text and a PNG
cSvg = oQr.ToSvgString([ :border = 4 ])
dnAssert("an SVG text",left(cSvg,5) = "<?xml" or left(cSvg,4) = "<svg",1)
dnAssert("the SVG has the size of the code and the border",substr(cSvg,"viewBox=" + '"' + "0 0 29 29" + '"') > 0,1)
cPng = oQr.ToPngBitmap([ :border = 2, :scale = 4 ])
dnAssert("a PNG starts with the PNG signature",substr(cPng,2,3),"PNG")
dnAssert("the PNG has bytes",len(cPng) > 100,1)

dnTestSummary()
