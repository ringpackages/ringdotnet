# Tutorial 17: databases step by step - a library catalog with Entity Framework Core
load "dotnetlib.ring"
dnUseData()

func main
	# STEP 1. Describe the tables: [table name, [ [column, type, isKey, options], ... ]]
	aSchema = [
		["Authors",[
			["Id","int",1],                                   # a key of type int is numbered by the database
			["Name","string",0,[["required",1],["unique",1]]]
		]],
		["Books",[
			["Id","int",1],
			["Title","string",0,[["required",1],["maxlength",80]]],
			["Year","int",0,[["nullable",1]]],
			["Copies","int",0,[["default",1]]],
			["AuthorId","int",0,[["references","Authors"],["ondelete","cascade"]]]    # a foreign key
		]]
	]
	oDb = new RingDatabase("Data Source=:memory:",aSchema)     # a SQLite database in memory
	? "STEP 1: the database exists"

	# STEP 2. Add rows. insert() gives back the key
	nTolkien = oDb.insert("Authors",[["Name","J.R.R. Tolkien"]])
	nLewis = oDb.insert("Authors",[["Name","C.S. Lewis"]])
	oDb.insert("Books",[["Title","The Hobbit"],["Year",1937],["AuthorId",nTolkien],["Copies",3]])
	oDb.insert("Books",[["Title","The Fellowship of the Ring"],["Year",1954],["AuthorId",nTolkien]])
	oDb.insert("Books",[["Title","The Lion, the Witch and the Wardrobe"],["Year",1950],["AuthorId",nLewis]])
	oDb.insert("Books",[["Title","A book with no year"],["AuthorId",nLewis]])
	? "STEP 2: " + oDb.count("Authors") + " authors, " + oDb.count("Books") + " books"

	# STEP 3. Read rows. A row is a list of [column, value] pairs: dbValue() reads one column
	aRow = oDb.byKey("Books",1)
	? nl + "STEP 3: book 1 is " + dbValue(aRow,"Title") + ", copies " + dbValue(aRow,"Copies")
	? "        book 4 has year [" + dbValue(oDb.byKey("Books",4),"Year") + "] (empty: the column allows no value)"

	# STEP 4. Search with a SQL condition: {0} and {1} are parameters, never paste text into SQL yourself
	? nl + "STEP 4: books after 1940:"
	for aBook in oDb.where("Books","Year > {0}",[1940])
		? "        " + dbValue(aBook,"Title") + " (" + dbValue(aBook,"Year") + ")"
	next

	# STEP 5. Change and delete
	oDb.update("Books",4,[["Year",1951],["Title","Prince Caspian"]])
	? nl + "STEP 5: book 4 is now " + dbValue(oDb.byKey("Books",4),"Title")
	oDb.remove("Books",2)
	? "        books left: " + oDb.count("Books")

	# STEP 6. Mistakes are errors that you can catch: the database refuses wrong data
	try
		oDb.insert("Authors",[["Name","C.S. Lewis"]])          # the name must be unique
	catch
		? nl + "STEP 6: a duplicate author is refused"
	done
	try
		oDb.insert("Books",[["Title","Orphan"],["AuthorId",99]])   # there is no author 99
	catch
		? "        a book of a missing author is refused"
	done
	oDb.close()
