# sound - SoundPlayer is a framework class that has no Ring class in the package: wrapassembly.ring makes one from the DLL of the framework.
#   The sound is a WAV file made in memory from Ring numbers (a Ring text can hold any byte). Run it with --play to hear it.
load "dotnet.ring"

using {
	"System.IO"
	"System.Windows.Forms"
}

if not iswindows()
	? "SoundPlayer is a class of Windows, so this lesson runs on Windows only."
	bye
ok

cHere = currentdir()
cClasses = cHere + "/Sound/classes"

# STEP 1. Where is the DLL? SoundPlayer is in System.Windows.Extensions.dll, in the folder of the desktop runtime, where
# System.Windows.Forms.dll is too: the program asks a Windows Forms class for its folder instead of writing the path of one computer.
func main

	cFormsDll = new Label().GetType().Assembly.Location
	cFolder = new Path().GetDirectoryName(cFormsDll)
	cDll = new Path().Combine([cFolder,"System.Windows.Extensions.dll"])
	? "the DLL is next to System.Windows.Forms.dll: " + new File().Exists(cDll)

	# STEP 2. Make Ring classes for the namespace System.Media of that DLL, and load them
	chdir("../../../tools/dotnettools")
	system(exefilename() + ' wrapassembly.ring "' + cDll + '" "' + cClasses + '" System.Media > nul')
	chdir(cHere)
	dnLoad(cDll)
	dnImportFrom(cClasses + "/","System.Media")

	# STEP 3. A sound: a WAV file is a header and the samples. One second at 8000 samples a second would be 16000 bytes; a quarter of a
	# second of the note A (440 hertz) is enough.
	nRate = 8000
	nSamples = nRate / 4
	cData = ""
	for nSample = 0 to nSamples - 1
		nValue = floor(sin(2 * 3.14159265 * 440 * nSample / nRate) * 12000)
		if nValue < 0 nValue += 65536 ok               # a 16-bit sample below 0 is stored as 65536 minus its size
		cData += char(nValue % 256) + char(floor(nValue / 256))
	next
	cWav = "RIFF" + le32(36 + len(cData)) + "WAVE"
	cWav += "fmt " + le32(16) + le16(1) + le16(1) + le32(nRate) + le32(nRate * 2) + le16(2) + le16(16)          # PCM, one channel, 16 bits
	cWav += "data" + le32(len(cData)) + cData
	? "samples: " + nSamples + ", bytes of the file: " + len(cWav)

	# STEP 4. The bytes go to a MemoryStream, and the stream to a SoundPlayer
	oStream = new MemoryStream().@New([ :buffer = cWav ])          # the constructor is chosen by the name of its parameter
	oPlayer = new SoundPlayer().@New([ :stream = oStream ])
	oPlayer.@Load()
	? "the sound is loaded: " + oPlayer.IsLoadCompleted

	if find(sysargv,"--play") > 0
		? "playing..."
		oPlayer.PlaySync()
	else
		? "(run the program with --play to hear it)"
	ok

# a number as bytes, the lowest byte first (little endian)
func le16 nNumber

	return char(nNumber % 256) + char(floor(nNumber / 256) % 256)

func le32 nNumber

	return le16(nNumber % 65536) + le16(floor(nNumber / 65536))
