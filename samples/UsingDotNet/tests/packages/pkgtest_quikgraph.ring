# QuikGraph: graphs and graph algorithms; the graph is a generic type made with its type arguments (vertices are numbers, edges are Edge<int>), the
# search and the shortest path algorithms take callbacks for the cost of an edge
load "pkg.ring"
pkgUse("quikgraph",[["QuikGraph","2.5.0"]],[["QuikGraph.dll",["QuikGraph","QuikGraph.Algorithms","QuikGraph.Algorithms.Search","QuikGraph.Algorithms.ShortestPath"]]])
pkgImport("quikgraph","QuikGraph.dll","QuikGraph")

cEdge = "QuikGraph.Edge`1[[System.Int32]]"
oGraph = dnNew("QuikGraph.AdjacencyGraph`2[[System.Int32],[" + cEdge + "]]",[])
for nVertex = 1 to 5
	oGraph.AddVertex(nVertex)
next
dnAssert("five vertices",oGraph.VertexCount,5)
aEdges = [[1,2],[2,3],[3,4],[1,3],[4,5]]
for aEdge in aEdges
	oGraph.AddEdge(dnNew(cEdge,[aEdge[1],aEdge[2]]))
next
dnAssert("five edges",oGraph.EdgeCount,5)
dnAssert("a vertex is in the graph",oGraph.ContainsVertex(3),1)
dnAssert("a vertex that is not",oGraph.ContainsVertex(9),0)
dnAssert("the out degree of a vertex",oGraph.OutDegree(1),2)
dnAssert("a graph with edges is not empty",oGraph.IsEdgesEmpty,0)
dnAssert("it is directed",oGraph.IsDirected,1)

# algorithms (extension methods of QuikGraph.Algorithms.AlgorithmExtensions)
cAlg = "QuikGraph.Algorithms.AlgorithmExtensions"
dnAssert("a graph without cycles",dnStatic(cAlg,"IsDirectedAcyclicGraph",[oGraph]),1)
aOrder = dnStatic(cAlg,"TopologicalSort",[oGraph]).toList()
dnAssert("the topological order has every vertex",len(aOrder),5)
dnAssert("the first vertex of the order",aOrder[1],1)
dnAssert("the last vertex of the order",aOrder[5],5)
oCycle = dnNew("QuikGraph.AdjacencyGraph`2[[System.Int32],[" + cEdge + "]]",[])
oCycle.AddVerticesAndEdge(dnNew(cEdge,[1,2]))
oCycle.AddVerticesAndEdge(dnNew(cEdge,[2,1]))
dnAssert("a graph with a cycle",dnStatic(cAlg,"IsDirectedAcyclicGraph",[oCycle]),0)
dnAssert("AddVerticesAndEdge adds the vertices",oCycle.VertexCount,2)

# the shortest path: the cost of an edge is a callback, and the answer is a delegate that takes the target vertex (answer: [found, edges])
oTry = dnStatic(cAlg,"ShortestPathsDijkstra",[oGraph,dnCallback("edgeCost"),1])
aFound = oTry.callMethod("Invoke",[5])
dnAssert("a path to a vertex that can be reached",aFound[1],1)
aPath = aFound[2].toList()
dnAssert("the cheapest path has four edges (the edge 1-3 costs 10)",len(aPath),4)
dnAssert("it starts at the source",aPath[1].Source,1)
dnAssert("it ends at the target",aPath[4].Target,5)
oOne = dnNew("QuikGraph.AdjacencyGraph`2[[System.Int32],[" + cEdge + "]]",[])
oOne.AddVertex(1)
oOne.AddVertex(2)
aNone = dnStatic(cAlg,"ShortestPathsDijkstra",[oOne,dnCallback("edgeCost"),1]).callMethod("Invoke",[2])
dnAssert("a vertex that can not be reached",aNone[1],0)

# the edges of a vertex, and removing
nOut = 0
for oEdge in oGraph.OutEdges(1).toList()
	nOut++
next
dnAssert("the edges that leave a vertex",nOut,2)
oGraph.RemoveVertex(5)
dnAssert("a vertex is removed with its edges",oGraph.EdgeCount,4)

# an undirected graph and its connected components
cUndirected = "QuikGraph.UndirectedGraph`2[[System.Int32],[" + cEdge + "]]"
oUndirected = dnNew(cUndirected,[])
oUndirected.AddVerticesAndEdge(dnNew(cEdge,[1,2]))
oUndirected.AddVerticesAndEdge(dnNew(cEdge,[3,4]))
oUndirected.AddVertex(5)
dnAssert("an undirected graph is not directed",oUndirected.IsDirected,0)
dnAssert("the number of vertices",oUndirected.VertexCount,5)
dnAssert("the edge is found from either end",oUndirected.callMethod("ContainsEdge",[2,1]),1)

dnTestSummary()

func edgeCost aArgs

	if aArgs[1].Source = 1 and aArgs[1].Target = 3
		return 10
	ok
	return 1

