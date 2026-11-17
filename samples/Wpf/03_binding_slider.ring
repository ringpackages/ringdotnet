# Data binding: the text follows the slider

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
}


oWindow = wpfWindow("Binding",320,150)
oPanel = new StackPanel()
oWindow.Content = oPanel
oSlider = new Slider() {
	Maximum = 100
	Margin = new Thickness(10,10,10,10)
}
oText = new WpfTextBox()
oText.Margin = new Thickness(10,10,10,10)
oBinding = dnNew("WpfBinding",[ :path = "Value" ])
oBinding.Source = oSlider
oText.SetBinding(oText.TextProperty,oBinding)
oPanel {
	Children.Add(oSlider)
	Children.Add(oText)
}

wpfTest(oWindow,"oSlider.Value = 64 dnAssert('binding',oText.Text,'64')")
wpfRun(oWindow)
wpfEnd()
