# Batch: Reflection, Interop, Numerics, Timers, Pipes, Win32, Security, Mail, Tar, Concurrent, Encoders ...
load "../libraries/dotnetlib/dotnetlib.ring"
dnImport("System")
dnImport("System.IO")
dnImport("System.Reflection")
dnImport("System.Runtime.InteropServices")
dnImport("System.Numerics")
dnImport("System.Timers")
dnImport("System.IO.Pipes")
dnImport("System.Threading.Tasks")
dnImport("System.Security.Principal")
dnImport("System.Net.Mail")
dnImport("System.Text.Encodings.Web")
dnImport("System.Formats.Tar")
dnImport("System.Collections.Concurrent")
dnImport("System.Security.Cryptography.X509Certificates")
dnImport("Microsoft.Win32")

# Reflection
oType = new Type().GetType_1("System.Math")
dnAssert("Type.FullName",oType.FullName,"System.Math")
dnAssert("Type.IsAbstract static class",oType.IsAbstract,1)
aMethods = oType.GetMethods().toList()
dnAssert("Type.GetMethods",len(aMethods) > 20,1)
dnAssert("MethodInfo wrapped",isobject(aMethods[1]) and isattribute(aMethods[1],"Name"),1)
oAsm = new Assembly().Load_("System.Linq")
dnAssert("Assembly.GetName",oAsm.GetName().Name,"System.Linq")
oProp = new Type().GetType_1("System.String").GetProperty("Length")
dnAssert("PropertyInfo.PropertyType",oProp.PropertyType.Name,"Int32")
dnAssert("Activator via Type",new Activator().CreateInstance_1(new Type().GetType_1("System.Text.StringBuilder")).ToString(),"")

# Interop and runtime information
dnAssert("RuntimeInformation.OSDescription",len(new RuntimeInformation().OSDescription) > 0,1)
dnAssert("RuntimeInformation.ProcessArchitecture",new RuntimeInformation().ProcessArchitecture,"X64")
dnAssert("Marshal.SizeOf int",new Marshal().SizeOf_1(new Type().GetType_1("System.Int64")),8)

# Big numbers
oBig = new BigInteger().Parse("123456789012345678901234567890")
dnAssert("BigInteger.Multiply",new BigInteger().Multiply(oBig,2).ToString(),"246913578024691357802469135780")
dnAssert("BigInteger.Pow",new BigInteger().Pow(2,100).ToString(),"1267650600228229401496703205376")
dnAssert("BigInteger.IsEven",oBig.IsEven,1)
oComplex = new Complex().New_2(3,4)
dnAssert("Complex.Magnitude",oComplex.Magnitude,5)
dnAssert("Vector2",new Vector2().New_2(3,4).Length(),5)

# Timers (no ticks: events run only on the Ring thread)
oTimer = new TimersTimer()
oTimer.Interval = 250
dnAssert("Timer.Interval",oTimer.Interval,250)
dnAssert("Timer.Enabled default",oTimer.Enabled,0)

# Named pipes on one thread: the server waits in a task
cPipe = "ringdotnet_" + random(1000000)
oServer = new NamedPipeServerStream(cPipe)
oWaiting = oServer.WaitForConnectionAsync()
oClient = new NamedPipeClientStream(".",cPipe)
oClient.Connect()
oWaiting.Wait()
oReading = new StreamReader(oServer).ReadLineAsync()	# pipes without buffers: the reader has to be waiting before the write
oWriter = new StreamWriter(oClient)
oWriter.AutoFlush = 1
oWriter.WriteLine("through a pipe")
oReading.Wait()
dnAssert("pipe line",oReading.getProp("Result"),"through a pipe")
oClient.Close()  oServer.Close()

# Windows only: registry and identity
if iswindows()
	oKey = new Registry().CurrentUser.CreateSubKey("RingDotNetTest")
	oKey.SetValue("answer",42)
	dnAssert("Registry round trip",number(oKey.GetValue("answer")),42)
	oKey.Close()
	new Registry().CurrentUser.DeleteSubKey("RingDotNetTest")
	dnAssert("WindowsIdentity",len(new WindowsIdentity().GetCurrent().Name) > 0,1)
ok

# Mail messages (no sending), encoders
oMail = new MailMessage()
oMail.Subject = "Hello"
oMail.setFrom(new MailAddress("a@example.com"))
oMail.getTo().Add("b@example.com")
dnAssert("MailMessage.To",oMail.getTo().Count,1)
dnAssert("HtmlEncoder",new HtmlEncoder().Default.Encode("<a & b>"),"&lt;a &amp; b&gt;")
dnAssert("UrlEncoder",new UrlEncoder().Default.Encode("a b"),"a%20b")

# Tar
cTemp = new Path().Combine(new Path().GetTempPath(),"ringdotnet_tar_" + random(100000))
new Directory().CreateDirectory(cTemp)
new File().WriteAllText(new Path().Combine(cTemp,"one.txt"),"1")
cTar = cTemp + ".tar"
new TarFile().CreateFromDirectory(cTemp,cTar,0)
dnAssert("TarFile created",new File().Exists(cTar),1)
new Directory().Delete_2(cTemp,1)
new File().Delete(cTar)

# Concurrent collections
oQueue = new ConcurrentStringQueue()
oQueue.Enqueue("a")  oQueue.Enqueue("b")
aTry = oQueue.TryDequeue()
dnAssert("ConcurrentQueue.TryDequeue",aTry[2],"a")
oDict = new ConcurrentObjectDictionary()
dnAssert("ConcurrentDictionary.TryAdd",oDict.TryAdd("k",5),1)
dnAssert("ConcurrentDictionary.Count",oDict.Count,1)

# X509
dnAssert("X509Store available",new X509Store().New_2("My","CurrentUser").Name,"My")

nFail = dnTestSummary()
