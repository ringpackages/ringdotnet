# A tree of nodes with the selection event

load "dotnet.ring"
dnUseDesktop()
using {
	"System.Drawing"
	"System.Windows.Forms"
}


oForm = uiForm("Tree",320,260)
oTree = new TreeView()
oTree.Dock = "Fill"
oRoot = oTree.Nodes.Add("Languages")
oScripting = oRoot.Nodes.Add("Scripting")
oScripting {
	Nodes.Add("Ring")
	Nodes.Add("Lua")
}
oCompiled = oRoot.Nodes.Add("Compiled")
oCompiled {
	Nodes.Add("C")
	Nodes.Add("Go")
}
oForm.Controls.Add(oTree)
oTree.ExpandAll()
oTree.setAfterSelectEvent("oForm.Text = 'Selected: ' + oTree.SelectedNode.Text")

uiTest(oForm,"selfTest()")
uiRun(oForm)
uiEnd()

# --------------------------------------------------------------------------

func selfTest
	oNode = oCompiled.Nodes.Item(1)
	oTree.SelectedNode = oNode
	dnAssert("selected node",oForm.Text,"Selected: Go")
	dnAssert("root has two children",oRoot.Nodes.Count,2)
	dnAssert("path",oTree.SelectedNode.FullPath,"Languages\Compiled\Go")
