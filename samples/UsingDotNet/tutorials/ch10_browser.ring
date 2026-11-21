# a folder browser - a TreeView of folders, a ListView of files, and the details of a file
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = ""
oTree = ""
oList = ""
oStatus = ""
cRoot = ""

func main
	# The folder to browse: this program makes a small demo folder (give another folder as the first argument to browse it)
	cRoot = makeDemoFolder()
	if len(sysargv) >= 3 and sysargv[3] != "--selftest"
		cRoot = sysargv[3]
	ok

	oForm = uiForm("Folder browser",640,360)

	# The pieces: a SplitContainer with the folders on the left and the files on the right, a status line at the bottom
	oSplit = new SplitContainer() {
		Dock = "Fill"
	}
	oForm.Controls.Add(oSplit)
	oSplit.SplitterDistance = 200

	oTree = new TreeView() {
		Dock = "Fill"
	}
	oSplit.Panel1.Controls.Add(oTree)

	oList = new ListView() {
		Dock = "Fill"
		View = "Details"                    # columns, like Explorer
		FullRowSelect = True
		GridLines = True
	}
	oList.Columns.Add([ :text = "Name", :width = 180 ])
	oList.Columns.Add([ :text = "Size", :width = 80 ])
	oList.Columns.Add([ :text = "Modified", :width = 130 ])
	oSplit.Panel2.Controls.Add(oList)

	oStatus = uiLabel(oForm,"",0,0,640,22)
	oStatus.Dock = "Bottom"

	# fill the tree from the folder, and react when the user picks a node
	oRootNode = addFolderNode(oTree.Nodes,cRoot)
	oRootNode.Expand()
	oTree.setAfterSelectEvent("folderChosen()")
	oTree.SelectedNode = oRootNode

	uiRun(oForm)

# A node for a folder, with a node for each subfolder below it. The Tag of a node remembers the full path.
func addFolderNode oNodes, cFolder
	oNode = oNodes.Add(new Path().GetFileName(cFolder))
	oNode.Tag = cFolder
	for cSub in sort(new Directory().GetDirectories(cFolder).toList())
		addFolderNode(oNode.Nodes,cSub)
	next
	return oNode

# The user picked a folder: list its files
func folderChosen
	cFolder = oTree.SelectedNode.Tag
	oList.Items.Clear()
	nFiles = 0
	nBytes = 0
	for cFile in sort(new Directory().GetFiles(cFolder).toList())
		oInfo = new FileInfo(cFile)
		oItem = new ListViewItem().@New([ :text = oInfo.Name ])
		oItem.SubItems.Add(sizeText(oInfo.Length))
		oItem.SubItems.Add(oInfo.LastWriteTime.Format("yyyy-MM-dd HH:mm"))
		oList.Items.Add(oItem)
		nFiles++
		nBytes += oInfo.Length
	next
	oStatus.Text = "  " + cFolder + "   -   " + nFiles + " files, " + sizeText(nBytes)

# a size in bytes as text: 1536 -> 1.5 KB
func sizeText nBytes
	if nBytes < 1024
		return "" + nBytes + " B"
	ok
	if nBytes < 1024 * 1024
		return uiNumber(floor(nBytes / 102.4) / 10) + " KB"      # uiNumber: 1.5, not Ring's fixed 1.50
	ok
	return uiNumber(floor(nBytes / 104857.6) / 10) + " MB"

# a demo folder with folders and files
func makeDemoFolder
	cBase = new Path().Combine([new Path().GetTempPath(),"ringdotnet_browser"])
	if new Directory().Exists(cBase)
		new Directory().Delete([ :path = cBase, :recursive = True ])
	ok
	for cName in ["Projects/Ring","Projects/Web","Pictures","Documents/2024"]
		new Directory().CreateDirectory(new Path().Combine([cBase,cName]))
	next
	new File().WriteAllText([ :path = new Path().Combine([cBase,"readme.txt"]), :contents = "A demo folder" ])
	new File().WriteAllText([ :path = new Path().Combine([cBase,"Projects/Ring/main.ring"]), :contents = copies("? 'hello'" + nl,40) ])
	new File().WriteAllText([ :path = new Path().Combine([cBase,"Projects/Ring/notes.txt"]), :contents = copies("some notes ",100) ])
	new File().WriteAllText([ :path = new Path().Combine([cBase,"Projects/Web/index.html"]), :contents = "<html></html>" ])
	new File().WriteAllText([ :path = new Path().Combine([cBase,"Documents/2024/report.txt"]), :contents = copies("report line" + nl,500) ])
	return cBase

func copies cText, nTimes
	cResult = ""
	for nIndex = 1 to nTimes
		cResult += cText
	next
	return cResult
