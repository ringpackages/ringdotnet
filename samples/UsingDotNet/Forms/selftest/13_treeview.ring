# the checks of 13_treeview.ring: run with  ring 13_treeview.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oNode = oCompiled.Nodes.Item(1)
	oTree.SelectedNode = oNode
	dnAssert("selected node",oForm.Text,"Selected: Go")
	dnAssert("root has two children",oRoot.Nodes.Count,2)
	dnAssert("path",oTree.SelectedNode.FullPath,"Languages\Compiled\Go")
