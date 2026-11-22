# Figgle: text as ASCII art in a font (a static font object with Render); the same text in two fonts
load "pkg.ring"
pkgUse("figgle",[["Figgle","0.6.6"],["Figgle.Fonts","0.6.6"]],[["Figgle.dll",["Figgle"]],["Figgle.Fonts.dll",["Figgle.Fonts"]]])
pkgImport("figgle","Figgle.dll","Figgle")

oStandard = dnStatic("Figgle.Fonts.FiggleFonts","Standard",[])
cArt = oStandard.Render("Ring")
dnAssert("the art has several lines",len(str2list(cArt)) >= 5,1)
dnAssert("and is wider than the text",len(cArt) > 4 * 5,1)
dnAssert("the letters are drawn with characters",substr(cArt,"|") > 0 or substr(cArt,"_") > 0,1)

oSmall = dnStatic("Figgle.Fonts.FiggleFonts","Small",[])
dnAssert("another font draws it differently",oSmall.Render("Ring") != cArt,1)
dnAssert("a text is rendered the same each time",oStandard.Render("Ring"),cArt)
dnAssert("an empty text",len(oStandard.Render("")) < len(cArt),1)

dnTestSummary()
