# The smallest WPF window

load "../../libraries/dotnetlib/dotnetlib.ring"
dnUseDesktop()
dnImport("System.Windows")
dnImport("System.Windows.Controls")
dnImport("System.Windows.Controls.Primitives")
dnImport("System.Windows.Media")
dnImport("System.Windows.Shapes")
dnImport("System.Windows.Data")
dnImport("System.Windows.Threading")
dnImport("System")


oWindow = wpfWindow("Hello WPF",320,160)
oPanel = new StackPanel()
oWindow.Content = oPanel
oText = new TextBlock()
oText.Text = "Hello from Ring and WPF!"
oText.FontSize = 20
oText.Margin = new Thickness(20,30,20,0)
oPanel.Children.Add(oText)

wpfTest(oWindow,"dnAssert('title',oWindow.Title,'Hello WPF') dnAssert('text',oText.Text,'Hello from Ring and WPF!') dnAssert('size',oWindow.Width,320)")
wpfRun(oWindow)
wpfEnd()
