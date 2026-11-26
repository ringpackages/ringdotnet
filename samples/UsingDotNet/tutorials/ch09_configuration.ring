# configuration - settings from a JSON file, from memory and from environment variables, layered so that the last one wins
load "dotnet.ring"

using {
	"System"
	"System.IO"
	"Microsoft.Extensions.Configuration"
	"RingDotNet.Web"                  # the configuration providers are part of the ASP.NET Core runtime: this line starts it
}

func main

	# A program needs settings that are not in its code: a port, a name, a path, the address of a database. The configuration system of
	# .NET reads them from SEVERAL sources and puts them into one tree of keys. Sources added later override sources added earlier:
	# defaults in a file, changes for a computer in the environment, a value for one run on the command line.
	cFile = new Path().Combine([new Path().GetTempPath(),"ringdotnet_configuration.json"])
	cJson = '{ "App": { "Name": "Demo", "Port": 8080, "Debug": false, "Features": [ "search", "export" ] }, "Database": { "Host": "localhost", "Timeout": 30 } }'
	new File().WriteAllText([ :path = cFile, :contents = cJson ])

	oBuilder = new ConfigurationBuilder
	oBuilder = oBuilder.AddJsonFile([ :path = cFile ])

	# 1. Keys are paths: "App:Name" is the key Name inside the section App. A list in the JSON becomes numbered keys (Features:0, Features:1).
	oConfig = oBuilder.Build()
	? "1. App:Name = " + oConfig.Item("App:Name") + ", App:Port = " + oConfig.Item("App:Port")
	? "   App:Features:1 = " + oConfig.Item("App:Features:1")
	? "   a key that does not exist is null: " + oConfig.Item("App:Missing").isNull()

	# 2. Every value is TEXT. GetValue converts it to the type you ask for, and takes a default for a missing key
	cBinder = "Microsoft.Extensions.Configuration.ConfigurationBinder"
	nPort = dnStatic(cBinder,"GetValue",[oConfig,dnType("System.Int32"),"App:Port"])
	lDebug = dnStatic(cBinder,"GetValue",[oConfig,dnType("System.Boolean"),"App:Debug"])
	nMissing = dnStatic(cBinder,"GetValue",[oConfig,dnType("System.Int32"),"App:Retries",3])
	? nl + "2. the port as a number: " + nPort + " (+1 = " + (nPort + 1) + "), debug as a yes or no: " + lDebug + ", Retries (not set, default 3): " + nMissing

	# 3. A section: GetSection gives a part of the tree. Its Key is the last name; GetChildren lists what is directly inside
	oSection = oConfig.GetSection("Database")
	? nl + "3. the section " + oSection.Key + " has:"
	aChildren = oSection.GetChildren().toList()
	for oChild in aChildren
		? "   " + oChild.Key + " = " + oChild.Value
	next

	# 4. More sources. AddInMemoryCollection adds values from a dictionary (good for defaults and for tests). Because it comes AFTER the
	#    file, its values win.
	oOverrides = new Dictionary([ :typeArguments = ["System.String","System.String"] ])
	oOverrides.Add("App:Port","9090")
	oOverrides.Add("App:Extra","only in memory")
	oBuilder.AddInMemoryCollection([ :initialData = oOverrides ])
	oConfig2 = oBuilder.Build()
	? nl + "4. after the memory source: App:Port = " + oConfig2.Item("App:Port") + " (was 8080), App:Name = " + oConfig2.Item("App:Name") + " (not changed), App:Extra = " + oConfig2.Item("App:Extra")

	# 5. Environment variables. With a prefix, only the variables that start with it are read, and "__" in the name means ":" in the key.
	#    This is how a server or a container changes a setting without a new file.
	new Environment().SetEnvironmentVariable([ :variable = "RDN111_Database__Host", :value = "db.example.com" ])
	oBuilder.AddEnvironmentVariables([ :prefix = "RDN111_" ])
	oConfig3 = oBuilder.Build()
	? nl + "5. the environment variable RDN111_Database__Host changes Database:Host to: " + oConfig3.Item("Database:Host")
	? "   Database:Timeout is still from the file: " + oConfig3.Item("Database:Timeout")
	new Environment().SetEnvironmentVariable([ :variable = "RDN111_Database__Host", :value = NULL ])

	# 6. Where the value came from does not matter to the code that reads it. The order of the sources is the only rule: the last wins.
	#    Secrets (passwords, keys) do not belong in a file that is kept with the code: use environment variables or a secrets store.
	new File().Delete(cFile)
