# the checks of 03_binding_slider.ring: run with  ring 03_binding_slider.ring --selftest  (the program loads this file and runs selfTest() once its window is shown)

func selfTest

	oSlider.Value = 64
	dnAssert("binding",oText.Text,"64")
