# Shapes on a canvas, rendered to a bitmap to check the colors

load "dotnet.ring"
dnUseDesktop()
using {
	"System.Windows"
	"System.Windows.Controls"
	"System.Windows.Controls.Primitives"
	"System.Windows.Media"
	"System.Windows.Shapes"
	"System.Windows.Data"
	"System.Windows.Threading"
	"System"
	"System.IO"
	"System.Drawing"
	"System.Windows.Media.Imaging"
}


oCanvas = new Canvas() {
	Width = 200
	Height = 120
	Background = wpfBrush("White")
}
oRect = new WpfRectangle() {
	Width = 80
	Height = 50
	Fill = wpfBrush("SteelBlue")
}
oCanvas.Children.Add(oRect)
oCanvas.SetLeft(oRect,10)
oCanvas.SetTop(oRect,10)
oCircle = new Ellipse() {
	Width = 60
	Height = 60
	Fill = wpfBrush("Orange")
}
oCanvas.Children.Add(oCircle)
oCanvas.SetLeft(oCircle,120)
oCanvas.SetTop(oCircle,30)
oWindow = wpfWindow("Shapes",260,200)
oWindow.Content = oCanvas

wpfTest(oWindow,"selfTest()")
wpfRun(oWindow)
wpfEnd()

# --------------------------------------------------------------------------

func selfTest
	dnAssert("rectangle",wpfPixel(oCanvas,200,120,40,30),"ff4682b4")
