# IdGen: Twitter Snowflake style identifiers: a number made of the time, a generator number and a sequence; structure, order and decoding.
# A Ring number is a double: an identifier of 63 bits loses its lowest bits, so the checks use the time and the generator number (the high bits)
load "pkg.ring"
pkgUse("idgen",[["IdGen","3.0.7"]],[["IdGen.dll",["IdGen"]]])
pkgImport("idgen","IdGen.dll","IdGen")

oStructure = new IdStructure(41,10,12)
dnAssert("the timestamp bits",oStructure.TimestampBits,41)
dnAssert("the generator bits",oStructure.GeneratorIdBits,10)
dnAssert("the sequence bits",oStructure.SequenceBits,12)
dnAssert("the number of generators",oStructure.MaxGenerators,1024)
dnAssert("the identifiers in a millisecond",oStructure.MaxSequenceIds,4096)

# the bits of a structure must be 63 in all
lError = 0
try
	oBad = new IdStructure(30,10,12)
catch
	lError = 1
done
dnAssert("a structure of the wrong size raises an error",lError,1)

oGenerator = new IdGenerator(5)
nFirst = oGenerator.CreateId()
dnStatic("System.Threading.Thread","Sleep",[20])
nSecond = oGenerator.CreateId()
dnStatic("System.Threading.Thread","Sleep",[20])
nThird = oGenerator.CreateId()
dnAssert("an identifier is a big number",nFirst > 1000000000,True)
dnAssert("a later identifier is bigger",nSecond > nFirst,True)
dnAssert("and a later one again",nThird > nSecond,True)

# an identifier is decoded to its parts
oPart = oGenerator.FromId(nFirst)
dnAssert("the generator number",oPart.GeneratorId,5)
dnAssert("the time is this year",oPart.DateTimeOffset.Year >= 2024,True)
oLater = oGenerator.FromId(nThird)
dnAssert("a later identifier has a later time",oLater.DateTimeOffset.Ticks > oPart.DateTimeOffset.Ticks,True)

# the generators are told apart by their numbers
oOther = new IdGenerator(6)
dnAssert("another generator number",oOther.FromId(oOther.CreateId()).GeneratorId,6)
dnAssert("the options of a generator",oOther.Options.IdStructure.GeneratorIdBits,10)

# a generator number outside the structure is an error
lError = 0
try
	oTooBig = new IdGenerator(5000)
catch
	lError = 1
done
dnAssert("a generator number that does not fit raises an error",lError,1)

dnTestSummary()
