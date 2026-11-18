load "dotnetlib.ring"
using { "System" }

# Dates and times
oNow = new DateTime(2024,12,25).AddHours(18.5)
? "Christmas 2024 : " + oNow.ToString_1("dddd, dd MMMM yyyy HH:mm")
? "Plus 10 days   : " + oNow.AddDays(10).ToString_1("yyyy-MM-dd")
? "Day of week    : " + oNow.DayOfWeek
oSpan = new TimeSpan().FromMinutes(135)
? "135 minutes    : " + oSpan.ToString() + " (" + oSpan.TotalHours + " hours)"

# Strings, conversions, math
oStr = new String()
? oStr.Join(" | ",["Ring","loves",".NET"])
? "Base64         : " + new Convert().ToBase64String("Hello Ring")
? "Hex of 255     : " + new Convert().ToString_2(255,16)
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
