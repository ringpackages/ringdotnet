# The smallest WPF window

load "dotnet.ring"
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


oWindow = wpfWindow("Hello WPF",320,160)
oPanel = new StackPanel()
oWindow.Content = oPanel
oText = new TextBlock() {
	Text = "Hello from Ring and WPF!"
	FontSize = 20
	Margin = new Thickness(20,30,20,0)
}
oPanel.Children.Add(oText)

wpfTest(oWindow,"dnAssert('title',oWindow.Title,'Hello WPF') dnAssert('text',oText.Text,'Hello from Ring and WPF!') dnAssert('size',oWindow.Width,320)")
wpfRun(oWindow)
wpfEnd()
