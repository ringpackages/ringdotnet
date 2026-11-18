# Entity Framework Core: relationships (foreign keys, children, parent, include, delete behaviors)
load "dotnetlib.ring"
dnUseData()

func main
	oDb = new RingDatabase("Data Source=:memory:",[
		["Authors",[["Id","int",1],["Name","string",0]]],
		["Books",[["Id","int",1],["Title","string",0],["AuthorId","int",0,[["references","Authors"],["ondelete","cascade"]]]]],
		["Reviews",[["Id","int",1],["Stars","int",0],["BookId","int",0,[["references","Books"],["ondelete","restrict"]]]]]
	])
	nTolkien = oDb.insert("Authors",[["Name","Tolkien"]])
	nLewis = oDb.insert("Authors",[["Name","Lewis"]])
	nHobbit = oDb.insert("Books",[["Title","The Hobbit"],["AuthorId",nTolkien]])
	oDb.insert("Books",[["Title","The Silmarillion"],["AuthorId",nTolkien]])
	nNarnia = oDb.insert("Books",[["Title","Narnia"],["AuthorId",nLewis]])
	oDb.insert("Reviews",[["Stars",5],["BookId",nHobbit]])

	aBooks = oDb.children("Authors",nTolkien,"Books")
	dnAssert("children",len(aBooks),2)
	dnAssert("children row",dbValue(aBooks[1],"Title"),"The Hobbit")
	dnAssert("parent",dbValue(oDb.parent("Books",nNarnia,"Authors"),"Name"),"Lewis")
	dnAssert("parent of a missing row",oDb.parent("Books",99,"Authors"),"")

	aAll = oDb.include("Authors","Books")
	dnAssert("include count",len(aAll),2)
	dnAssert("include author",dbValue(aAll[1][1],"Name"),"Tolkien")
	dnAssert("include children",len(aAll[1][2]),2)
	dnAssert("include children of the second",len(aAll[2][2]),1)
	aWithAuthor = oDb.include("Books","Authors")
	dnAssert("include parent",dbValue(aWithAuthor[3][2],"Name"),"Lewis")

	# a foreign key must point to an existing row
	lFailed = false
	try
		oDb.insert("Books",[["Title","Orphan"],["AuthorId",99]])
	catch
		lFailed = true
	done
	dnAssert("a foreign key to nothing is rejected",lFailed,1)

	# restrict: a book with reviews cannot be deleted
	lFailed = false
	try
		oDb.remove("Books",nHobbit)
	catch
		lFailed = true
	done
	dnAssert("restrict",lFailed,1)

	# cascade: deleting an author deletes the books
	oDb.remove("Authors",nLewis)
	dnAssert("cascade",oDb.count("Books"),2)
	dnAssert("the other books stay",dbValue(oDb.children("Authors",nTolkien,"Books")[2],"Title"),"The Silmarillion")

	lFailed = false
	try
		oDb.children("Authors",1,"Reviews")
	catch
		lFailed = true
	done
	dnAssert("unrelated tables",lFailed,1)
	oDb.close()
	dnTestSummary()
