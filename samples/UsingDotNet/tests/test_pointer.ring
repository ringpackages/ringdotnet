# Pointer parameters and results: a number is an address, a text, a byte string, a list or a buffer is pinned for the call
load "dotnet.ring"
dnImport("System")
dnImport("System.Text")
dnImport("System.Runtime.InteropServices")

# a pointer that a method returns is a number
nMemory = dnStatic("System.Runtime.InteropServices.NativeMemory","Alloc",[16])
dnAssert("a void* result is a number",isnumber(nMemory) and nMemory > 0,1)

# a number as the address, a text as the buffer: Buffer.MemoryCopy(void*, void*, long, long)
dnStatic("System.Buffer","MemoryCopy",["hello",nMemory,16,5])
dnAssert("a text copied to the address",dnStatic("System.Runtime.InteropServices.Marshal","PtrToStringAnsi",[nMemory,5]),"hello")

# a byte string
dnStatic("System.Buffer","MemoryCopy",[char(65) + char(66) + char(0),nMemory,16,3])
dnAssert("a byte string copied to the address",dnStatic("System.Runtime.InteropServices.Marshal","PtrToStringAnsi",[nMemory,2]),"AB")

# a list of numbers is bytes for a void*
dnStatic("System.Buffer","MemoryCopy",[ [2, 1, 0, 0, 7],nMemory,16,5])
dnAssert("a list of numbers for a void*",dnStatic("System.Runtime.InteropServices.Marshal","ReadInt32",[nMemory]),258)

# a buffer that the method fills: the address as the source, a ByteBuffer as the destination
oBuffer = dnBuffer(4)
dnStatic("System.Buffer","MemoryCopy",[nMemory,oBuffer,4,4])
dnAssert("a ByteBuffer filled through a byte*",ascii(dnBufferBytes(oBuffer,4)[1]),2)

# a pointer that a method takes as a C string: Encoding.GetString(byte*, int)
oUtf8 = new UTF8Encoding()
dnStatic("System.Buffer","MemoryCopy",["text",nMemory,16,4])
dnAssert("GetString(byte*, int) with an address",oUtf8.callMethod("GetString",[nMemory,4]),"text")

dnStatic("System.Runtime.InteropServices.NativeMemory","Free",[nMemory])
dnTestSummary()
