# A drop-down list

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System.Drawing")
dnImport("System.Windows.Forms")


oForm = uiForm("Combo box",300,130)
oCombo = uiComboBox(oForm,20,20,160,["Ring","Python","Lua","C"])
oChoice = uiLabel(oForm,"",20,65,260,24)
oCombo.setSelectedIndexChangedEvent("oChoice.Text = 'Language: ' + oCombo.Text")

uiTest(oForm,"oCombo.SelectedIndex = 2 dnAssert('item',oChoice.Text,'Language: Lua') dnAssert('count',oCombo.Items.Count,4)")
uiRun(oForm)
uiEnd()
