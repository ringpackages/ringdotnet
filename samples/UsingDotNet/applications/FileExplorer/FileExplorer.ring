# File explorer - a folder tree on the left, the files of the selected folder on the right

load "dotnet.ring"

using {
	"System"
	"System.IO"
	"System.Drawing"
	"System.Windows.Forms"
}

cRoot = ""
oForm = uiForm("File explorer",760,460)
oSplit = new SplitContainer()
oSplit.Dock = "Fill"
oForm.Controls.Add(oSplit)
oSplit.SplitterDistance = 240
oTree = new TreeView()
oTree.Dock = "Fill"
oSplit.Panel1.Controls.Add(oTree)
oList = new ListView() {
	Dock = "Fill"
	View = "Details"
	FullRowSelect = True
	GridLines = True
}
oList.Columns.Add([ :text = "Name", :width = 260 ])
oList.Columns.Add([ :text = "Size", :width = 90 ])
oList.Columns.Add([ :text = "Modified", :width = 140 ])
oSplit.Panel2.Controls.Add(oList)
oStatus = new StatusStrip()
oStatusText = new ToolStripStatusLabel()
oStatus.Items.Add(oStatusText)
oForm.Controls.Add(oStatus)
oTree {
	setAfterSelectEvent("showFolder()")
	setBeforeExpandEvent("expandNode(aDotNetArgs[2].Node)")
}

if not uiSelfTest()
	setRoot(new Environment().GetFolderPath("UserProfile"))
ok

uiRun(oForm)

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
		aFolders = new Directory().GetDirectories(oNode.Tag).toList()
		for cFolder in aFolders
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
		aFiles = new Directory().GetFiles(cFolder).toList()
		for cFile in aFiles
			oInfo = new FileInfo(cFile)
			oItem = new ListViewItem().@New([ :text = oInfo.Name ])
			oItem.SubItems.Add(sizeText(oInfo.Length))
			oItem.SubItems.Add(oInfo.LastWriteTime.Format("yyyy-MM-dd HH:mm"))
			oList.Items.Add(oItem)
			nFiles++
		next
	catch
		oStatusText.Text = "Can't read " + cFolder
		return
	done
	oStatusText.Text = cFolder + "   (" + nFiles + " files)"
