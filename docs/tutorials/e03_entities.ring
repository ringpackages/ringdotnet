# the tutorial "Entity objects and migrations", part 1: entity objects - the rows of a table as real objects with navigation properties
load "dotnet.ring"
using { "RingDotNet.Data" }

func main
	# The schema is the same as with RingDatabase. RingEntityDb turns every table into a .NET class.
	oDb = new RingEntityDb("Data Source=:memory:",[
		["Teams",[["Id","int",1],["Name","string",0,[["required",1]]]]],
		["Players",[["Id","int",1],["Name","string",0],["Goals","int",0,[["default",0]]],["TeamId","int",0,[["references","Teams"]]]]]
	])

	# The generated class has a property for every column, plus navigations that follow the foreign keys
	cProperties = ""
	for cProperty in oDb.properties("Players")
		cProperties += cProperty + " "
	next
	? "Properties of a Player : " + cProperties
	cProperties = ""
	for cProperty in oDb.properties("Teams")
		cProperties += cProperty + " "
	next
	? "Properties of a Team   : " + cProperties

	# STEP 1. Create objects: newEntity gives an empty object; set its properties; add() stores it
	oRed = oDb.newEntity("Teams")
	oRed.setProp("Name","Red")
	oDb.add(oRed)
	? nl + "STEP 1: the team got its key from the database: Id = " + oRed.getProp("Id")

	oAnn = oDb.newEntity("Players")
	oDb.fill(oAnn,[["Name","Ann"],["Goals",5]])
	oAnn.setProp("Team",oRed)                       # a navigation property: the foreign key is set for you
	oDb.add(oAnn)
	? "        Ann's TeamId   = " + oAnn.getProp("TeamId")

	oBob = oDb.newEntity("Players")
	oDb.fill(oBob,[["Name","Bob"],["Goals",2],["TeamId",1]])    # or set the foreign key directly
	oDb.add(oBob)
	? "        players stored : " + oDb.count("Players",[])

	# STEP 2. Read objects, with the related object loaded (include)
	? nl + "STEP 2: players with goals >= 3, with their team:"
	for oPlayer in oDb.query("Players",[ ["where",["Goals",">=",3]], ["include",["Team"]] ])
		? "        " + oPlayer.getProp("Name") + " plays for " + oPlayer.getProp("Team").getProp("Name")
	next

	# STEP 3. Objects are TRACKED: change a property, call save(), the change is written
	oAnn.setProp("Goals",8)
	oDb.save()
	oDb.discard()                                    # forget the tracked objects, so that the next read comes from the database
	? nl + "STEP 3: Ann's goals in the database: " + oDb.getValue(oDb.find("Players",1),"Goals")

	# STEP 4. The other direction: a team with its players
	for oTeam in oDb.query("Teams",[ ["include",["Players"]] ])
		? nl + "STEP 4: team " + oTeam.getProp("Name") + " has " + oTeam.getProp("Players").getProp("Count") + " players"
	next

	# STEP 5. Remove an object
	oDb.remove(oDb.find("Players",2))
	? "STEP 5: after removing Bob there are " + oDb.count("Players",[]) + " player(s)"
	oDb.close()
