# QRCoder: a QR code as PNG bytes (binary result), as a matrix of modules, and as SVG text
load "pkg.ring"
pkgUse("qrcoder",[["QRCoder","1.6.0"]],[["QRCoder.dll",["QRCoder"]]])
pkgImport("qrcoder","QRCoder.dll","QRCoder")

oGenerator = new QRCodeGenerator()
oData = oGenerator.CreateQrCode([ :plainText = "https://ring-lang.github.io", :eccLevel = dnStatic("QRCoder.QRCodeGenerator+ECCLevel","M",[]) ])
nSize = len(oData.ModuleMatrix.toList())
dnAssert("a QR code is a square of at least 21 modules",nSize >= 21,1)
dnAssert("the first row has as many modules",len(oData.ModuleMatrix.Item(0).toList()),nSize)

oPng = new PngByteQRCode().@New(oData)
cPng = oPng.GetGraphic(4)
dnAssert("a PNG signature",substr(cPng,"PNG") = 2,1)
dnAssert("the first byte of a PNG",ascii(left(cPng,1)),137)
dnAssert("a PNG of some size",len(cPng) > 200,1)

oSvg = new SvgQRCode().@New(oData)
cSvg = oSvg.GetGraphic(4)
dnAssert("an SVG text",substr(cSvg,"<svg") > 0,1)

# the same text gives the same code
oData2 = oGenerator.CreateQrCode([ :plainText = "https://ring-lang.github.io", :eccLevel = dnStatic("QRCoder.QRCodeGenerator+ECCLevel","M",[]) ])
dnAssert("a determined result",new PngByteQRCode().@New(oData2).GetGraphic(4) = cPng,1)

# a longer text needs a bigger code
oBig = oGenerator.CreateQrCode([ :plainText = copy("ring ",60), :eccLevel = dnStatic("QRCoder.QRCodeGenerator+ECCLevel","L",[]) ])
dnAssert("a longer text, a bigger code",len(oBig.ModuleMatrix.toList()) > nSize,1)

dnTestSummary()
