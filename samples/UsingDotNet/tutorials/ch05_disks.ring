# disks and free space - DriveInfo: the drives of the computer, size, free space, and a check before a big write
load "dotnet.ring"
using {
	"System"
	"System.IO"
}

func main
	# Drive names, sizes and formats are different on each computer, so this program prints what is true on every computer (counts, yes/no)
	# and a few sizes that come from its own functions.

	# 1. Sizes for people. A number of bytes such as 1610612736 is hard to read: 1.5 GB is easy. Each step divides by 1024.
	? "1. formatSize:"
	for nBytes in [ 0, 512, 1024, 1536, 1048576, 1610612736, 5497558138880 ]
		? "   " + padRight("" + nBytes,16) + formatSize(nBytes)
	next

	# 2. DriveInfo.GetDrives() lists the drives (the letters of Windows, the mounted file systems of Linux and macOS)
	oAny = new DriveInfo(new Path().GetPathRoot(new Path().GetTempPath()))     # static methods are called through any object of the class
	aDrives = oAny.GetDrives().toList()
	nReady = 0
	for oDrive in aDrives
		if oDrive.IsReady
			nReady++
		ok
	next
	? nl + "2. the computer has drives: " + yesNo(len(aDrives) > 0) + ", ready to use: " + yesNo(nReady > 0)

	# 3. The drive of a folder. The root of a path (the drive letter on Windows, "/" on Linux) is the name of its drive. Here: the folder for
	#    temporary files.
	cFolder = new Path().GetTempPath()
	cRoot = new Path().GetPathRoot(cFolder)
	oDrive = new DriveInfo(cRoot)
	? nl + "3. the drive of the temporary folder: ready " + yesNo(oDrive.IsReady) + ", type " + oDrive.DriveType

	# 4. Sizes: TotalSize is the whole drive, TotalFreeSpace all the free space, AvailableFreeSpace the free space for the current user
	#    (a disk quota can make it smaller). Always use AvailableFreeSpace when you ask "will it fit?".
	nTotal = oDrive.TotalSize
	nFree = oDrive.TotalFreeSpace
	nAvailable = oDrive.AvailableFreeSpace
	? nl + "4. the total size is more than the free space: " + yesNo(nTotal > nFree)
	? "   available for the user is not more than the free space: " + yesNo(nAvailable <= nFree)
	nPercent = floor(100 * nFree / nTotal)
	? "   the percentage of free space is between 0 and 100: " + yesNo(nPercent >= 0 and nPercent <= 100)

	# 5. Will it fit? A program that writes a big file checks the free space first and says what is needed, instead of failing in the middle.
	? nl + "5. will it fit?"
	for nNeeded in [ 1048576, 5497558138880 * 1000 ]
		? "   " + padRight(formatSize(nNeeded),14) + fits(oDrive,nNeeded)
	next

	# 6. A name that is not a drive name raises an error; the program prints the kind of the error.
	try
		oOther = new DriveInfo("?")
		? nl + "6. a drive with an impossible name was accepted"
	catch
		? nl + "6. a drive with an impossible name: " + errorKind(cCatchError)
	done

func fits oDrive,nBytes
	nAvailable = oDrive.AvailableFreeSpace
	if nBytes <= nAvailable
		return "fits"
	ok
	return "does not fit: " + formatSize(nBytes - nAvailable) + " more is needed"

# 1024 bytes = 1 KB, 1024 KB = 1 MB, ... one decimal, and no decimal for whole bytes
func formatSize nBytes
	aUnits = [ "bytes", "KB", "MB", "GB", "TB", "PB" ]
	nValue = nBytes
	nUnit = 1
	while nValue >= 1024 and nUnit < len(aUnits)
		nValue = nValue / 1024
		nUnit++
	end
	if nUnit = 1
		return "" + nBytes + " bytes"
	ok
	nTenths = floor(nValue * 10 + 0.5)                   # rounded to one decimal: the whole part, a point, the tenth
	return "" + floor(nTenths / 10) + "." + (nTenths % 10) + " " + aUnits[nUnit]

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"

func padRight cText,nWidth
	return cText + copy(" ",nWidth - len(cText))

func errorKind cMessage
	cText = trim(cMessage)
	nStart = substr(cText,"DotNet Error: ")
	if nStart > 0
		cText = substr(cText,nStart + 14)
	ok
	nEnd = substr(cText,":")
	if nEnd > 0
		cText = left(cText,nEnd - 1)
	ok
	return cText
