# Bogus: fake data; a seeded generator gives the same numbers every time
load "pkg.ring"
pkgUse("bogus",[["Bogus","35.6.5"]],[["Bogus.dll",["Bogus","Bogus.DataSets"]]])
pkgImport("bogus","Bogus.dll","Bogus")
pkgImport("bogus","Bogus.dll","Bogus.DataSets")

oFaker = new Faker()
oPerson = oFaker.Name
cName = oPerson.FullName(NULL)
dnAssert("a name has a space",substr(cName," ") > 0,1)
dnAssert("an email has an @",substr(oFaker.Internet.Email(NULL),"@") > 0,1)
dnAssert("a city is a text",len(oFaker.Address.City()) > 0,1)
dnAssert("a sentence ends with a dot",right(oFaker.Lorem.Sentence(NULL),1),".")
nDice = oFaker.Random.Number([ :min = 1, :max = 6 ])
dnAssert("a number in the range",nDice >= 1 and nDice <= 6,1)
dnAssert("an item of a list",find(["red","green","blue"],oFaker.PickRandom([ :items = ["red","green","blue"] ])) > 0,1)
dnAssert("a date in the past is before now",oFaker.Date.Past(NULL).ToString() != "",1)

# the same seed, the same numbers
oFirst = dnNew("Bogus.Randomizer",[42])
oSecond = dnNew("Bogus.Randomizer",[42])
dnAssert("a seeded randomizer repeats",oFirst.Number([ :min = 1, :max = 1000 ]),oSecond.Number([ :min = 1, :max = 1000 ]))
dnAssert("and again",oFirst.Number([ :min = 1, :max = 1000 ]),oSecond.Number([ :min = 1, :max = 1000 ]))

dnTestSummary()
