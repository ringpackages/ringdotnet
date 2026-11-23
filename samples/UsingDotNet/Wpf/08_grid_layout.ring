# A grid with rows, columns and attached properties

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

oWindow = wpfWindow("Grid",360,200)
oGrid = new Grid()
oWindow.Content = oGrid
fillGrid()

wpfRun(oWindow)

# --------------------------------------------------------------------------

func fillGrid

	for nIndex = 1 to 3
		oGrid.RowDefinitions.Add(new RowDefinition())
		oGrid.ColumnDefinitions.Add(new ColumnDefinition())
	next
	for nRow = 0 to 2
		for nColumn = 0 to 2
			oCell = new TextBlock() {
				Text = "" + (nRow * 3 + nColumn + 1)
				HorizontalAlignment = "Center"
				VerticalAlignment = "Center"
			}
			oGrid.Children.Add(oCell)
			oGrid.SetRow(oCell,nRow)
			oGrid.SetColumn(oCell,nColumn)
		next
	next
