# Entity Framework Core with real entity classes (generated from the schema)
load "dotnet.ring"
dnUseData()

func main

	aSchema = [
		["Authors",[["Id","int",1],["Name","string",0,[["required",1]]]]],
		["Books",[["Id","int",1],["Title","string",0],["Year","int",0],["Pages","int",0,[["nullable",1]]],["AuthorId","int",0,[["references","Authors"],["ondelete","cascade"]]]]]
	]
	for cConnection in ["Data Source=:memory:","inmemory:typed"]
		oDb = new RingEntityDb(cConnection,aSchema)
		cKind = cConnection

		dnAssert(cKind + " the generated class",oDb.entityType("Books").Name,"Books")
		aProps = oDb.properties("Books")
		dnAssert(cKind + " properties",len(aProps),6)
		dnAssert(cKind + " the navigation to the parent",aProps[6],"Author")
		dnAssert(cKind + " the collection on the parent",oDb.properties("Authors")[3],"Books")

		oTolkien = oDb.newEntity("Authors")
		oTolkien.setProp("Name","Tolkien")
		nId = oDb.add(oTolkien)
		dnAssert(cKind + " generated key",nId,1)
		dnAssert(cKind + " the key is set on the entity",oTolkien.getProp("Id"),1)

		oBook = oDb.newEntity("Books")
		oDb.fill(oBook,[["Title","The Hobbit"],["Year",1937],["AuthorId",nId]])
		oDb.add(oBook)
		oBook2 = oDb.newEntity("Books")
		oDb.fill(oBook2,[["Title","The Silmarillion"],["Year",1977],["Pages",365]])
		oBook2.setProp("Author",oTolkien)				# a navigation property
		oDb.add(oBook2)
		dnAssert(cKind + " count",oDb.count("Books",[]),2)
		dnAssert(cKind + " the foreign key follows the navigation",oBook2.getProp("AuthorId"),1)

		aBooks = oDb.query("Books",[ ["orderby",[["Year","desc"]]] ])
		dnAssert(cKind + " query",len(aBooks),2)
		dnAssert(cKind + " order",oDb.getValue(aBooks[1],"Title"),"The Silmarillion")
		dnAssert(cKind + " nullable",oDb.getValue(aBooks[2],"Pages"),"")
		aBooks = oDb.query("Books",[ ["where",["Year","<",1950]] ])
		dnAssert(cKind + " where",len(aBooks),1)
		dnAssert(cKind + " toRow",dbValue(oDb.toRow(aBooks[1]),"Title"),"The Hobbit")

		# change tracking: a changed property is saved by save()
		aBooks[1].setProp("Title","The Hobbit (1st edition)")
		oDb.save()
		oDb.discard()
		dnAssert(cKind + " tracked change",oDb.getValue(oDb.find("Books",1),"Title"),"The Hobbit (1st edition)")

		# navigation with include
		aBooks = oDb.query("Books",[ ["include",["Author"]], ["where",["Title","contains","Silm"]] ])
		dnAssert(cKind + " include",aBooks[1].getProp("Author").getProp("Name"),"Tolkien")
		aAuthors = oDb.query("Authors",[ ["include",["Books"]] ])
		dnAssert(cKind + " the collection",aAuthors[1].getProp("Books").getProp("Count"),2)
		dnAssert(cKind + " the collection items",len(aAuthors[1].getProp("Books").toList()),2)

		oDb.remove(oDb.find("Books",2))
		dnAssert(cKind + " remove",oDb.count("Books",[]),1)
		dnAssert(cKind + " find a missing entity",oDb.find("Books",99),"")
		if cConnection = "Data Source=:memory:"
			lFailed = false
			try
				oBad = oDb.newEntity("Authors")
				oDb.add(oBad)				# the name is required
			catch
				lFailed = true
			done
			dnAssert(cKind + " required column",lFailed,1)
			oDb.remove(oDb.find("Authors",1))
			dnAssert(cKind + " cascade",oDb.count("Books",[]),0)
		ok
		oDb.close()
	next
	dnTestSummary()
