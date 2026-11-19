# a project - a command runner (a window that starts a program and shows what it prints)
load "dotnet.ring"
using {
	"System"
	"System.Diagnostics"
	"System.Drawing"
	"System.Windows.Forms"
}

oForm = ""
oCommand = ""
oOutput = ""
oStatus = ""

func main
	oForm = uiForm("Command runner",560,380)
	uiLabel(oForm,"Command:",10,12,70,22)
	oCommand = uiTextBox(oForm,84,10,380,24)
	oCommand.Text = "echo hello from the command line"
	uiButton(oForm,"Run",472,8,76,28,"runCommand()")
	oOutput = uiMemo(oForm,10,46,538,300)
	oOutput {
		Font = new Font("Consolas",10)
		ReadOnly = True
		BackColor = new Color().Black
		ForeColor = new Color().LightGreen
	}
	oStatus = uiLabel(oForm,"Type a command and press Run",10,352,538,22)

	uiTest(oForm,"selfTest()")
	uiRun(oForm)
	uiEnd()

# Run "cmd /c <command>", wait for it, show everything it printed and its exit code
func runCommand
	cCommand = trim(oCommand.Text)
	if cCommand = ""
		return
	ok
	oInfo = new ProcessStartInfo() {
		FileName = "cmd"
		Arguments = "/c " + cCommand
		RedirectStandardOutput = True
		RedirectStandardError = True
		UseShellExecute = False
		CreateNoWindow = True
	}
	oStatus.Text = "Running..."
	oWatch = new Stopwatch()
	oWatch.Start()
	try
		oProcess = new Process().Start([ :startInfo = oInfo ])
		cOut = oProcess.StandardOutput.ReadToEnd()
		cErr = oProcess.StandardError.ReadToEnd()
		oProcess.WaitForExit(NULL)
		oWatch.Stop()
		oOutput.Text = cOut + cErr
		oStatus.Text = "Exit code " + oProcess.ExitCode + ", " + oWatch.ElapsedMilliseconds + " ms"
		oProcess.Dispose()
	catch
		oOutput.Text = "Could not run the command: " + cCatchError
		oStatus.Text = "Failed"
	done

func selfTest
	oCommand.Text = "echo one && echo two"
	runCommand()
	dnAssert("the output has both lines",substr(oOutput.Text,"one") > 0 and substr(oOutput.Text,"two") > 0,True)
	dnAssert("the exit code is shown",substr(oStatus.Text,"Exit code 0") > 0,True)
	oCommand.Text = "dir c:\folder\that\does\not\exist"
	runCommand()
	dnAssert("an error text appears",len(trim(oOutput.Text)) > 0,True)
	dnAssert("the exit code is not 0",substr(oStatus.Text,"Exit code 0") = 0,True)
	oCommand.Text = "echo done"
	runCommand()
	dnAssert("the status",substr(oStatus.Text," ms") > 0,True)
