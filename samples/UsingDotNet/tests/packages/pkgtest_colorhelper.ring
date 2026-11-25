# ColorHelper: colors in several models (RGB, HEX, HSL, HSV, CMYK) converted from one to another; the models are structs with a constructor and a
# converter class with static methods
load "pkg.ring"
pkgUse("colorhelper",[["ColorHelper","1.8.1"]],[["ColorHelper.dll",["ColorHelper"]]])
pkgImport("colorhelper","ColorHelper.dll","ColorHelper")

oRed = dnNew("ColorHelper.RGB",[255,0,0])
dnAssert("the red of an RGB color",oRed.R,255)
dnAssert("the green",oRed.G,0)
oHex = dnStatic("ColorHelper.ColorConverter","RgbToHex",[oRed])
dnAssert("a color as HEX",oHex.Value,"FF0000")
oHsl = dnStatic("ColorHelper.ColorConverter","RgbToHsl",[oRed])
dnAssert("the hue of red",oHsl.H,0)
dnAssert("the saturation",oHsl.S,100)
dnAssert("the lightness",oHsl.L,50)

# another color, through several models and back
oBlue = dnNew("ColorHelper.RGB",[0,0,255])
oHsv = dnStatic("ColorHelper.ColorConverter","RgbToHsv",[oBlue])
dnAssert("the hue of blue is 240",oHsv.H,240)
dnAssert("the value",oHsv.V,100)
oCmyk = dnStatic("ColorHelper.ColorConverter","RgbToCmyk",[oBlue])
dnAssert("blue in CMYK: cyan",oCmyk.C,100)
dnAssert("blue in CMYK: yellow",oCmyk.Y,0)
oBack = dnStatic("ColorHelper.ColorConverter","HsvToRgb",[oHsv])
dnAssert("back to RGB: blue",oBack.B,255)
dnAssert("back to RGB: red",oBack.R,0)

# a HEX text read into a color
oFromHex = dnStatic("ColorHelper.ColorConverter","HexToRgb",[dnNew("ColorHelper.HEX",["336699"])])
dnAssert("HEX 336699: red",oFromHex.R,51)
dnAssert("HEX 336699: green",oFromHex.G,102)
dnAssert("HEX 336699: blue",oFromHex.B,153)

# a gray
oGray = dnNew("ColorHelper.RGB",[128,128,128])
oGrayHsl = dnStatic("ColorHelper.ColorConverter","RgbToHsl",[oGray])
dnAssert("a gray has no saturation",oGrayHsl.S,0)
dnAssert("a gray is half light",oGrayHsl.L,50)

# the model of a color is a struct that compares by value
dnAssert("two colors with the same channels are equal",oRed.Equals(dnNew("ColorHelper.RGB",[255,0,0])),1)
dnAssert("two colors that differ are not",oRed.Equals(oBlue),0)

dnTestSummary()
