# A tree of nodes with the selection event

load "dotnet.ring"
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

uiRun(oForm)

# --------------------------------------------------------------------------
