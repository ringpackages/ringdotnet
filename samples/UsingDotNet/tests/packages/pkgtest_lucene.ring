# Lucene.Net: a full-text index in memory (analyzer, documents with fields, a writer, a searcher), queries by term and by phrase, scores and stored fields
load "pkg.ring"
pkgUse("lucene",[["Lucene.Net","4.8.0-beta00017"],["Lucene.Net.Analysis.Common","4.8.0-beta00017"]],[["Lucene.Net.dll",["Lucene.Net.Store","Lucene.Net.Index","Lucene.Net.Documents","Lucene.Net.Search","Lucene.Net.Util"]],["Lucene.Net.Analysis.Common.dll",["Lucene.Net.Analysis.Standard"]]])
for cNamespace in ["Lucene.Net.Store","Lucene.Net.Index","Lucene.Net.Documents","Lucene.Net.Search","Lucene.Net.Util"]
	pkgImport("lucene","Lucene.Net.dll",cNamespace)
next
pkgImport("lucene","Lucene.Net.Analysis.Common.dll","Lucene.Net.Analysis.Standard")

oVersion = dnStatic("Lucene.Net.Util.LuceneVersion","LUCENE_48",[])
oDirectory = new RAMDirectory()
oAnalyzer = dnNew("Lucene.Net.Analysis.Standard.StandardAnalyzer",[oVersion])
oConfig = dnNew("Lucene.Net.Index.IndexWriterConfig",[oVersion,oAnalyzer])
oWriter = dnNew("Lucene.Net.Index.IndexWriter",[oDirectory,oConfig])

# documents: a stored title and a searched body
aTexts = [ ["Ring and .NET","Ring programs call .NET classes through a bridge"],
           ["Gardening","tomatoes grow best in the sun"],
           ["Bridges","a bridge connects two sides of a river"] ]
for aText in aTexts
	oDocument = new Document()
	oDocument.Add(dnNew("Lucene.Net.Documents.StringField",["title",aText[1],dnStatic("Lucene.Net.Documents.Field+Store","YES",[])]))
	oDocument.Add(dnNew("Lucene.Net.Documents.TextField",["body",aText[2],dnStatic("Lucene.Net.Documents.Field+Store","NO",[])]))
	oWriter.AddDocument(oDocument)
next
oWriter.Commit()
dnAssert("three documents were added",oWriter.NumDocs,3)
oWriter.Dispose(NULL)

# search: a term query (the analyzer lower-cases the words of the index)
oReader = dnStatic("Lucene.Net.Index.DirectoryReader","Open",[oDirectory])
dnAssert("the reader sees the documents",oReader.NumDocs,3)
oSearcher = new IndexSearcher(oReader)
oQuery = dnNew("Lucene.Net.Search.TermQuery",[dnNew("Lucene.Net.Index.Term",["body","bridge"])])
oHits = oSearcher.Search([ :query = oQuery, :n = 10 ])
dnAssert("two documents have the word bridge",oHits.TotalHits,2)
aScores = oHits.ScoreDocs.toList()
dnAssert("a hit for each document",len(aScores),2)
dnAssert("the best hit has a score",aScores[1].Score > 0,1)
dnAssert("the hits are ordered by score",aScores[1].Score >= aScores[2].Score,1)
nBest = aScores[1].getProp("Doc")          # Doc is spelled out by getProp and callMethod
oBest = oSearcher.callMethod("Doc",[nBest])
cTitle = oBest.callMethod("Get",["title"])          # Get is a word of Ring: callMethod
dnAssert("a stored field of the best hit",cTitle != "",1)

# a query that has no hit, and a phrase
dnAssert("no hit",oSearcher.Search([ :query = dnNew("Lucene.Net.Search.TermQuery",[dnNew("Lucene.Net.Index.Term",["body","spaceship"])]), :n = 10 ]).TotalHits,0)
oPhrase = new PhraseQuery()
oPhrase.Add(dnNew("Lucene.Net.Index.Term",["body","tomatoes"]))
oPhrase.Add(dnNew("Lucene.Net.Index.Term",["body","grow"]))
oGardening = oSearcher.Search([ :query = oPhrase, :n = 10 ])
dnAssert("a phrase finds one document",oGardening.TotalHits,1)
dnAssert("its stored title",oSearcher.callMethod("Doc",[oGardening.ScoreDocs.toList()[1].getProp("Doc")]).callMethod("Get",["title"]),"Gardening")

oReader.Dispose()
oDirectory.Dispose()

dnTestSummary()
