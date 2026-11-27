# Imports every namespace of the manifest: a generated file that does not load stops here (used by checkgenerator.ring)
#   ring importall.ring
load "../../libraries/dotnetlib/dotnetlib.ring"
load "dotnetmanifest.ring"

func main

	dnUseAll()
	nOk = 0
	aBad = []
	for aEntry in aDotNetManifest
		try
			dnImport(aEntry[:namespace])
			nOk++
		catch
			aBad + (aEntry[:namespace] + ": " + left(cCatchError,160))
		done
	next
	? "IMPORTED " + nOk + " namespaces, " + len(aBad) + " failed"
	for cBad in aBad
		? "  FAILED " + cBad
	next
