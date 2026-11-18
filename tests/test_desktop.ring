# Batch: System.Drawing*, System.Windows.Forms (the whole namespace)
load "dotnet.ring"
dnUseDesktop()
dnImport("System")
dnImport("System.Drawing")
dnImport("System.Drawing.Imaging")
dnImport("System.Windows.Forms")
dnImport("System.IO")

# System.Drawing: structs and colors
oPoint = new Point(3,4)
dnAssert("Point.X",oPoint.X,3)
dnAssert("Point.Add",new Point(1,1).Add(oPoint,new Size(10,20)).Y,24)
oRect = new Rectangle(10,20,100,50)
dnAssert("Rectangle.Right",oRect.Right,110)
dnAssert("Rectangle.Contains",oRect.Contains_2(50,40),1)
oColor = new Color().FromArgb_3(10,20,30)
dnAssert("Color.R",oColor.R,10)
dnAssert("Color.B",oColor.B,30)
dnAssert("Color.Red name",new Color().Red.Name,"Red")
dnAssert("Color.ToArgb",new Color().White.ToArgb(),-1)

# Bitmap drawing and reading pixels back
oBitmap = new Bitmap(20,20)
oGraphics = new Graphics().FromImage(oBitmap)
oGraphics.Clear(new Color().Blue)
oGraphics.FillRectangle(new SolidBrush(new Color().Red),new Rectangle(0,0,10,10))
dnAssert("Bitmap pixel red",oBitmap.GetPixel(2,2).Name,"ffff0000")
dnAssert("Bitmap pixel blue",oBitmap.GetPixel(15,15).Name,"ff0000ff")
dnAssert("Bitmap.Width",oBitmap.Width,20)
oGraphics.Dispose()
oFont = new Font("Arial",12)
dnAssert("Font.Name",oFont.Name,"Arial")

# Windows Forms controls (a form is built without being shown)
oForm = new Form()
oForm.Text = "Test form"
oForm.Width = 400
oForm.Height = 300
oButton = new Button()
oButton.Text = "OK"
oButton.Location = new Point(10,10)
oLabel = new Label()
oLabel.Text = "label"
oTextBox = new TextBox()
oTextBox.Text = "typed"
oCheck = new CheckBox()
oCheck.Checked = 1
oForm.Controls.Add(oButton)
oForm.Controls.Add(oLabel)
oForm.Controls.Add(oTextBox)
oForm.Controls.Add(oCheck)
dnAssert("Controls.Count",oForm.Controls.Count,4)
dnAssert("Form.Text",oForm.Text,"Test form")
dnAssert("Button.Location",oButton.Location.X,10)
dnAssert("TextBox.Text",oTextBox.Text,"typed")
dnAssert("CheckBox.Checked",oCheck.Checked,1)
dnAssert("Control.Name inherited",classname(oButton),"button")

# ListBox and ComboBox items
oList = new ListBox()
oList.Items.Add("one")
oList.Items.Add("two")
dnAssert("ListBox.Items.Count",oList.Items.Count,2)
oCombo = new ComboBox()
oCombo.Items.Add("x")
oCombo.SelectedIndex = 0
dnAssert("ComboBox.SelectedItem",oCombo.SelectedItem,"x")

# Events with the message loop: a Timer ticks, then closes the form (the Ring thread runs the loop)
nTicks = 0
oTimer = new FormsTimer()
oTimer.Interval = 20
oTimer.setTickEvent("nTicks++ if nTicks = 3 oForm.Close() ok")
oTimer.Start()
new Application().Run(oForm)
oTimer.Stop()
dnAssert("Timer ticks until closed",nTicks,3)

# Click events
nClicks = 0
oButton.setClickEvent("nClicks++")
oButton.PerformClick()
oButton.PerformClick()
dnAssert("Button.PerformClick events",nClicks,2)

nFail = dnTestSummary()
