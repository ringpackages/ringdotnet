# RulesEngine (Microsoft): business rules as JSON workflows (a name and an expression for each rule), run against named inputs, with the result of each rule
load "pkg.ring"
pkgUse("rulesengine",[["RulesEngine","6.0.1"]],[["RulesEngine.dll",["RulesEngine","RulesEngine.Models","RulesEngine.Interfaces"]]])
pkgImport("rulesengine","RulesEngine.dll","RulesEngine")
pkgImport("rulesengine","RulesEngine.dll","RulesEngine.Models")
pkgImport("rulesengine","RulesEngine.dll","RulesEngine.Interfaces")

cWorkflow = '{"WorkflowName":"Discount","Rules":[' +
	'{"RuleName":"Adult","ErrorMessage":"must be an adult","Expression":"age >= 18"},' +
	'{"RuleName":"Big spender","ErrorMessage":"spend more","Expression":"spend > 1000"},' +
	'{"RuleName":"Both","Expression":"age >= 18 AND spend > 1000"}]}'

oEngine = (new RulesEngine).@New([ :jsonConfig = [ cWorkflow ] ])
dnAssert("the workflow is registered",oEngine.ContainsWorkflow("Discount"),1)
dnAssert("another workflow is not",oEngine.ContainsWorkflow("Other"),0)
dnAssert("the names of the workflows",oEngine.GetAllRegisteredWorkflowNames().toList()[1],"Discount")

# an adult who spent a lot: every rule holds
aResults = run(oEngine,25,2500)
dnAssert("three rules ran",len(aResults),3)
dnAssert("the adult rule holds",aResults[1][2],1)
dnAssert("the big spender rule holds",aResults[2][2],1)
dnAssert("both rules together hold",aResults[3][2],1)

# an adult who spent little
aResults = run(oEngine,40,100)
dnAssert("the adult rule still holds",aResults[1][2],1)
dnAssert("the big spender rule does not",aResults[2][2],0)
dnAssert("both together do not",aResults[3][2],0)
dnAssert("the rule says its name",aResults[2][1],"Big spender")

# a young customer
aResults = run(oEngine,16,5000)
dnAssert("a young customer fails the adult rule",aResults[1][2],0)
dnAssert("but passes the spending rule",aResults[2][2],1)

dnTestSummary()

# runs the workflow with two inputs: a list of [rule name, did it hold]
func run oEngine,nAge,nSpend

	oAge = new RuleParameter("age",nAge)
	oSpend = new RuleParameter("spend",nSpend)
	oTask = oEngine.ExecuteAllRulesAsync([ :workflowName = "Discount", :ruleParams = [oAge,oSpend] ])
	oList = oTask.Result
	aOut = []
	for oItem in oList.toList()
		oRule = oItem.Rule
		aOut + [oRule.RuleName,oItem.IsSuccess]
	next
	return aOut
