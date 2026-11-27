# Captures the main window of a Ring program as a PNG: starts the program, waits for its window, copies the window with PrintWindow, crops it to the
# frame that Windows draws (without the invisible border) and closes the program. The Windows API is called with ring-cffi (ringpm install ring-cffi
# from ysdragon); the PNG is written by GDI+. Windows only. Used by shoot.ring, shoot_all.ring and shoot_tutorials.ring.

load "cffi.ring"
load "doclib.ring"

C_RING_EXE = "B:\ring\bin\ring.exe"
C_BIN_FOLDER = "B:\newpro\ringdotnet\bin"

aWin = []                  # the functions of the Windows API, by name (made by winInit)
oWinUser = NULL
oWinKernel = NULL
oWinGdiplus = NULL
oWinDwm = NULL
aWinStarted = []

func winInit

	if len(aWinStarted) > 0
		return
	ok
	aWinStarted + 1
	oWinUser = new FFI("user32.dll")
	oWinKernel = new FFI("kernel32.dll")
	oWinGdiplus = new FFI("gdiplus.dll")
	oWinDwm = new FFI("dwmapi.dll")
	aWin + ["SetThreadDpiAwarenessContext",oWinUser.cFunc("SetThreadDpiAwarenessContext","ptr",["intptr_t"])]
	aWin + ["GetDpiForSystem",oWinUser.cFunc("GetDpiForSystem","uint",[])]
	aWin + ["GetTopWindow",oWinUser.cFunc("GetTopWindow","ptr",["ptr"])]
	aWin + ["GetWindow",oWinUser.cFunc("GetWindow","ptr",["ptr","uint"])]
	aWin + ["GetWindowThreadProcessId",oWinUser.cFunc("GetWindowThreadProcessId","uint",["ptr","ptr"])]
	aWin + ["IsWindowVisible",oWinUser.cFunc("IsWindowVisible","int",["ptr"])]
	aWin + ["GetClassNameW",oWinUser.cFunc("GetClassNameW","int",["ptr","ptr","int"])]
	aWin + ["GetWindowRect",oWinUser.cFunc("GetWindowRect","int",["ptr","ptr"])]
	aWin + ["PrintWindow",oWinUser.cFunc("PrintWindow","int",["ptr","ptr","uint"])]
	aWin + ["GetWindowDpiAwarenessContext",oWinUser.cFunc("GetWindowDpiAwarenessContext","ptr",["ptr"])]
	aWin + ["GetAwarenessFromDpiAwarenessContext",oWinUser.cFunc("GetAwarenessFromDpiAwarenessContext","int",["ptr"])]
	aWin + ["DwmGetWindowAttribute",oWinDwm.cFunc("DwmGetWindowAttribute","int",["ptr","uint","ptr","uint"])]
	aWin + ["SetEnvironmentVariableW",oWinKernel.cFunc("SetEnvironmentVariableW","int",["ptr","ptr"])]
	aWin + ["CreateProcessW",oWinKernel.cFunc("CreateProcessW","int",["ptr","ptr","ptr","ptr","int","uint","ptr","ptr","ptr","ptr"])]
	aWin + ["TerminateProcess",oWinKernel.cFunc("TerminateProcess","int",["ptr","uint"])]
	aWin + ["GetExitCodeProcess",oWinKernel.cFunc("GetExitCodeProcess","int",["ptr","ptr"])]
	aWin + ["CloseHandle",oWinKernel.cFunc("CloseHandle","int",["ptr"])]
	aWin + ["Sleep",oWinKernel.cFunc("Sleep","void",["uint"])]
	aWin + ["GdiplusStartup",oWinGdiplus.cFunc("GdiplusStartup","int",["ptr","ptr","ptr"])]
	aWin + ["GdipCreateBitmapFromScan0",oWinGdiplus.cFunc("GdipCreateBitmapFromScan0","int",["int","int","int","int","ptr","ptr"])]
	aWin + ["GdipGetImageGraphicsContext",oWinGdiplus.cFunc("GdipGetImageGraphicsContext","int",["ptr","ptr"])]
	aWin + ["GdipGetDC",oWinGdiplus.cFunc("GdipGetDC","int",["ptr","ptr"])]
	aWin + ["GdipReleaseDC",oWinGdiplus.cFunc("GdipReleaseDC","int",["ptr","ptr"])]
	aWin + ["GdipDeleteGraphics",oWinGdiplus.cFunc("GdipDeleteGraphics","int",["ptr"])]
	aWin + ["GdipCloneBitmapAreaI",oWinGdiplus.cFunc("GdipCloneBitmapAreaI","int",["int","int","int","int","int","ptr","ptr"])]
	aWin + ["GdipSaveImageToFile",oWinGdiplus.cFunc("GdipSaveImageToFile","int",["ptr","ptr","ptr","ptr"])]
	aWin + ["GdipDisposeImage",oWinGdiplus.cFunc("GdipDisposeImage","int",["ptr"])]
	# GDI+ must be started once
	oInput = oWinGdiplus.defineStruct("GdiplusStartupInput",[["GdiplusVersion","uint32"],["DebugEventCallback","ptr"],["SuppressBackgroundThread","int"],["SuppressExternalCodecs","int"]])
	pInput = oWinGdiplus.structNew(oInput)
	oWinGdiplus.ptrSet(oWinGdiplus.field(pInput,oInput,"GdiplusVersion"),"uint32",1)
	pToken = oWinGdiplus.alloc("ptr")
	winCall("GdiplusStartup",[pToken,pInput,oWinGdiplus.nullptr()])

