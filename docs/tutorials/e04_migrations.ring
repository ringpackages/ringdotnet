# Tutorial 27, part 2: changing a database that already has data - migrations
load "dotnet.ring"
dnUseData()
using {
	"System.IO"
}

func main
	cFile = new Path().Combine(new Path().GetTempPath(),"ringdotnet_tutorial27.db")
	if new File().Exists(cFile)
		new File().Delete(cFile)
	ok
	cConnection = "Data Source=" + cFile

	# VERSION 1 of the program: a table of contacts with a name
	oDb = new RingDatabase(cConnection,[
		["Contacts",[["Id","int",1],["Name","string",0]]]
	])
	oDb.insert("Contacts",[["Name","Ann"]])
	oDb.insert("Contacts",[["Name","Bob"]])
	? "VERSION 1: " + oDb.count("Contacts") + " contacts stored in the file"
	oDb.close()

	# VERSION 2: you want a Phone column, a Notes table, and an index on Name.
	# Opening the OLD file with the NEW schema is not enough: the file still has the old tables.
	oDb = new RingDatabase(cConnection,[
		["Contacts",[["Id","int",1],["Name","string",0,[["index",1]]],["Phone","string",0],["Level","int",0,[["default",1]]]]],
		["Notes",[["Id","int",1],["Text","string",0],["ContactId","int",0,[["references","Contacts"]]]]]
	])

	# migrate() compares the file with the schema and makes what is missing. The old rows are kept.
	aChanges = oDb.migrate()
	? nl + "VERSION 2: migrate() made " + len(aChanges) + " changes:"
	for cChange in aChanges
		? "   " + cChange
	next
	aOld = oDb.byKey("Contacts",1)
	? nl + "The old row is still there: " + dbValue(aOld,"Name") + ", phone [" + dbValue(aOld,"Phone") + "], level " + dbValue(aOld,"Level")

	# Now the new columns and the new table work
	oDb.update("Contacts",1,[["Phone","555-0100"]])
	oDb.insert("Notes",[["Text","met at the conference"],["ContactId",1]])
	? "Ann's phone: " + dbValue(oDb.byKey("Contacts",1),"Phone") + ", notes: " + len(oDb.children("Contacts",1,"Notes"))

	# Migrating again changes nothing
	? "Migrating again: " + len(oDb.migrate()) + " changes"

	# A change that is not a new column or table is done with SQL, once, by name.
	? nl + "Promote everybody (first time) : " + oDb.apply("001-promote","UPDATE Contacts SET Level = 5")
	? "Promote everybody (second time): " + oDb.apply("001-promote","UPDATE Contacts SET Level = 9")
	oDb.discard()
	? "Level now: " + dbValue(oDb.byKey("Contacts",1),"Level") + " (the second one did not run)"
	? "Applied changes: " + oDb.applied()[1]
	oDb.close()
	new File().Delete(cFile)
