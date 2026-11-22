# Jint: a JavaScript engine in the process: values go in, scripts run, functions are called, results come back
load "pkg.ring"
pkgUse("jint",[["Jint","4.18.0"]],[["Jint.dll",["Jint","Jint.Native"]]])
pkgImport("jint","Jint.dll","Jint")
pkgImport("jint","Jint.dll","Jint.Native")

oEngine = new Engine()
oResult = oEngine.Evaluate("1 + 2 * 3")
dnAssert("an expression, as text",oResult.ToString(),"7")
dnAssert("an expression, as a number",oResult.AsNumber(),7)

oEngine.SetValue("greeting","hello from Ring")
dnAssert("a value from Ring in a script",oEngine.Evaluate("greeting.toUpperCase()").ToString(),"HELLO FROM RING")
oEngine.SetValue("limit",4)
dnAssert("a number from Ring",oEngine.Evaluate("limit * 2").AsNumber(),8)

oEngine.Execute("function square(x) { return x * x; } var total = 0; for (var i = 1; i <= limit; i++) total += square(i);")
dnAssert("a global of the script",oEngine.GetValue("total").AsNumber(),30)
dnAssert("a function of the script, a params list",oEngine.callMethod("Invoke",["square",[7]]).AsNumber(),49)
dnAssert("an array of the script",oEngine.Evaluate("[1,2,3].map(function(x) { return x + 1; }).join('-')").ToString(),"2-3-4")
dnAssert("JSON in the script",oEngine.Evaluate("JSON.stringify({a: 1, b: [true, null]})").ToString(),'{"a":1,"b":[true,null]}')

try
	oEngine.Execute("throw new Error('from the script');")
	dnAssert("an error of the script is a Ring error",1,0)
catch
	dnAssert("an error of the script is a Ring error",substr(cCatchError,"from the script") > 0,1)
done

dnTestSummary()
