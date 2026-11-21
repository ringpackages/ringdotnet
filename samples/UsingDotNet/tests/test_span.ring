# Methods with a Span<T> or ReadOnlySpan<T> parameter: Ring gives a text, a byte string or a list, and a number is the size of a buffer to fill
load "dotnet.ring"
dnImport("System")

# a Span<byte> that the method writes to: the answer has the result and the filled buffer
aResult = dnStatic("System.BitConverter","TryWriteBytes",[8, 258])
dnAssert("TryWriteBytes answers a list",islist(aResult),1)
dnAssert("TryWriteBytes fits",aResult[1],1)
dnAssert("the buffer has the size",len(aResult[2]),8)
dnAssert("the first byte",ascii(aResult[2][1]),2)
dnAssert("the second byte",ascii(aResult[2][2]),1)
aResult = dnStatic("System.BitConverter","TryWriteBytes",[1, 258])
dnAssert("a buffer that is too small",aResult[1],0)

# a buffer that Ring made: the bytes are the content
aResult = dnStatic("System.BitConverter","TryWriteBytes",[copy(char(0),4), 7])
dnAssert("a byte string as the buffer",ascii(aResult[2][1]),7)

# a ReadOnlySpan<byte> in and a Span<char> out, with an out parameter
aResult = dnStatic("System.Convert","TryToBase64Chars",["Ring",16])
dnAssert("base64 of a text, done",aResult[1],1)
dnAssert("base64 of a text, the chars",left(aResult[2],aResult[3]),"UmluZw==")

# a ReadOnlySpan<char> from a text
aResult = dnStatic("System.Int32","TryParse",["123"])
dnAssert("TryParse of a text",aResult[2],123)

# the same, in a list of bytes
aResult = dnStatic("System.Convert","TryToBase64Chars",[[82,105,110,103],16])
dnAssert("a list of numbers as the bytes",left(aResult[2],aResult[3]),"UmluZw==")

# named arguments
aResult = dnRequest("callnamed",[dnType("System.BitConverter"),"TryWriteBytes",[ [:destination,4], [:value,7] ]])
dnAssert("named arguments",aResult[1],1)

dnTestSummary()
