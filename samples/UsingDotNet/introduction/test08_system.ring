# Dates and times, strings, conversions and math from the .NET class library
load "dotnet.ring"

using { "System" }

# Dates and times
oNow = new DateTime(2024,12,25).AddHours(18.5)
? "Christmas 2024 : " + oNow.Format("dddd, dd MMMM yyyy HH:mm")
? "Plus 10 days   : " + oNow.AddDays(10).Format("yyyy-MM-dd")
? "Day of week    : " + oNow.DayOfWeek
oSpan = new TimeSpan().FromMinutes(135)
? "135 minutes    : " + oSpan.ToString() + " (" + oSpan.TotalHours + " hours)"

# Strings, conversions, math
oStr = new String()
? oStr.Join([ :separator = " | ", :value = ["Ring","loves",".NET"] ])
? "Base64         : " + new Convert().ToBase64String("Hello Ring")
? "Hex of 255     : " + new Convert().Format([ :value = 255, :toBase = 16 ])
? "2 ^ 20         : " + new Math().Pow(2,20)

# Uri, Guid, Version, Environment
oUri = new Uri("https://ring-lang.github.io:8443/docs/index.html?lang=en")
? "Host / Port    : " + oUri.Host + " / " + oUri.Port
? "Path / Query   : " + oUri.AbsolutePath + " / " + oUri.Query
? "Guid length    : " + len(new Guid().NewGuid().ToString())
? "Version        : " + new Version("1.28.3").Minor
? "Processors > 0 : " + (new Environment().ProcessorCount > 0)

# out parameters return a list
aParsed = new Int32().TryParse("123")
? "TryParse       : " + aParsed[1] + " -> " + aParsed[2]
aParsed = new Int32().TryParse("12x")
? "TryParse bad   : " + aParsed[1]
