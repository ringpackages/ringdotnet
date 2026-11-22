# Makaretu.Dns: DNS messages built as objects, written to the wire format (a binary text) and read back; a binary protocol
load "pkg.ring"
pkgUse("dns",[["Makaretu.Dns","2.0.1"]],[["Makaretu.Dns.dll",["Makaretu.Dns"]]])
pkgImport("dns","Makaretu.Dns.dll","Makaretu.Dns")

oMessage = new Message()
oMessage.Id = 1234
oQuestion = new Question()
oQuestion.Name = dnNew("Makaretu.Dns.DomainName",["example.com"])
oQuestion.Type = dnStatic("Makaretu.Dns.DnsType","A",[])
oMessage.Questions.Add(oQuestion)
dnAssert("a question was added",oMessage.Questions.Count,1)

cWire = oMessage.ToByteArray()
dnAssert("a header of 12 bytes and a question",len(cWire) > 12 + 13,1)
dnAssert("the id is in the first two bytes",ascii(cWire[1]) * 256 + ascii(cWire[2]),1234)

oBack = new Message()
oBack.callMethod("Read",[cWire])
dnAssert("the id is read back",oBack.Id,1234)
dnAssert("the question is read back",oBack.Questions.Count,1)
dnAssert("the name of the question",oBack.Questions.Item(0).Name.ToString(),"example.com")

dnAssert("a label count",dnNew("Makaretu.Dns.DomainName",["www.example.com"]).Labels.Count,3)

dnTestSummary()