# a function of the Windows API
func winCall cName,aArgs

	for aItem in aWin
		if aItem[1] = cName
			return cffi_invoke(aItem[2],aArgs)
		ok
	next
	raise("Windows function not made: " + cName)

# the number at the pointer p: an array of int
func winInt p,nIndex

	return cffi_get(p,"int",nIndex)

# the rectangle (left, top, right, bottom) of a window, or of its frame
func windowRect hWnd,lFrame

	pRect = cffi_new("int",4)
	if lFrame
		if winCall("DwmGetWindowAttribute",[hWnd,9,pRect,16]) != 0
			winCall("GetWindowRect",[hWnd,pRect])
		ok
	else
		winCall("GetWindowRect",[hWnd,pRect])
	ok
	return [winInt(pRect,0),winInt(pRect,1),winInt(pRect,2),winInt(pRect,3)]

# the visible window of a process that has the biggest area (the console windows do not count), or NULL
func findWindow nPid

	hBest = cffi_nullptr()
	nBestArea = 0
	pPid = cffi_new("uint",1)
	pClass = cffi_new("char",512)
	h = winCall("GetTopWindow",[cffi_nullptr()])
	nGuard = 0
	while not cffi_isnull(h) and nGuard < 5000
		winCall("GetWindowThreadProcessId",[h,pPid])
		if cffi_get(pPid,"uint") = nPid and winCall("IsWindowVisible",[h]) != 0
			winCall("GetClassNameW",[h,pClass,256])
			cClass = cffi_wtostring(pClass)
			if cClass != "ConsoleWindowClass" and left(cClass,7) != "CASCADIA"
				aRect = windowRect(h,false)
				nArea = (aRect[3] - aRect[1]) * (aRect[4] - aRect[2])
				if nArea > nBestArea
					hBest = h
					nBestArea = nArea
				ok
			ok
		ok
		h = winCall("GetWindow",[h,2])
		nGuard++
	end
	return hBest

# [int] of PowerShell: rounds to the nearest whole number, the even one at .5
func roundEven x

	nFloor = floor(x)
	nDiff = x - nFloor
	if nDiff < 0.5
		return nFloor
	but nDiff > 0.5
		return nFloor + 1
	ok
	if nFloor % 2 = 0
		return nFloor
	ok
	return nFloor + 1

