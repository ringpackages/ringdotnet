# text to speech - System.Speech (a package from nuget.org) makes a voice of Windows speak, or writes the speech to a WAV file
#   (the project is in the folder Speech: Speech.csproj names the package for Windows, and Empty.cs is the one source file a project needs)
#   Run it with --speak to hear the voice; without it the program writes the speech to a file, silently.
load "dotnet.ring"
using { "System.IO" }

if not iswindows()
	? "The voices are part of Windows, so this lesson runs on Windows only."
	bye
ok

cHere = currentdir()
cDll = cHere + "/Speech/libs/System.Speech.dll"
cClasses = cHere + "/Speech/classes"

# STEP 1. Get the package (nuget.org the first time) with dotnet publish. The project says RuntimeIdentifier win-x64: the package has an
# empty version of the DLL for every system, and the real one only for Windows, which a publish for Windows puts in the folder.
if not fexists(cDll)
	? "getting the package..."
	system("dotnet publish Speech -c Release -o Speech/libs -nologo -v q > nul")
ok
if not fexists(cDll)
	? "The package could not be restored. It is downloaded from nuget.org the first time, so the computer needs the internet once."
	bye
ok

# STEP 2. Make Ring classes for the namespace that makes speech
chdir("../../../tools/dotnettools")
system(exefilename() + " wrapassembly.ring " + cDll + " " + cClasses + " System.Speech.Synthesis > nul")
chdir(cHere)

# STEP 3. Load the assembly and the classes
dnLoad(cDll)
dnImportFrom(cClasses + "/","System.Speech.Synthesis")

func main
	oVoice = new SpeechSynthesizer()

	# 1. The voices that are installed (the names depend on the computer, so the program only counts them)
	aVoices = oVoice.GetInstalledVoices(NULL).toList()
	? "1. installed voices: " + len(aVoices) + ", at least one: " + (len(aVoices) > 0)

	# 2. Speech goes to a file: SetOutputToWaveFile, then Speak. Rate is from -10 (slow) to 10 (fast): a slower voice needs more time,
	#    so its file is bigger.
	cFile = new Path().Combine([new Path().GetTempPath(),"ringdotnet-speech.wav"])
	cText = "Hello from Ring. This sentence is spoken by a voice of Windows."
	nSizeNormal = speakToFile(oVoice,cText,0,cFile)
	nSizeSlow = speakToFile(oVoice,cText,-5,cFile)
	nSizeFast = speakToFile(oVoice,cText,5,cFile)
	? "2. a WAV file was written: " + (nSizeNormal > 10000)
	? "   the slow voice makes a bigger file than the normal one, and the normal one a bigger file than the fast one: " + (nSizeSlow > nSizeNormal and nSizeNormal > nSizeFast)
	new File().Delete(cFile)

	# 3. To hear it, the output goes back to the speakers: SetOutputToDefaultAudioDevice, and Speak waits until the text is spoken
	if find(sysargv,"--speak") > 0
		oVoice.SetOutputToDefaultAudioDevice()
		oVoice.Rate = 0
		? "3. speaking..."
		oVoice.Speak(cText)
	else
		? "3. (run the program with --speak to hear it)"
	ok
	oVoice.Dispose()

# speaks a text to a WAV file with a rate and gives the size of the file
func speakToFile oVoice, cText, nRate, cFile
	oVoice.Rate = nRate
	oVoice.SetOutputToWaveFile(cFile)
	oVoice.Speak(cText)
	oVoice.SetOutputToNull()          # closes the file
	return new FileInfo(cFile).Length
