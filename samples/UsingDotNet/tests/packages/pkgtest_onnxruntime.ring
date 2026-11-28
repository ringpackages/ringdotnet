# Microsoft.ML.OnnxRuntime: a neural network file (ONNX) is loaded and run: its inputs and outputs are read, a tensor goes in, the result is checked by hand.
# data/tiny.onnx is a model of two steps: Y = Relu(X * W + B) with X of 1 x 3, W = [[1,0],[0,1],[1,-1]] and B = [0.5,-10] (made by data/make_tiny_onnx.ring)
load "pkg.ring"
pkgUse("onnxruntime",[["Microsoft.ML.OnnxRuntime","1.20.1"]],[["Microsoft.ML.OnnxRuntime.dll",["Microsoft.ML.OnnxRuntime","Microsoft.ML.OnnxRuntime.Tensors"]]])
pkgImport("onnxruntime","Microsoft.ML.OnnxRuntime.dll","Microsoft.ML.OnnxRuntime")
pkgImport("onnxruntime","Microsoft.ML.OnnxRuntime.dll","Microsoft.ML.OnnxRuntime.Tensors")

oSession = new InferenceSession(cPkgHere + "/data/tiny.onnx")

# what the model says about itself
aInputs = oSession.InputNames.toList()
aOutputs = oSession.OutputNames.toList()
dnAssert("one input",len(aInputs),1)
dnAssert("the input name",aInputs[1],"X")
dnAssert("one output",len(aOutputs),1)
dnAssert("the output name",aOutputs[1],"Y")
oInput = oSession.InputMetadata.callMethod("get_Item",["X"])
dnAssert("the input is a tensor",oInput.IsTensor,True)
aShape = oInput.Dimensions.toList()
dnAssert("the input shape: rows",aShape[1],1)
dnAssert("the input shape: columns",aShape[2],3)

# run it: [1,2,3] gives Gemm = [1*1+3*1+0.5, 2*1-3*1-10] = [4.5, -11] and Relu makes [4.5, 0]
oTensor = makeTensor([1,3],[1,2,3])
dnAssert("the tensor has three items",oTensor.Length,3)
oValue = dnType("Microsoft.ML.OnnxRuntime.NamedOnnxValue").callGeneric("CreateFromTensor",["System.Single"],["X",oTensor])
oResults = oSession.Run([ oValue ])
aResults = oResults.toList()
dnAssert("one result",len(aResults),1)
dnAssert("the result name",aResults[1].Name,"Y")
aY = aResults[1].AsEnumerable([ :typeArguments = ["System.Single"] ]).toList()
dnAssert("the result has two items",len(aY),2)
dnAssert("the first value",aY[1],4.5)
dnAssert("the second value is cut to zero by Relu",aY[2],0)

# another input
oTensor2 = makeTensor([1,3],[0,20,0])
oValue2 = dnType("Microsoft.ML.OnnxRuntime.NamedOnnxValue").callGeneric("CreateFromTensor",["System.Single"],["X",oTensor2])
aY2 = oSession.Run([ oValue2 ]).toList()[1].AsEnumerable([ :typeArguments = ["System.Single"] ]).toList()
dnAssert("another input: the first value",aY2[1],0.5)
dnAssert("another input: the second value",aY2[2],10)

# a file that is not a model is an error
lError = 0
try
	oBad = new InferenceSession(cPkgHere + "/pkg.ring")
catch
	lError = 1
done
dnAssert("a file that is not a model raises an error",lError,1)

dnTestSummary()

# a tensor of floats with a shape: made from its shape, then filled by position
func makeTensor aShape, aValues

	oTensor = dnNewGeneric("Microsoft.ML.OnnxRuntime.Tensors.DenseTensor",["System.Single"],[ aShape ])
	nValues = len(aValues)
	for nValue = 1 to nValues
		oTensor.callMethod("SetValue",[nValue - 1,aValues[nValue]])
	next
	return oTensor
