# UnitsNet: quantities with units (structs with many static factories and properties), conversions, operators between objects, parsing
load "pkg.ring"
pkgUse("unitsnet",[["UnitsNet","5.75.1"]],[["UnitsNet.dll",["UnitsNet"]]])
pkgImport("unitsnet","UnitsNet.dll","UnitsNet")

oLength = dnStatic("UnitsNet.Length","FromMeters",[1000])
dnAssert("meters to kilometers",oLength.Kilometers,1)
dnAssert("meters to feet",floor(oLength.Feet),3280)
dnAssert("the value in its unit",oLength.Value,1000)

oMile = dnStatic("UnitsNet.Length","FromMiles",[1])
dnAssert("a mile in meters",floor(oMile.Meters),1609)

# operators between quantities, and with a number
oSum = oLength + oMile
dnAssert("a sum of lengths",floor(oSum.Meters),2609)
dnAssert("a difference",floor((oLength - oMile).Meters),-610)
bLonger = oLength < oMile
dnAssert("lengths compare",bLonger,1)
dnAssert("a quantity times a number",(oLength * 2).Meters,2000)
dnAssert("a quantity over a number",(oLength / 4).Meters,250)

# other kinds
oMass = dnStatic("UnitsNet.Mass","FromKilograms",[2.5])
dnAssert("kilograms to grams",oMass.Grams,2500)
dnAssert("kilograms to pounds",floor(oMass.Pounds * 100),551)
oTemperature = dnStatic("UnitsNet.Temperature","FromDegreesCelsius",[100])
dnAssert("Celsius to Fahrenheit",oTemperature.DegreesFahrenheit,212)
dnAssert("Celsius to Kelvin",oTemperature.Kelvins,373.15)

# the product of quantities of different kinds is another kind
oSpeed = dnStatic("UnitsNet.Speed","FromMetersPerSecond",[10])
dnAssert("a speed in km/h",floor(oSpeed.KilometersPerHour),36)

# a quantity as a text
dnAssert("a quantity as text",dnStatic("UnitsNet.Length","FromMeters",[5]).ToString(),"5 m")

# parsing
oParsed = dnStatic("UnitsNet.Length","Parse",["5 km"])
dnAssert("parse a length",oParsed.Meters,5000)

dnTestSummary()
