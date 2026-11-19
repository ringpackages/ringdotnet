# screens and pictures of windows - Screen, taking a picture of the screen, and a picture of a form (Windows Forms)
load "dotnet.ring"
using {
	"System"
	"System.IO"
	"System.Drawing"
	"System.Drawing.Imaging"
	"System.Windows.Forms"
}

func main
	# 1. Screen describes the monitors. The size of a screen depends on the computer, so the program prints only what is always true.
	oScreens = new Screen()
	oPrimary = oScreens.PrimaryScreen
	nWidth = oPrimary.Bounds.Width
	nHeight = oPrimary.Bounds.Height
	? "1. the primary screen has a size: " + yesNo(nWidth > 0 and nHeight > 0)
	? "   the working area (without the taskbar) fits in the screen: " + yesNo(oPrimary.WorkingArea.Width <= nWidth and oPrimary.WorkingArea.Height <= nHeight)
	? "   at least one screen: " + yesNo(len(oScreens.AllScreens.toList()) >= 1)

	# 2. A picture of a part of the screen: a bitmap, a Graphics object that draws on it, and CopyFromScreen that copies the pixels. The first
	#    two numbers are the place on the screen, the next two the place in the bitmap, and the last the size of the part.
	oShot = new Bitmap(120,80)
	oGraphics = new Graphics().FromImage(oShot)
	oGraphics.CopyFromScreen([ :sourceX = 0, :sourceY = 0, :destinationX = 0, :destinationY = 0, :blockRegionSize = dnNew("Size",[ 120, 80 ]) ])
	oGraphics.Dispose()
	cFile = new Path().Combine([ new Path().GetTempPath(), "ringdotnet-shot.png" ])
	oShot.Save([ :filename = cFile, :format = new ImageFormat().Png ])
	? nl + "2. a picture of the top left corner of the screen: " + oShot.Width + " x " + oShot.Height + " pixels, saved: " + yesNo(new FileInfo(cFile).Length > 0)
	new File().Delete(cFile)
	oShot.Dispose()

	# 3. A picture of a CONTROL does not need the screen: DrawToBitmap asks the control to draw itself. The picture is always the same, even
	#    when another window is in front of the form. The panel here has a red background and a label with a white background. (A picture of
	#    the form itself also has its title bar and its border.)
	oForm = uiForm("Picture me",300,200)
	oPanel = uiPanel(oForm,10,10,240,120)
	oPanel.BackColor = dnStatic("System.Drawing.Color","FromArgb",[ 255, 220, 40, 40 ])
	oLabel = uiLabel(oPanel,"Hello",20,20,100,24)
	oLabel.BackColor = dnStatic("System.Drawing.Color","FromArgb",[ 255, 255, 255, 255 ])
	oForm.Show(NULL)
	nPanelWidth = oPanel.Width
	nPanelHeight = oPanel.Height
	oPicture = new Bitmap(nPanelWidth,nPanelHeight)
	oPanel.DrawToBitmap(oPicture,dnNew("Rectangle",[ :x = 0, :y = 0, :width = nPanelWidth, :height = nPanelHeight ]))
	? nl + "3. a picture of the panel: " + oPicture.Width + " x " + oPicture.Height + " pixels"

	# 4. What is in the picture? GetPixel reads one pixel, so the program can check what the panel looks like. A pixel far from the label is
	#    the red of the panel, a pixel inside the label (but not on its text) is the white of the label.
	? nl + "4. a pixel on the background: " + oPicture.GetPixel(200,100).Name
	? "   a pixel inside the label:  " + oPicture.GetPixel(110,30).Name
	? "   (the color is shown as alpha, red, green and blue in hexadecimal)"

	# 5. Count the pixels of each color: how much of the panel is background? (Every fourth pixel is enough for an estimate.)
	nRed = 0
	nTotal = 0
	for x = 0 to nPanelWidth - 1 step 4
		for y = 0 to nPanelHeight - 1 step 4
			nTotal++
			if oPicture.GetPixel(x,y).Name = "ffdc2828"
				nRed++
			ok
		next
	next
	? nl + "5. most of the panel is the red background: " + yesNo(nRed / nTotal > 0.8)

	oPicture.Dispose()
	oForm.Close()

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"
