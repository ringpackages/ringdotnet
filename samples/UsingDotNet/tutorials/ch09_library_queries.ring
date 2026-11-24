# the tutorial "Databases step by step", part 2: relations, queries, transactions and a file database
load "dotnet.ring"

using {
	"System.IO"
	"RingDotNet.Data"
}

func main

	cFile = new Path().Combine([new Path().GetTempPath(),"ringdotnet_library.db"])
	if new File().Exists(cFile)
		new File().Delete(cFile)
	ok
	aSchema = [
		["Authors",[["Id","int",1],["Name","string",0,[["required",1]]]]],
		["Books",[["Id","int",1],["Title","string",0],["Year","int",0],["Stars","double",0],
			["AuthorId","int",0,[["references","Authors"],["ondelete","cascade"]]]]]
	]
	oDb = new RingDatabase("Data Source=" + cFile,aSchema)    # a file: the data stays after the program ends
	nTolkien = oDb.insert("Authors",[["Name","Tolkien"]])
	nLewis = oDb.insert("Authors",[["Name","Lewis"]])
	oDb.insert("Books",[["Title","The Hobbit"],["Year",1937],["Stars",4.7],["AuthorId",nTolkien]])
	oDb.insert("Books",[["Title","The Fellowship of the Ring"],["Year",1954],["Stars",4.8],["AuthorId",nTolkien]])
	oDb.insert("Books",[["Title","The Silmarillion"],["Year",1977],["Stars",4.1],["AuthorId",nTolkien]])
	oDb.insert("Books",[["Title","Narnia"],["Year",1950],["Stars",4.5],["AuthorId",nLewis]])

	# RELATIONS: the rows that belong to a row
	? "Books by Tolkien:"
	aBooks = oDb.children("Authors",nTolkien,"Books")
	for aBook in aBooks
		? "  " + dbValue(aBook,"Title")
	next
	? "Narnia was written by " + dbValue(oDb.parent("Books",4,"Authors"),"Name")
	? nl + "Authors with their books:"
	aItems = oDb.include("Authors","Books")
	for aItem in aItems
		? "  " + dbValue(aItem[1],"Name") + ": " + len(aItem[2]) + " book(s)"
	next

	# QUERIES: filter, sort and page with a query written as data
	aBest = oDb.query("Books",[
		["where",["Stars",">=",4.5]],
		["orderby",[["Year","desc"]]],
		["select",["Title","Year"]]
	])
	? nl + "Books with at least 4.5 stars, newest first:"
	for aBook in aBest
		? "  " + dbValue(aBook,"Year") + "  " + dbValue(aBook,"Title")
	next
	? nl + "Average stars : " + oDb.average("Books","Stars",[])
	? "Best rating   : " + oDb.max("Books","Stars",[])
	? "Books per author:"
	aGroups = oDb.groupCount("Books","AuthorId",[])
	for aGroup in aGroups
		? "  author " + aGroup[1] + " -> " + aGroup[2]
	next

	# TRANSACTIONS: all or nothing
	oDb.begin()
	oDb.insert("Books",[["Title","Draft 1"],["Year",2024],["Stars",1],["AuthorId",nLewis]])
	oDb.insert("Books",[["Title","Draft 2"],["Year",2024],["Stars",1],["AuthorId",nLewis]])
	? nl + "Books inside the transaction: " + oDb.count("Books")
	oDb.rollback()
	? "Books after rollback        : " + oDb.count("Books")

	# THE FILE: close the database, open it again, the data is still there
	oDb.close()
	oAgain = new RingDatabase("Data Source=" + cFile,aSchema)
	? nl + "After reopening the file: " + oAgain.count("Books") + " books"
	oAgain.close()
	new File().Delete(cFile)
