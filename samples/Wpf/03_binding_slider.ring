# Data binding: the text follows the slider

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


oWindow = wpfWindow("Binding",320,150)
oPanel = new StackPanel()
oWindow.Content = oPanel
oSlider = new Slider()
oSlider.Maximum = 100
oSlider.Margin = new Thickness(10,10,10,10)
oText = new WpfTextBox()
oText.Margin = new Thickness(10,10,10,10)
oBinding = new WpfBinding().New_1("Value")
oBinding.Source = oSlider
oText.SetBinding(oText.TextProperty,oBinding)
oPanel.Children.Add(oSlider)
oPanel.Children.Add(oText)

wpfTest(oWindow,"oSlider.Value = 64 dnAssert('binding',oText.Text,'64')")
wpfRun(oWindow)
wpfEnd()
