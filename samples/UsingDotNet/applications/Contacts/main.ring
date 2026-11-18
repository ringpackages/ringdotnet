# A contacts book stored in a SQLite database with Entity Framework Core
#   ring main.ring                 (console menu)      ring main.ring --selftest
load "dotnet.ring"
using { "RingDotNet.Data" }

func main
	aSchema = [["Contacts",[["Id","int",1],["Name","string",0],["Phone","string",0],["City","string",0]]]]
	lTest = find(sysargv,"--selftest") > 0
	cConnection = "Data Source=contacts.db"
	if lTest
		cConnection = "Data Source=:memory:"
	ok
	oDb = new RingDatabase(cConnection,aSchema)
	if lTest
		selfTest(oDb)
		oDb.close()
		return
	ok
	while true
		? nl + "1 add  2 list  3 find by city  4 delete  0 quit"
		cChoice = trim(input("> "))
		switch cChoice
		on "1"
			cName = trim(input("Name: "))
			cPhone = trim(input("Phone: "))
			cCity = trim(input("City: "))
			oDb.insert("Contacts",[["Name",cName],["Phone",cPhone],["City",cCity]])
		on "2"
			showRows(oDb.all("Contacts"))
		on "3"
			showRows(oDb.where("Contacts","City = {0}",[trim(input("City: "))]))
		on "4"
			oDb.remove("Contacts",number(input("Id: ")))
		on "0"
			exit
		off
	end
	oDb.close()

func showRows aRows
	for aRow in aRows
		? dbValue(aRow,"Id") + "  " + dbValue(aRow,"Name") + "  " + dbValue(aRow,"Phone") + "  " + dbValue(aRow,"City")
	next
	? "" + len(aRows) + " contact(s)"

func selfTest oDb
	oDb.insert("Contacts",[["Name","Ann"],["Phone","111"],["City","Cairo"]])
	nBob = oDb.insert("Contacts",[["Name","Bob"],["Phone","222"],["City","Giza"]])
	oDb.insert("Contacts",[["Name","Cy"],["Phone","333"],["City","Cairo"]])
	dnAssert("three contacts",oDb.count("Contacts"),3)
	dnAssert("find by city",len(oDb.where("Contacts","City = {0}",["Cairo"])),2)
	oDb.update("Contacts",nBob,[["City","Cairo"]])
	dnAssert("after the update",len(oDb.where("Contacts","City = {0}",["Cairo"])),3)
	oDb.remove("Contacts",nBob)
	dnAssert("after the delete",oDb.count("Contacts"),2)
	? "SELFTEST " + iif(nDotNetFail = 0,"OK (" + nDotNetPass + " checks)","FAILED")

func iif lCondition, xYes, xNo
	if lCondition
		return xYes
	ok
	return xNo
