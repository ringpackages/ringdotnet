# Makes tiny.onnx, the model of pkgtest_onnxruntime.ring: Y = Relu(Gemm(X, W, B)) with X of 1 x 3, W = [[1,0],[0,1],[1,-1]] and B = [0.5,-10].
# An ONNX file is a protocol buffer: every field is a key (field number and wire type) and then a number (varint) or a length and its bytes.
#     ring make_tiny_onnx.ring

cFile = "tiny.onnx"
if len(sysargv) > 2
	cFile = sysargv[3]
ok

cGraph = field(1,node("Gemm",["X","W","B"],["H"],"gemm")) +
	field(1,node("Relu",["H"],["Y"],"relu")) +
	text(2,"tiny") +
	field(5,tensor("W",[3,2],[1,0,0,1,1,-1])) +
	field(5,tensor("B",[2],[0.5,-10])) +
	field(11,valueInfo("X",[1,3])) +
	field(12,valueInfo("Y",[1,2]))
cModel = number(1,8) + text(2,"ring") + field(7,cGraph) + field(8,number(2,13))
write(cFile,cModel)
? "" + len(cModel) + " bytes in " + cFile

# the bytes of a whole number, seven bits at a time, the last byte has no high bit
func varint nValue

	cBytes = ""
	while true
		nByte = nValue % 128
		nValue = floor(nValue / 128)
		if nValue > 0
			cBytes += char(nByte + 128)
		else
			cBytes += char(nByte)
			return cBytes
		ok
	end

func key nField, nWire

	return varint(nField * 8 + nWire)

# a field that is a whole number
func number nField, nValue

	return key(nField,0) + varint(nValue)

# a field that is bytes (a text or a message inside a message): the length and then the bytes
func field nField, cBytes

	return key(nField,2) + varint(len(cBytes)) + cBytes

func text nField, cText

	return field(nField,cText)

# the items of a list as 32 bit floats, little endian
func floats aValues

	cBytes = ""
	for nValue in aValues
		cBytes += float2bytes(nValue)
	next
	return cBytes

# a tensor of floats: the dimensions (1), the type 1 = float (2), the name (8) and the values as raw bytes (9)
func tensor cName, aDims, aValues

	cBytes = ""
	for nDim in aDims
		cBytes += number(1,nDim)
	next
	return cBytes + number(2,1) + text(8,cName) + field(9,floats(aValues))

# the name and the type of an input or an output: a tensor of floats with a shape
func valueInfo cName, aDims

	cShape = ""
	for nDim in aDims
		cShape += field(1,number(1,nDim))
	next
	cTensorType = number(1,1) + field(2,cShape)
	return text(1,cName) + field(2,field(1,cTensorType))

func node cOperator, aInputs, aOutputs, cName

	cBytes = ""
	for cInput in aInputs
		cBytes += text(1,cInput)
	next
	for cOutput in aOutputs
		cBytes += text(2,cOutput)
	next
	return cBytes + text(3,cName) + text(4,cOperator)
