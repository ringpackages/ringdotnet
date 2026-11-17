# File explorer - a folder tree on the left, the files of the selected folder on the right

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System")
dnImport("System.IO")
dnImport("System.Drawing")
dnImport("System.Windows.Forms")

cRoot = ""
oForm = uiForm("File explorer",760,460)
oSplit = new SplitContainer()
oSplit.Dock = "Fill"
oForm.Controls.Add(oSplit)
oSplit.SplitterDistance = 240
oTree = new TreeView()
oTree.Dock = "Fill"
oSplit.Panel1.Controls.Add(oTree)
oList = new ListView()
oList.Dock = "Fill"
oList.View = "Details"
oList.FullRowSelect = 1
oList.GridLines = 1
oList.Columns.Add_2("Name",260)
oList.Columns.Add_2("Size",90)
oList.Columns.Add_2("Modified",140)
oSplit.Panel2.Controls.Add(oList)
oStatus = new StatusStrip()
oStatusText = new ToolStripStatusLabel()
oStatus.Items.Add(oStatusText)
oForm.Controls.Add(oStatus)
oTree.setAfterSelectEvent("showFolder()")
oTree.setBeforeExpandEvent("expandNode(aDotNetArgs[2].Node)")

if not uiSelfTest()
	setRoot(new Environment().GetFolderPath("UserProfile"))
ok

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

# the tree starts at a folder; its sub folders are loaded when a node is expanded
func setRoot cFolder
	cRoot = cFolder
	oTree.Nodes.Clear()
	oNode = oTree.Nodes.Add(cFolder)
	oNode.Tag = cFolder
	addChildren(oNode)
	oNode.Expand()

func addChildren oNode
	oNode.Nodes.Clear()
	try
		for cFolder in new Directory().GetDirectories(oNode.Tag).toList()
			oChild = oNode.Nodes.Add(new Path().GetFileName(cFolder))
			oChild.Tag = cFolder
			# a placeholder child makes the "+" visible
			oChild.Nodes.Add("...")
		next
	catch
		# folders without access are shown empty
	done

func expandNode oNode
	if oNode.Nodes.Count = 1 and oNode.Nodes.Item(0).Text = "..."
		addChildren(oNode)
	ok

func sizeText nBytes
	if nBytes < 1024
		return "" + nBytes + " B"
	but nBytes < 1024 * 1024
		return "" + floor(nBytes / 1024) + " KB"
	ok
	return "" + floor(nBytes / 1048576) + " MB"

func showFolder
	oList.Items.Clear()
	if not isobject(oTree.SelectedNode)
		return
	ok
	cFolder = oTree.SelectedNode.Tag
	nFiles = 0
	try
		for cFile in new Directory().GetFiles(cFolder).toList()
			oInfo = new FileInfo(cFile)
			oItem = new ListViewItem().New_1(oInfo.Name)
			oItem.SubItems.Add(sizeText(oInfo.Length))
			oItem.SubItems.Add(oInfo.LastWriteTime.ToString_1("yyyy-MM-dd HH:mm"))
			oList.Items.Add(oItem)
			nFiles++
		next
	catch
		oStatusText.Text = "Can't read " + cFolder
		return
	done
	oStatusText.Text = cFolder + "   (" + nFiles + " files)"

func selfTest
	# a small folder tree in the temp folder
	oPath = new Path()
	cBase = oPath.Combine(oPath.GetTempPath(),"explorer_selftest")
	if new Directory().Exists(cBase)
		new Directory().Delete_2(cBase,1)
	ok
	new Directory().CreateDirectory(oPath.Combine(cBase,"docs"))
	new Directory().CreateDirectory(oPath.Combine(cBase,"images/icons"))
	new File().WriteAllText(oPath.Combine(cBase,"readme.txt"),"hello")
	new File().WriteAllText(oPath.Combine(cBase,"docs/manual.txt"),copy("x",2048))
	setRoot(cBase)
	dnAssert("root node",oTree.Nodes.Count,1)
	dnAssert("two sub folders",oTree.Nodes.Item(0).Nodes.Count,2)
	oTree.SelectedNode = oTree.Nodes.Item(0)
	dnAssert("files of the root",oList.Items.Count,1)
	dnAssert("file name",oList.Items.Item(0).Text,"readme.txt")
	dnAssert("size text",oList.Items.Item(0).SubItems.Item(1).Text,"5 B")
	oDocs = oTree.Nodes.Item(0).Nodes.Item(0)
	oTree.SelectedNode = oDocs
	dnAssert("the docs folder",oList.Items.Item(0).Text,"manual.txt")
	dnAssert("2 KB file",oList.Items.Item(0).SubItems.Item(1).Text,"2 KB")
	oImages = oTree.Nodes.Item(0).Nodes.Item(1)
	dnAssert("placeholder child",oImages.Nodes.Item(0).Text,"...")
	expandNode(oImages)
	dnAssert("sub folder loaded on expand",oImages.Nodes.Item(0).Text,"icons")
	dnAssert("status text",right(oStatusText.Text,9),"(1 files)")
	dnAssert("sizes",sizeText(3 * 1048576),"3 MB")
	new Directory().Delete_2(cBase,1)
