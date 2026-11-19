# the checks of ch10_browser.ring: run with  ring ch10_browser.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	dnAssert("the root node",oTree.Nodes.Count,1)
	dnAssert("the root has three subfolders",oTree.Nodes.Item(0).Nodes.Count,3)
	dnAssert("the root folder has one file",oList.Items.Count,1)
	# pick the folder Projects > Ring
	oProjects = oTree.Nodes.Item(0).Nodes.Item(2)          # sorted: Documents, Pictures, Projects
	dnAssert("the node is Projects",oProjects.Text,"Projects")
	oTree.SelectedNode = oProjects.Nodes.Item(0)
	dnAssert("two files in Ring",oList.Items.Count,2)
	dnAssert("the first file",oList.Items.Item(0).Text,"main.ring")
	dnAssert("the status shows the folder and the totals",substr(oStatus.Text,"2 files") > 0,True)
	dnAssert("a size text",sizeText(1536),"1.5 KB")
	dnAssert("a small size",sizeText(300),"300 B")
	new Directory().Delete([ :path = cRoot, :recursive = True ])
