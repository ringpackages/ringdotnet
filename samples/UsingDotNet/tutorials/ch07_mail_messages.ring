# e-mail messages - addresses, a MailMessage with several recipients, an attachment, a body in HTML and in text (nothing is sent)
load "dotnet.ring"

using {
	"System"
	"System.IO"
	"System.Net.Mail"
	"System.Net.Mime"
	"System.Text"
}

func main

	# 1. MailAddress reads "Name <user@host>" and splits it. A wrong address raises an error, so it is a check too.
	oAddress = new MailAddress("Ann Lee <ann.lee@example.com>")
	? "1. display name: " + oAddress.DisplayName
	? "   user: " + oAddress.User + ", host: " + oAddress.Host + ", address: " + oAddress.Address
	for cText in ["bob@example.com","bob@","bob@@example.com","@example.com"]
		? "   '" + cText + "' is an address: " + isAddress(cText)
	next

	# 2. A message: from, to, cc, subject and body. Nothing is sent here: SmtpClient.Send would do that with a server.
	oMessage = new MailMessage()
	oMessage.From = new MailAddress("Ann Lee <ann.lee@example.com>")
	oMessage.To.Add("bob@example.com")
	oMessage.To.Add("Carla <carla@example.com>")
	oMessage.CC.Add("boss@example.com")
	oMessage.Subject = "Meeting on Friday"
	oMessage.Body = "Hello," + nl + "the meeting is on Friday at 10:00." + nl + "Ann"
	? nl + "2. from: " + oMessage.From.Address
	? "   to: " + oMessage.To.Count + " people, cc: " + oMessage.CC.Count + " person"
	aPersons = oMessage.To.toList()
	for oPerson in aPersons
		? "      " + oPerson.DisplayName + " <" + oPerson.Address + ">"
	next
	? "   subject: " + oMessage.Subject
	? "   body is HTML: " + oMessage.IsBodyHtml

	# 3. HTML with a text version: AlternateViews hold the same message in more than one form, and the mail program shows the best one
	oText = dnStatic("System.Net.Mail.AlternateView","CreateAlternateViewFromString",["Meeting on Friday at 10:00",dnNull(),"text/plain"])
	oHtml = dnStatic("System.Net.Mail.AlternateView","CreateAlternateViewFromString",["<p>Meeting on <b>Friday</b> at 10:00</p>",dnNull(),"text/html"])
	oMessage.AlternateViews.Add(oText)
	oMessage.AlternateViews.Add(oHtml)
	? nl + "3. views: " + oMessage.AlternateViews.Count + " (" + oText.ContentType.MediaType + ", " + oHtml.ContentType.MediaType + ")"

# A text is an address when MailAddress accepts it (a wrong one raises an error)
func isAddress cText

	try
		new MailAddress(cText)
		return True
	catch
		return False
	done
