# Loan calculator - monthly payment, total interest and the first rows of the amortization table

load "dotnet.ring"
using {
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Loan calculator",520,420)
uiLabel(oForm,"Loan amount",15,18,100,22)
oAmount = uiTextBox(oForm,120,15,120,26)
oAmount.Text = "20000"
uiLabel(oForm,"Interest % / year",15,52,105,22)
oRate = uiTextBox(oForm,120,49,120,26)
oRate.Text = "6"
uiLabel(oForm,"Years",15,86,100,22)
oYears = uiTextBox(oForm,120,83,120,26)
oYears.Text = "5"
uiButton(oForm,"Calculate",120,120,120,32,"calculate()")
oPayment = uiLabel(oForm,"",270,15,240,24)
oPayment.Font = uiFont("Segoe UI",13,true)
oInterest = uiLabel(oForm,"",270,48,240,24)
oTotal = uiLabel(oForm,"",270,78,240,24)
oTable = new ListView() {
	Location = new Point(15,165)
	Size = new Size(490,245)
	View = "Details"
	GridLines = True
	FullRowSelect = True
}
for aColumn in [["Month",60],["Payment",100],["Interest",100],["Principal",100],["Balance",110]]
	oTable.Columns.Add([ :text = aColumn[1], :width = aColumn[2] ])
next
oForm.Controls.Add(oTable)

calculate()
uiRun(oForm)

# --------------------------------------------------------------------------

func money nValue
	return uiNumber(floor(nValue * 100 + 0.5) / 100)

# the monthly payment of a loan
func monthlyPayment nAmount, nYearlyRate, nYears
	nMonths = nYears * 12
	nMonthlyRate = nYearlyRate / 100 / 12
	if nMonthlyRate = 0
		return nAmount / nMonths
	ok
	return nAmount * nMonthlyRate / (1 - pow(1 + nMonthlyRate,-nMonths))

func calculate
	nAmount = number(oAmount.Text)
	nRate = number(oRate.Text)
	nYears = number(oYears.Text)
	oTable.Items.Clear()
	if nAmount <= 0 or nYears <= 0 or nRate < 0
		oPayment.Text = "Check the input"
		oInterest.Text = ""
		oTotal.Text = ""
		return
	ok
	nPayment = monthlyPayment(nAmount,nRate,nYears)
	nMonths = floor(nYears * 12)
	nBalance = nAmount
	nTotalInterest = 0
	for nMonth = 1 to nMonths
		nInterestPart = nBalance * nRate / 100 / 12
		nPrincipal = nPayment - nInterestPart
		nBalance -= nPrincipal
		nTotalInterest += nInterestPart
		if nMonth <= 12
			oItem = new ListViewItem().@New([ :text = "" + nMonth ])
			oItem.SubItems.Add(money(nPayment))
			oItem.SubItems.Add(money(nInterestPart))
			oItem.SubItems.Add(money(nPrincipal))
			oItem.SubItems.Add(money(fabs(nBalance)))
			oTable.Items.Add(oItem)
		ok
	next
	oPayment.Text = "Monthly payment: " + money(nPayment)
	oInterest.Text = "Total interest: " + money(nTotalInterest)
	oTotal.Text = "Total paid: " + money(nAmount + nTotalInterest)
