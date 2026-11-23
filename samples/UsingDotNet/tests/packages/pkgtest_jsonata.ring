# Jsonata.Net.Native: JSONata queries over JSON text (text in, text out); sums, filters, paths, functions, errors
load "pkg.ring"
pkgUse("jsonata",[["Jsonata.Net.Native","3.0.0"]],[["Jsonata.Net.Native.dll",["Jsonata.Net.Native"]]])
pkgImport("jsonata","Jsonata.Net.Native.dll","Jsonata.Net.Native")

cJson = '{"items":[{"name":"pen","price":2.5,"qty":4},{"name":"book","price":12,"qty":1},{"name":"bag","price":30,"qty":2}],"owner":"Ann"}'

dnAssert("a path",jq("owner",cJson),'"Ann"')
dnAssert("a sum",jq("$sum(items.price)",cJson),"44.5")
dnAssert("a computed value",jq("$sum(items.(price * qty))",cJson),"82")
dnAssert("a filter",compact(jq("items[price > 10].name",cJson)),'["book","bag"]')
dnAssert("a count",jq("$count(items)",cJson),"3")
dnAssert("a string function",jq("$uppercase(owner)",cJson),'"ANN"')
dnAssert("an object made",compact(jq('{"total": $sum(items.qty)}',cJson)),'{"total":7}')
dnAssert("a join",jq('$join(items.name, "/")',cJson),'"pen/book/bag"')
dnAssert("text that is not English",jq("$uppercase(a)",'{"a":"é"}'),'"É"')

cError = ""
try
	jq("items[",cJson)
catch
	cError = cCatchError
done
dnAssert("a broken query raises an error",len(cError) > 0,1)

dnTestSummary()

func jq cQuery, cData

	oQuery = new JsonataQuery(cQuery)
	return oQuery.callMethod("Eval",[cData])

func compact cText

	return substr(substr(substr(cText,char(13),""),char(10),"")," ","")
