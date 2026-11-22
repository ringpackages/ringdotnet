# Math.NET Numerics: special functions, statistics, matrices and vectors (builders, operators, indexers with two indexes)
load "pkg.ring"
pkgUse("mathnet",[["MathNet.Numerics","5.0.0"]],[["MathNet.Numerics.dll",["MathNet.Numerics","MathNet.Numerics.Statistics","MathNet.Numerics.LinearAlgebra"]]])
pkgImport("mathnet","MathNet.Numerics.dll","MathNet.Numerics")
pkgImport("mathnet","MathNet.Numerics.dll","MathNet.Numerics.Statistics")
pkgImport("mathnet","MathNet.Numerics.dll","MathNet.Numerics.LinearAlgebra")

dnAssert("Gamma",dnStatic("MathNet.Numerics.SpecialFunctions","Gamma",[5]),24)
dnAssert("Factorial",dnStatic("MathNet.Numerics.SpecialFunctions","Factorial",[10]),3628800)
dnAssert("Combinations",dnStatic("MathNet.Numerics.Combinatorics","Combinations",[5,2]),10)

aData = [2.5, 3.5, 1.0, 4.0, 9.5]
dnAssert("Mean",dnStatic("MathNet.Numerics.Statistics.Statistics","Mean",[aData]),4.1)
dnAssert("Median",dnStatic("MathNet.Numerics.Statistics.Statistics","Median",[aData]),3.5)
dnAssert("StandardDeviation",floor(dnStatic("MathNet.Numerics.Statistics.Statistics","StandardDeviation",[aData]) * 1000),3228)

oBuild = dnType("MathNet.Numerics.LinearAlgebra.Matrix`1[[System.Double]]").getProp("Build")
oA = oBuild.DenseOfRowArrays([ [2,1], [1,3] ])
oB = oBuild.DenseOfRowArrays([ [1,0], [0,1] ])
oC = oA + oB
dnAssert("a sum of matrices",oC.Item([0,0]),3)
dnAssert("a sum of matrices, another cell",oC.Item([1,1]),4)
dnAssert("a determinant",oA.Determinant(),5)
oInverse = oA.Inverse()
dnAssert("an inverse, by an indexer with two indexes",floor(oInverse.Item([0,0]) * 10),6)
dnAssert("an inverse, a negative cell",oInverse.Item([0,1]) < 0,1)
dnAssert("a transpose (the call without arguments of an overloaded method)",oA.Transpose(NULL).Item([0,1]),1)
oV = dnType("MathNet.Numerics.LinearAlgebra.Vector`1[[System.Double]]").getProp("Build").DenseOfArray([1,2])
oProduct = oA * oV
dnAssert("a matrix times a vector",oProduct.Item(0),4)
dnAssert("a matrix times a vector, the second item",oProduct.Item(1),7)
oMatrix2 = oA.SetItem([0,0],9)
dnAssert("a cell that was set",oA.Item([0,0]),9)

dnTestSummary()
