# Login form with validation, a password hash and an error provider

load "dotnet.ring"
using {
	"System"
	"System.Text"
	"System.Security.Cryptography"
	"System.Drawing"
	"System.Windows.Forms"
}

# the "database": user name -> SHA-256 hash of the password
aUsers = []
nAttempts = 0

oForm = uiForm("Sign in",340,240)
oForm {
	FormBorderStyle = "FixedDialog"
	MaximizeBox = False
}
uiLabel(oForm,"User name",20,22,90,22)
oUser = uiTextBox(oForm,115,19,190,26)
uiLabel(oForm,"Password",20,62,90,22)
oPassword = uiTextBox(oForm,115,59,190,26)
oPassword.UseSystemPasswordChar = True
oShow = uiCheckBox(oForm,"Show password",115,92,150,24,"togglePassword()")
oSignIn = uiButton(oForm,"Sign in",115,125,90,32,"signIn()")
uiButton(oForm,"Register",215,125,90,32,"registerUser()")
oMessage = uiLabel(oForm,"",20,170,300,40)
oErrors = new ErrorProvider()
oForm.AcceptButton = oSignIn
register("admin","secret")

uiRun(oForm)

# --------------------------------------------------------------------------

func hashOf cPassword
	cBytes = new SHA256().HashData(cPassword)
	return lower(new Convert().ToHexString(cBytes))

func register cName, cPassword
	for aUser in aUsers
		if aUser[1] = lower(cName)
			return false
		ok
	next
	aUsers + [lower(cName),hashOf(cPassword)]
	return true

func checkLogin cName, cPassword
	for aUser in aUsers
		if aUser[1] = lower(cName) and aUser[2] = hashOf(cPassword)
			return true
		ok
	next
	return false

func togglePassword
	oPassword.UseSystemPasswordChar = not oShow.Checked

# true when the fields are filled (the error provider shows an icon next to an empty one)
func validate
	lValid = true
	if trim(oUser.Text) = ""
		oErrors.SetError(oUser,"Enter the user name")
		lValid = false
	else
		oErrors.SetError(oUser,"")
	ok
	if oPassword.Text = ""
		oErrors.SetError(oPassword,"Enter the password")
		lValid = false
	else
		oErrors.SetError(oPassword,"")
	ok
	return lValid

func signIn
	if not validate()
		oMessage.Text = "Please fill in both fields"
		return
	ok
	nAttempts++
	if checkLogin(oUser.Text,oPassword.Text)
		oMessage {
			ForeColor = uiColor("DarkGreen")
			Text = "Welcome, " + oUser.Text + "!"
		}
		nAttempts = 0
	else
		oMessage {
			ForeColor = uiColor("Firebrick")
			Text = "Wrong user name or password (attempt " + nAttempts + " of 3)"
		}
		if nAttempts >= 3
			oSignIn.Enabled = False
			oMessage.Text = "Too many attempts: sign in is disabled"
		ok
	ok

func registerUser
	if validate()
		if register(oUser.Text,oPassword.Text)
			oMessage {
				ForeColor = uiColor("DarkGreen")
				Text = "User " + oUser.Text + " created"
			}
		else
			oMessage {
				ForeColor = uiColor("Firebrick")
				Text = "That user name is taken"
			}
		ok
	ok
