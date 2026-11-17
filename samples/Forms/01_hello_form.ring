# The smallest window: a form with a label

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System.Drawing")
dnImport("System.Windows.Forms")


oForm = uiForm("Hello",300,120)
oLabel = uiLabel(oForm,"Hello from Ring and .NET!",20,40,260,30)
oLabel.Font = uiFont("Segoe UI",14,true)

uiTest(oForm,"dnAssert('label text',oLabel.Text,'Hello from Ring and .NET!') dnAssert('form title',oForm.Text,'Hello')")
uiRun(oForm)
uiEnd()
