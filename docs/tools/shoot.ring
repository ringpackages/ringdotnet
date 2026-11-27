# Captures the main window of a Ring program to a PNG and closes the program (Windows; uses ring-cffi, see shootlib.ring).
#
#     cd docs/tools
#     ring shoot.ring <folder of the program> <program.ring> <out.png> [delay in milliseconds (default 2500)] [arguments of the program]

load "shootlib.ring"

func main

	if len(sysargv) < 5
		? "usage: ring shoot.ring <folder> <program.ring> <out.png> [delay ms] [arguments]"
		return
	ok
	nDelay = 2500
	if len(sysargv) >= 6
		nDelay = number(sysargv[6])
	ok
	cArgs = ""
	if len(sysargv) >= 7
		cArgs = sysargv[7]
	ok
	? shootWindow(sysargv[3],sysargv[4],sysargv[5],nDelay,cArgs)
