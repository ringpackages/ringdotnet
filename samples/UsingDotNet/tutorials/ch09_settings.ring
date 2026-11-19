# settings - defaults, a JSON file, loading, saving, and special folders
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Text.Json"
}

func main
	# Where do programs keep their files? .NET knows the special folders of the user.
	oEnvironment = new Environment()
	? "Special folders exist:"
	for cFolder in ["MyDocuments","ApplicationData","LocalApplicationData","Desktop"]
		? "   " + cFolder + " : " + (len(oEnvironment.GetFolderPath(cFolder)) > 0)
	next

	# For this tutorial the file is in the temp folder
	cFile = new Path().Combine([new Path().GetTempPath(),"tutorial32-settings.json"])
	if new File().Exists(cFile)
		new File().Delete(cFile)
	ok

	# 1. The first run: there is no file, so the settings have their default values
	oSettings = new Settings(cFile)
	? nl + "First run"
	showSettings(oSettings)

	# 2. The user changes some settings, the program saves them
	oSettings.setValue("name","Ann")
	oSettings.setValue("fontSize",14)
	oSettings.setValue("darkMode",1)
	oSettings.save()
	? nl + "The file now contains: " + new File().ReadAllText(cFile)

	# 3. The next run: a new Settings object reads the file again
	oAgain = new Settings(cFile)
	? nl + "Second run"
	showSettings(oAgain)

	# 4. A file that is damaged must not stop the program: use the defaults
	new File().WriteAllText([ :path = cFile, :contents = "this is not json {" ])
	oBroken = new Settings(cFile)
	? nl + "A damaged file: the defaults are used, error was: " + (len(oBroken.cLoadError) > 0)
	showSettings(oBroken)
	new File().Delete(cFile)

func showSettings oSettings
	? "   name     = " + oSettings.getValue("name")
	? "   fontSize = " + oSettings.getValue("fontSize")
	? "   darkMode = " + oSettings.getValue("darkMode")

# A class for settings: a list of [key, value], defaults, loading and saving
class Settings

	aValues = []
	cFile = ""
	cLoadError = ""

	func init cPath
		cFile = cPath
		# the defaults: the keys that exist, and what they are before the user changes them
		aValues = [["name","Guest"],["fontSize",11],["darkMode",0]]
		readFile()

	func getValue cKey
		for aPair in aValues
			if aPair[1] = cKey
				return aPair[2]
			ok
		next
		return ""

	func setValue cKey, xValue
		for nIndex = 1 to len(aValues)
			if aValues[nIndex][1] = cKey
				aValues[nIndex][2] = xValue
			ok
		next

	# the file holds a JSON object: {"name":"Ann","fontSize":14,"darkMode":1}
	func save
		cJson = "{"
		for nIndex = 1 to len(aValues)
			if nIndex > 1
				cJson += ","
			ok
			xValue = aValues[nIndex][2]
			if isstring(xValue)
				xValue = '"' + xValue + '"'
			ok
			cJson += '"' + aValues[nIndex][1] + '":' + xValue
		next
		cJson += "}"
		new File().WriteAllText([ :path = cFile, :contents = cJson ])

	# (named readFile: "load" is a Ring keyword)
	func readFile
		cLoadError = ""
		if not new File().Exists(cFile)
			return
		ok
		try
			oDocument = new JsonDocument().Parse(new File().ReadAllText(cFile))
			oRoot = oDocument.RootElement
			for nIndex = 1 to len(aValues)
				aFound = oRoot.TryGetProperty(aValues[nIndex][1])         # [found, element]
				if aFound[1]
					if isstring(aValues[nIndex][2])
						aValues[nIndex][2] = aFound[2].GetString()
					else
						aValues[nIndex][2] = aFound[2].GetInt32()
					ok
				ok
			next
			oDocument.Dispose()
		catch
			cLoadError = cCatchError
		done
