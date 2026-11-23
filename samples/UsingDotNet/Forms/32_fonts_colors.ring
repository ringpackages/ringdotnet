# Fonts, styles and colors

load "dotnet.ring"

using {
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = uiForm("Fonts and colors",360,230)
nY = 10
for cName in ["Segoe UI","Consolas","Georgia","Arial Black"]
	oLabel = uiLabel(oForm,cName + " - The quick brown fox",15,nY,330,30)
	oLabel.Font = uiFont(cName,14,false)
	nY += 36
next
oBold = uiLabel(oForm,"Bold dark red",15,nY,330,30)
oBold {
	Font = uiFont("Segoe UI",14,true)
	ForeColor = uiColor("DarkRed")
}

uiRun(oForm)
