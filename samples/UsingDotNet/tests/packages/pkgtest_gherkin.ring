# Gherkin: the parser of the feature files of Cucumber; a text becomes a document with a feature, scenarios, steps, tags and tables
load "pkg.ring"
pkgUse("gherkin",[["Gherkin","43.0.0"]],[["Gherkin.dll",["Gherkin","Gherkin.Ast"]]])
pkgImport("gherkin","Gherkin.dll","Gherkin")
pkgImport("gherkin","Gherkin.dll","Gherkin.Ast")
using { "System.IO" }

cFeature = "@billing" + nl + "Feature: Pay" + nl + "  A customer pays" + nl + nl + "  Background:" + nl + "    Given a customer" + nl + nl + "  @fast" + nl + "  Scenario: Pay by card" + nl + "    When the customer pays 10" + nl + "    Then the balance is 90" + nl + nl + "  Scenario Outline: Pay many" + nl + "    When the customer pays <amount>" + nl + "    Examples:" + nl + "      | amount |" + nl + "      | 5      |" + nl + "      | 7      |" + nl
oParser = new Parser()
oDocument = oParser.callMethod("Parse",[dnNew("System.IO.StringReader",[cFeature])])
dnAssert("a document with a feature",oDocument.Feature.Name,"Pay")
dnAssert("the description of the feature",substr(oDocument.Feature.Description,"A customer pays") > 0,1)
dnAssert("the keyword of the feature",oDocument.Feature.Keyword,"Feature")
dnAssert("the language",oDocument.Feature.Language,"en")
dnAssert("the tag of the feature",oDocument.Feature.Tags.toList()[1].Name,"@billing")

# the children of the feature: the background and the scenarios
aChildren = oDocument.Feature.Children.toList()
dnAssert("three children",len(aChildren),3)
oBackground = aChildren[1]
dnAssert("the background",oBackground.Keyword,"Background")
dnAssert("a step of the background",oBackground.Steps.toList()[1].Text,"a customer")
oScenario = aChildren[2]
dnAssert("the name of a scenario",oScenario.Name,"Pay by card")
dnAssert("the tag of a scenario",oScenario.Tags.toList()[1].Name,"@fast")
aSteps = oScenario.Steps.toList()
dnAssert("two steps",len(aSteps),2)
dnAssert("the keyword of a step",aSteps[1].Keyword,"When ")
dnAssert("the text of a step",aSteps[2].Text,"the balance is 90")
dnAssert("the line of a step",aSteps[1].Location.Line,10)

# an outline with its table of examples
oOutline = aChildren[3]
dnAssert("the outline",oOutline.Keyword,"Scenario Outline")
oExamples = oOutline.Examples.toList()[1]
dnAssert("the header of the table",oExamples.TableHeader.Cells.toList()[1].Value,"amount")
aRows = oExamples.TableBody.toList()
dnAssert("two rows of examples",len(aRows),2)
dnAssert("a cell of a row",aRows[2].Cells.toList()[1].Value,"7")

# a feature in another language
oFrench = oParser.callMethod("Parse",[dnNew("System.IO.StringReader",["# language: fr" + nl + "Fonctionnalité: Payer" + nl + "  Scénario: Un" + nl + "    Soit un client" + nl])])
dnAssert("a feature in French",oFrench.Feature.Language,"fr")
dnAssert("its name",oFrench.Feature.Name,"Payer")

# a text that is not a feature is an error
cError = ""
try
	oParser.callMethod("Parse",[dnNew("System.IO.StringReader",["this is not gherkin" + nl + "Feature: x"])])
catch
	cError = cCatchError
done
dnAssert("a text with no feature at the start is an error",substr(cError,"ParserException") + substr(cError,"CompositeParserException") > 0,1)
dnTestSummary()
