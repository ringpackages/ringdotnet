# Shapes on a canvas, rendered to a bitmap to check the colors

load "../../libraries/dotnetlib/dotnetlib.ring"
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


oCanvas = new Canvas()
oCanvas.Width = 200
oCanvas.Height = 120
oCanvas.Background = wpfBrush("White")
oRect = new WpfRectangle()
oRect.Width = 80
oRect.Height = 50
oRect.Fill = wpfBrush("SteelBlue")
oCanvas.Children.Add(oRect)
oCanvas.SetLeft(oRect,10)
oCanvas.SetTop(oRect,10)
oCircle = new Ellipse()
oCircle.Width = 60
oCircle.Height = 60
oCircle.Fill = wpfBrush("Orange")
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
