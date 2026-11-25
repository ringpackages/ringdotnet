# GraphQL-Parser: the syntax tree of a GraphQL document; operations, fields with arguments and selections are nodes that Ring reads by their properties
load "pkg.ring"
pkgUse("graphqlparser",[["GraphQL-Parser","9.5.1"]],[["GraphQLParser.dll",["GraphQLParser","GraphQLParser.AST"]]])
pkgImport("graphqlparser","GraphQLParser.dll","GraphQLParser")
pkgImport("graphqlparser","GraphQLParser.dll","GraphQLParser.AST")

cQuery = 'query Hero($id: ID!) { hero(id: $id) { name friends { name } } }'
oDocument = dnStatic("GraphQLParser.Parser","Parse",[cQuery])
dnAssert("a document was parsed",oDocument.Definitions.Count,1)
oOperation = oDocument.Definitions.Item(0)
dnAssert("the kind of the definition",oOperation.Kind,"OperationDefinition")
dnAssert("the operation is a query",oOperation.Operation,"Query")
dnAssert("its name",oOperation.Name.StringValue,"Hero")

# the variables of the operation
dnAssert("one variable",oOperation.Variables.Count,1)
oVariable = oOperation.Variables.Item(0)
dnAssert("the name of the variable",oVariable.Variable.Name.StringValue,"id")
dnAssert("its type is not null",oVariable.Type.Kind,"NonNullType")

# the selection: the field hero with an argument, and the fields inside it
oSelections = oOperation.SelectionSet.Selections
dnAssert("one field at the top",oSelections.Count,1)
oHero = oSelections.Item(0)
dnAssert("the field",oHero.Name.StringValue,"hero")
dnAssert("it has an argument",oHero.Arguments.Count,1)
dnAssert("the name of the argument",oHero.Arguments.Item(0).Name.StringValue,"id")
dnAssert("the value of the argument is a variable",oHero.Arguments.Item(0).Value.Kind,"Variable")
oInner = oHero.SelectionSet.Selections
dnAssert("two fields inside",oInner.Count,2)
dnAssert("the second is friends",oInner.Item(1).Name.StringValue,"friends")
dnAssert("friends has fields of its own",oInner.Item(1).SelectionSet.Selections.Item(0).Name.StringValue,"name")

# a document with a mutation, a fragment and a list of values
oDocument2 = dnStatic("GraphQLParser.Parser","Parse",['mutation { addTag(names: ["a","b"], count: 3) { id } } fragment F on User { id }'])
dnAssert("two definitions",oDocument2.Definitions.Count,2)
dnAssert("a mutation",oDocument2.Definitions.Item(0).Operation,"Mutation")
dnAssert("a fragment",oDocument2.Definitions.Item(1).Kind,"FragmentDefinition")
oAdd = oDocument2.Definitions.Item(0).SelectionSet.Selections.Item(0)
dnAssert("a list argument",oAdd.Arguments.Item(0).Value.Kind,"ListValue")
dnAssert("a number argument",oAdd.Arguments.Item(1).Value.Kind,"IntValue")

# a query that is not valid is an error with the place
cError = ""
try
	dnStatic("GraphQLParser.Parser","Parse",["query { hero( }"])
catch
	cError = cCatchError
done
dnAssert("a syntax error is raised",substr(cError,"GraphQLSyntaxErrorException") > 0,1)
dnTestSummary()
