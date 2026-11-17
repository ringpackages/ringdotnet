# RingDotNet applications

Small Windows Forms applications written in Ring with RingDotNet. Many are ports of the RingQt applications in `ring/applications`.

Run one: `cd Calculator` then `ring main.ring`.

Every application can test itself: `ring main.ring --selftest` drives the form, checks the results with `dnAssert()` and prints `SELFTEST OK`. `tests/run.sh` runs all of them.

They use the helpers of `libraries/dotnetlib/gui.ring` (`uiForm`, `uiButton`, `uiLabel`, `uiTextBox`, `uiTimer`, `uiMenu`, `UiCanvas`, `uiTest`, `uiRun`...), loaded together with `dnImport("System.Windows.Forms")`.
