# writing JSON as a stream - Utf8JsonWriter, indentation, nesting, escaping, and JsonSerializer options
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Text"
	"System.Text.Json"
}

func main
	# 1. Utf8JsonWriter writes a JSON text piece by piece into a stream, without building a tree in memory first.
	#    It is the right tool for big documents and for output that must be exactly formatted.
	oStream = new MemoryStream
	oOptions = new JsonWriterOptions()
	oOptions.Indented = True
	oWriter = dnNew("Utf8JsonWriter",[ :utf8Json = oStream, :options = oOptions ])
	oWriter.WriteStartObject(NULL)
	oWriter.WriteString("name","Ann")
	oWriter.WriteNumber("age",31)
	oWriter.WriteBoolean("active",True)
	oWriter.WriteNull("manager")
	oWriter.WriteStartArray("skills")
	oWriter.WriteStringValue("ring")
	oWriter.WriteStringValue(".NET")
	oWriter.WriteEndArray()
	oWriter.WriteStartObject("address")
	oWriter.WriteString("city","Cairo")
	oWriter.WriteEndObject()
	oWriter.WriteEndObject()
	oWriter.Flush()                      # the writer keeps a buffer: Flush sends it to the stream
	cJson = new UTF8Encoding().GetString(oStream.ToArray())
	? "1. the document:"
	? substr(cJson,char(13),"")
	oWriter.Dispose()

	# 2. The same document in one line (not indented): the writer adds no spaces
	oStream2 = new MemoryStream
	oWriter2 = new Utf8JsonWriter(oStream2)
	oWriter2.WriteStartArray(NULL)
	for n = 1 to 3
		oWriter2.WriteNumberValue(n * n)
	next
	oWriter2.WriteEndArray()
	oWriter2.Flush()
	? nl + "2. one line: " + new UTF8Encoding().GetString(oStream2.ToArray())
	oWriter2.Dispose()

	# 3. Escaping is done for you. The writer also refuses a document that is not valid: a value without a property name inside an
	#    object, or an end without a start, raises an error (that is a test of your own program).
	oStream3 = new MemoryStream
	oWriter3 = new Utf8JsonWriter(oStream3)
	oWriter3.WriteStartObject(NULL)
	oWriter3.WriteString("text",'a "quoted" line' + nl + 'and a <tag> & more')
	oWriter3.WriteEndObject()
	oWriter3.Flush()
	? nl + "3. escaped: " + new UTF8Encoding().GetString(oStream3.ToArray())
	lError = False
	try
		oWriter3.WriteEndObject()           # there is no object to end
	catch
		lError = True
	done
	? "   an end without a start is an error: " + lError

	# 4. JsonSerializer turns .NET objects into JSON; JsonSerializerOptions choose the form. A list of numbers and a dictionary:
	oSerializer = new JsonSerializer()
	oNumbers = dnNewGeneric("System.Collections.Generic.List",["System.Int32"],[])
	for n in [3,1,2]
		oNumbers.Add(n)
	next
	? nl + "4. a list: " + oSerializer.Serialize(oNumbers)
	oScores = dnNewGeneric("System.Collections.Generic.Dictionary",["System.String","System.Double"],[])
	oScores.Add("ann",9.5)
	oScores.Add("bob",7)
	? "   a dictionary: " + oSerializer.Serialize(oScores)
	oIndent = new JsonSerializerOptions()
	oIndent.WriteIndented = True
	? "   indented: " + substr(substr(oSerializer.Serialize([ :value = oScores, :options = oIndent ]),char(13),""),nl," ")
