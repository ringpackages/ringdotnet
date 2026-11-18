load "dotnetlib.ring"
using { "System.Linq" }

# LINQ over Ring lists: the conditions are Ring code (aDotNetArgs[1] is the item)
aSales = [120, 45.5, 300, 80, 15, 210, 99.9]

aBig = dnQuery(aSales).Where("xDotNetResult = aDotNetArgs[1] >= 100").OrderByDescending("xDotNetResult = aDotNetArgs[1]").ToList()
? "Sales >= 100 (high to low) : " + list2str(aBig)
oAll = dnQuery(aSales)
? "Count / Sum / Average     : " + oAll.Count() + " / " + oAll.Sum("") + " / " + oAll.Average("")
? "Min / Max                 : " + oAll.Min("") + " / " + oAll.Max("")
? "Any over 250 ?            : " + oAll.Any("xDotNetResult = aDotNetArgs[1] > 250")
? "All positive ?            : " + oAll.All("xDotNetResult = aDotNetArgs[1] > 0")

# Strings: select, distinct, order, skip/take
aNames = ["Ring","dotnet","Ring","linq","Lua","dotnet","Python"]
? "Distinct upper-cased      : " + list2str(dnQuery(aNames).Distinct().Select("xDotNetResult = upper(aDotNetArgs[1])").ToList())
? "Second to fourth by length: " + list2str(dnQuery(aNames).Distinct().OrderBy("xDotNetResult = len(aDotNetArgs[1])").Skip(1).Take(3).ToList())

# The raw Enumerable class: type arguments are inferred
oLinq = new Enumerable()
? "Enumerable.Last           : " + oLinq.Last(aNames)
