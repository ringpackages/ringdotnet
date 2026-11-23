# the checks of LoginForm.ring: run with  ring LoginForm.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	dnAssert("sha-256 of abc",hashOf("abc"),"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
	oSignIn.PerformClick()
	dnAssert("empty fields",oMessage.Text,"Please fill in both fields")
	dnAssert("error provider message",oErrors.GetError(oUser),"Enter the user name")
	oUser.Text = "admin"
	oPassword.Text = "secret"
	oSignIn.PerformClick()
	dnAssert("login ok",oMessage.Text,"Welcome, admin!")
	dnAssert("errors cleared",oErrors.GetError(oUser),"")
	oPassword.Text = "wrong"
	oSignIn.PerformClick()
	dnAssert("wrong password",left(oMessage.Text,5),"Wrong")
	oSignIn.PerformClick()
	oSignIn.PerformClick()
	dnAssert("locked after 3 attempts",oSignIn.Enabled,False)
	oSignIn.Enabled = True
	nAttempts = 0
	oUser.Text = "newuser"
	oPassword.Text = "pw123"
	registerUser()
	dnAssert("registered",oMessage.Text,"User newuser created")
	registerUser()
	dnAssert("duplicate user",oMessage.Text,"That user name is taken")
	dnAssert("password char hidden",oPassword.UseSystemPasswordChar,True)
	oShow.Checked = True
	togglePassword()
	dnAssert("show password turns the mask off",oPassword.UseSystemPasswordChar,False)
