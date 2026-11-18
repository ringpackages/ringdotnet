# A grid with rows, columns and attached properties

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
}


oWindow = wpfWindow("Grid",360,200)
oGrid = new Grid()
oWindow.Content = oGrid
fillGrid()

wpfTest(oWindow,"selfTest()")
wpfRun(oWindow)
wpfEnd()

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

func selfTest
	dnAssert("9 cells",oGrid.Children.Count,9)
	dnAssert("3 rows",oGrid.RowDefinitions.Count,3)
	oFifth = oGrid.Children.Item(4)
	dnAssert("attached row",oGrid.GetRow(oFifth),1)
	dnAssert("attached column",oGrid.GetColumn(oFifth),1)
