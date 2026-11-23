# WPF data binding - controls that follow each other: a slider, a text box, a progress bar, a check box and a list, all in XAML
load "dotnet.ring"

using {
	"System.Windows"
	"System.Windows.Controls"
	"System"
}

oWindow = ""

func main

	# A BINDING connects a property of one control to a property of another: when one changes, the other follows, and no Ring code runs.
	#   {Binding ElementName=amount, Path=Value}   the property Value of the element named "amount"
	#   Mode=TwoWay                                the change goes both ways (a text box writes back to the slider)
	#   UpdateSourceTrigger=PropertyChanged        write back at each key, not only when the text box loses the focus
	#   StringFormat=N0                            the format string of the tutorial about formatting (the first {} is for the XAML parser)
	#   FallbackValue                              what to show when the path has no value
	cXaml = '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="Binding" Width="380" Height="400" Background="#F4F2FB">'
	cXaml += '<StackPanel Margin="16">'
	cXaml += '<TextBlock Text="Amount (drag the slider, or type a number)"/>'
	cXaml += '<Slider x:Name="amount" Minimum="0" Maximum="100" Value="20" Margin="0,6,0,6"/>'
	cXaml += '<TextBox x:Name="box" Width="80" HorizontalAlignment="Left" Text="{Binding ElementName=amount, Path=Value, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged, StringFormat=N0}"/>'
	cXaml += '<ProgressBar x:Name="bar" Height="16" Margin="0,10,0,0" Maximum="100" Value="{Binding ElementName=amount, Path=Value}"/>'
	cXaml += '<TextBlock x:Name="text" Margin="0,6,0,0" Text="{Binding ElementName=amount, Path=Value, StringFormat={}{0:F0} percent}"/>'
	cXaml += '<CheckBox x:Name="allow" Content="Allow sending" IsChecked="True" Margin="0,16,0,6"/>'
	cXaml += '<Button x:Name="send" Content="Send" Width="100" HorizontalAlignment="Left" IsEnabled="{Binding ElementName=allow, Path=IsChecked}"/>'
	cXaml += '<TextBlock Text="Color" Margin="0,16,0,4"/>'
	cXaml += '<ListBox x:Name="colors" Height="70"><ListBoxItem Content="Red"/><ListBoxItem Content="Green"/><ListBoxItem Content="Blue"/></ListBox>'
	cXaml += '<TextBlock x:Name="chosen" Margin="0,6,0,0" Text="{Binding ElementName=colors, Path=SelectedItem.Content, FallbackValue=nothing chosen}"/>'
	cXaml += '</StackPanel></Window>'
	oWindow = wpfXaml(cXaml)

	wpfRun(oWindow)
