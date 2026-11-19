# the checks of 01_hello_form.ring: run with  ring 01_hello_form.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest
	dnAssert("label text",oLabel.Text,"Hello from Ring and .NET!")
	dnAssert("form title",oForm.Text,"Hello")
