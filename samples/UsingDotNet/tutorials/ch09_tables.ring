# tabular data - read a CSV text, use a DataTable, filter, sort, summarise, write a CSV
load "dotnet.ring"

using {
	"System"
	"System.Data"
	"System.IO"
}

func main

	# STEP 1. The data: a CSV text (comma separated values): a header line and one line per row
	cCsv = "Region,Seller,Amount" + nl +
		"North,Ann,1200" + nl +
		"South,Bob,800" + nl +
		"North,Cy,450" + nl +
		"East,Dee,2000" + nl +
		"South,Eve,300" + nl +
		"North,Ann,700"

	# STEP 2. A DataTable has typed columns and rows
	oTable = new DataTable()
	oTable.Columns.Add([ :columnName = "Region", :type = "System.String" ])
	oTable.Columns.Add([ :columnName = "Seller", :type = "System.String" ])
	oTable.Columns.Add([ :columnName = "Amount", :type = "System.Int32" ])
	aLines = str2list(cCsv)
	for nLine = 2 to len(aLines)                         # line 1 is the header
		aFields = str2list(substr(aLines[nLine],",",nl))
		oTable.Rows.Add([aFields[1],aFields[2],number(aFields[3])])
	next
	? "STEP 2: " + oTable.Rows.Count + " rows, " + oTable.Columns.Count + " columns"

	# STEP 3. Compute: SUM, AVG, MIN, MAX, COUNT over all rows or those that match a filter
	? nl + "STEP 3: total          : " + oTable.Compute("SUM(Amount)","")
	? "        North total      : " + oTable.Compute("SUM(Amount)","Region = 'North'")
	? "        biggest sale     : " + oTable.Compute("MAX(Amount)","")
	? "        sales over 500   : " + oTable.Compute("COUNT(Amount)","Amount > 500")

	# STEP 4. A DataView sorts and filters without changing the table
	oView = oTable.DefaultView
	oView.Sort = "Amount DESC"
	? nl + "STEP 4: top three sales:"
	for nIndex = 0 to 2
		? "        " + oView.Item(nIndex).Item("Seller") + "  " + oView.Item(nIndex).Item("Amount")
	next
	oView.RowFilter = "Region = 'South'"
	? "        rows in the South: " + oView.Count
	oView.RowFilter = ""

	# STEP 5. Totals per region: collect the regions, then compute for each
	aRegions = []
	for nIndex = 0 to oTable.Rows.Count - 1
		cRegion = oTable.Rows.Item(nIndex).Item("Region")
		if find(aRegions,cRegion) = 0
			aRegions + cRegion
		ok
	next
	aRegions = sort(aRegions)
	? nl + "STEP 5: totals per region:"
	for cRegion in aRegions
		? "        " + cRegion + "  " + oTable.Compute("SUM(Amount)","Region = '" + cRegion + "'")
	next

	# STEP 6. Write the table back as CSV
	cOut = "Region,Seller,Amount" + nl
	for nIndex = 0 to oTable.Rows.Count - 1
		oRow = oTable.Rows.Item(nIndex)
		cOut += oRow.Item("Region") + "," + oRow.Item("Seller") + "," + oRow.Item("Amount") + nl
	next
	cFile = new Path().Combine([new Path().GetTempPath(),"ringdotnet_tables.csv"])
	new File().WriteAllText([ :path = cFile, :contents = cOut ])
	? nl + "STEP 6: wrote " + len(new File().ReadAllLines(cFile).toList()) + " lines to a CSV file"
	new File().Delete(cFile)