# The window of a Ring program as a PNG. cDir is the folder of the program (the working folder), cScript the program, cOut the PNG file,
# nDelay the milliseconds to wait for the window to be drawn, cRingArgs the arguments of the program. Returns "OK <file> <w>x<h>" or "NOWINDOW <script>".
func shootWindow cDir,cScript,cOut,nDelay,cRingArgs

	winInit()
	winCall("SetThreadDpiAwarenessContext",[-4])
	# the program runs with the bin folder of the package first in PATH and without RING_HOME
	cPath = sysget("PATH")
	winCall("SetEnvironmentVariableW",[cffi_wstring("PATH"),cffi_wstring(substr(C_BIN_FOLDER,"/","\") + ";" + cPath)])
	winCall("SetEnvironmentVariableW",[cffi_wstring("RING_HOME"),cffi_nullptr()])
	cCommand = '"' + C_RING_EXE + '" "' + cScript + '" ' + cRingArgs
	cCommand = pyStrip(cCommand)
	oInfo = cffi_struct("STARTUPINFOW",[["cb","uint32"],["lpReserved","ptr"],["lpDesktop","ptr"],["lpTitle","ptr"],["dwX","uint32"],["dwY","uint32"],["dwXSize","uint32"],["dwYSize","uint32"],["dwXCountChars","uint32"],["dwYCountChars","uint32"],["dwFillAttribute","uint32"],["dwFlags","uint32"],["wShowWindow","uint16"],["cbReserved2","uint16"],["lpReserved2","ptr"],["hStdInput","ptr"],["hStdOutput","ptr"],["hStdError","ptr"]])
	pInfo = cffi_struct_new(oInfo)
	cffi_set(cffi_field(pInfo,oInfo,"cb"),"uint32",cffi_struct_size(oInfo))
	oProcess = cffi_struct("PROCESS_INFORMATION",[["hProcess","ptr"],["hThread","ptr"],["dwProcessId","uint32"],["dwThreadId","uint32"]])
	pProcess = cffi_struct_new(oProcess)
	nOk = winCall("CreateProcessW",[cffi_nullptr(),cffi_wstring(cCommand),cffi_nullptr(),cffi_nullptr(),0,134217728,cffi_nullptr(),cffi_wstring(substr(cDir,"/","\")),pInfo,pProcess])
	if nOk = 0
		return "NOWINDOW " + cScript
	ok
	hProcess = cffi_get(cffi_field(pProcess,oProcess,"hProcess"),"ptr")
	nPid = cffi_get(cffi_field(pProcess,oProcess,"dwProcessId"),"uint32")
	pCode = cffi_new("uint",1)
	lFound = false
	hWnd = cffi_nullptr()
	nStart = clock()
	while true
		winCall("Sleep",[300])
		hWnd = findWindow(nPid)
		lFound = not cffi_isnull(hWnd)
		if lFound
			exit
		ok
		winCall("GetExitCodeProcess",[hProcess,pCode])
		if cffi_get(pCode,"uint") != 259 or (clock() - nStart) / clockspersecond() > 25
			exit
		ok
	end
	if not lFound
		winCall("GetExitCodeProcess",[hProcess,pCode])
		nCode = cffi_get(pCode,"uint")
		winCall("TerminateProcess",[hProcess,1])
		winCall("CloseHandle",[hProcess])
		if nCode != 259
			return "NOWINDOW " + cScript + " (the program ended by itself, exit code " + nCode + ", before its window could be captured)"
		ok
		return "NOWINDOW " + cScript + " (no window in 25 seconds)"
	ok
	winCall("Sleep",[nDelay])
	hWnd = findWindow(nPid)
	if cffi_isnull(hWnd)
		winCall("TerminateProcess",[hProcess,1])
		winCall("CloseHandle",[hProcess])
		return "NOWINDOW " + cScript + " (the program closed its window before the capture)"
	ok
	aRect = windowRect(hWnd,false)
	nWidth = aRect[3] - aRect[1]
	nHeight = aRect[4] - aRect[2]
	# the Ring process is DPI unaware: its window is drawn at the logical size and scaled by Windows
	nScale = winCall("GetDpiForSystem",[]) / 96
	hContext = winCall("GetWindowDpiAwarenessContext",[hWnd])
	if winCall("GetAwarenessFromDpiAwarenessContext",[hContext]) > 0
		nScale = 1
	ok
	nWidth = ceil(nWidth / nScale)
	nHeight = ceil(nHeight / nScale)
	# a 32 bit bitmap of GDI+ and the window printed into it
	pBitmap = cffi_new("ptr",1)
	winCall("GdipCreateBitmapFromScan0",[nWidth,nHeight,0,2498570,cffi_nullptr(),pBitmap])
	pGraphics = cffi_new("ptr",1)
	hBitmap = cffi_get(pBitmap,"ptr")
	winCall("GdipGetImageGraphicsContext",[hBitmap,pGraphics])
	hGraphics = cffi_get(pGraphics,"ptr")
	pDc = cffi_new("ptr",1)
	winCall("GdipGetDC",[hGraphics,pDc])
	hDc = cffi_get(pDc,"ptr")
	winCall("PrintWindow",[hWnd,hDc,2])
	winCall("GdipReleaseDC",[hGraphics,hDc])
	winCall("GdipDeleteGraphics",[hGraphics])
	# the frame that Windows draws: the window without the invisible border
	aFrame = windowRect(hWnd,true)
	nX = roundEven((aFrame[1] - aRect[1]) / nScale)
	nY = roundEven((aFrame[2] - aRect[2]) / nScale)
	nCropWidth = roundEven((aFrame[3] - aFrame[1]) / nScale)
	nCropHeight = roundEven((aFrame[4] - aFrame[2]) / nScale)
	if nX + nCropWidth > nWidth
		nCropWidth = nWidth - nX
	ok
	if nY + nCropHeight > nHeight
		nCropHeight = nHeight - nY
	ok
	pCropped = cffi_new("ptr",1)
	winCall("GdipCloneBitmapAreaI",[nX,nY,nCropWidth,nCropHeight,2498570,hBitmap,pCropped])
	hCropped = cffi_get(pCropped,"ptr")
	cFolder = parentFolder(substr(cOut,"\","/"))
	if cFolder != "" and not direxists(cFolder)
		system("mkdir " + substr(cFolder,"/","\"))
	ok
	# the PNG encoder of GDI+: {557CF406-1A04-11D3-9A73-0000F81EF32E}
	pClsid = cffi_new("uint8",16)
	aBytes = [6,244,124,85,4,26,211,17,154,115,0,0,248,30,243,46]
	for nByte = 1 to 16
		cffi_set(pClsid,"uint8",aBytes[nByte],nByte - 1)
	next
	nSaved = winCall("GdipSaveImageToFile",[hCropped,cffi_wstring(substr(cOut,"/","\")),pClsid,cffi_nullptr()])
	winCall("GdipDisposeImage",[hCropped])
	winCall("GdipDisposeImage",[hBitmap])
	winCall("TerminateProcess",[hProcess,1])
	winCall("CloseHandle",[hProcess])
	if nSaved != 0
		return "FAILED " + cScript + " (GDI+ error " + nSaved + ")"
	ok
	return "OK " + cOut + " " + nCropWidth + "x" + nCropHeight
