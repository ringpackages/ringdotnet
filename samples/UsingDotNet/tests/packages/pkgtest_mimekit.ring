# MimeKit: an e-mail message built offline (addresses, subject, text and HTML bodies, an attachment), written as MIME text, and parsed back
load "pkg.ring"
pkgUse("mimekit",[["MimeKit","5.0.0"]],[["MimeKit.Core.dll",["MimeKit"]]])
pkgImport("mimekit","MimeKit.Core.dll","MimeKit")
dnImport("System.IO")

oMessage = new MimeMessage()
oFrom = dnNew("MimeKit.MailboxAddress",["Ring Sender","sender@example.org"])
oTo = dnNew("MimeKit.MailboxAddress",["Ann Lee","ann@example.org"])
oMessage.From.Add(oFrom)
oMessage.To.Add(oTo)
oMessage.Subject = "Hello from Ring"
dnAssert("the subject",oMessage.Subject,"Hello from Ring")
dnAssert("one sender",oMessage.From.Count,1)
dnAssert("the address of the recipient",oMessage.To.Mailboxes.toList()[1].Address,"ann@example.org")
dnAssert("the name of the recipient",oMessage.To.Mailboxes.toList()[1].Name,"Ann Lee")

# a body with a text and an HTML version, and an attachment: the body builder
oBuilder = new BodyBuilder()
oBuilder.TextBody = "plain text of the message"
oBuilder.HtmlBody = "<p>html <b>text</b> of the message</p>"
oBuilder.Attachments.Add([ :fileName = "data.txt", :data = "the attached data" ])
oMessage.Body = oBuilder.ToMessageBody()
dnAssert("the body has parts",oMessage.Body.ContentType.MimeType,"multipart/mixed")
dnAssert("the text body",oMessage.TextBody,"plain text of the message")
dnAssert("the HTML body",substr(oMessage.HtmlBody,"<b>text</b>") > 0,1)
aAttachments = oMessage.Attachments.toList()
dnAssert("one attachment",len(aAttachments),1)
dnAssert("the name of the attachment",aAttachments[1].ContentDisposition.FileName,"data.txt")

# the message as MIME text
cMime = oMessage.ToString()
dnAssert("the MIME text has the headers",substr(cMime,"Subject: Hello from Ring") > 0 and substr(cMime,"To: Ann Lee <ann@example.org>") > 0,1)
dnAssert("the MIME text has the parts",substr(cMime,"multipart/mixed") > 0 and substr(cMime,"multipart/alternative") > 0,1)

# parse the text back
oStream = new MemoryStream().@New(cMime)
oBack = dnStatic("MimeKit.MimeMessage","Load",[oStream])
dnAssert("the subject read back",oBack.Subject,"Hello from Ring")
dnAssert("the text read back",oBack.TextBody,"plain text of the message")
dnAssert("the attachment read back",oBack.Attachments.toList()[1].ContentDisposition.FileName,"data.txt")

# an address that is not valid
aTry = dnStatic("MimeKit.MailboxAddress","TryParse",["not an address"])
dnAssert("a bad address does not parse",aTry[1],0)
dnAssert("a good address parses",dnStatic("MimeKit.MailboxAddress","TryParse",["Bo <bo@example.org>"])[1],1)

dnTestSummary()
