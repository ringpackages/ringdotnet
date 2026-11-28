# Sentry: the options, events, scopes, breadcrumbs, users and identifiers of the error reporting client; nothing is sent
load "pkg.ring"
pkgUse("sentry",[["Sentry","4.13.0"]],[["Sentry.dll",["Sentry"]]])
pkgImport("sentry","Sentry.dll","Sentry")

oOptions = new SentryOptions()
oOptions.Dsn = "https://publickey@o123.ingest.sentry.io/456"
oOptions.Environment = "testing"
oOptions.SampleRate = 0.5
oOptions.MaxBreadcrumbs = 25
oOptions.SendDefaultPii = False
oOptions.AttachStacktrace = True
dnAssert("the dsn",oOptions.Dsn,"https://publickey@o123.ingest.sentry.io/456")
dnAssert("the environment",oOptions.Environment,"testing")
dnAssert("the sample rate",oOptions.SampleRate,0.5)
dnAssert("the number of breadcrumbs",oOptions.MaxBreadcrumbs,25)
dnAssert("personal data is not sent",oOptions.SendDefaultPii,False)
dnAssert("the stack trace",oOptions.AttachStacktrace,True)

# an event: tags, extra data and breadcrumbs
oEvent = new SentryEvent()
oEvent.SetTag("module","payments")
oEvent.SetTag("version","1.2")
oEvent.SetExtra("order",1234)
oEvent.Environment = "testing"
oEvent.Logger = "ring"
dnAssert("the event tags",oEvent.Tags.Count,2)
dnAssert("a tag",oEvent.Tags.Item("module"),"payments")
dnAssert("the extra data",oEvent.Extra.Count,1)
dnAssert("the event environment",oEvent.Environment,"testing")
dnAssert("the logger",oEvent.Logger,"ring")
oEvent.UnsetTag("version")
dnAssert("a tag was removed",oEvent.Tags.Count,1)
dnAssert("a new event has an id",oEvent.EventId.ToString() != "00000000000000000000000000000000",True)

# the identifier of an event is 32 hexadecimal characters
oId = (new SentryId).Create()
dnAssert("an identifier has 32 characters",len(oId.ToString()),32)
oParsed = (new SentryId).Parse(oId.ToString())
dnAssert("parse gives the same identifier",oParsed.ToString(),oId.ToString())
dnAssert("the empty identifier",oId.getEmpty().ToString(),"00000000000000000000000000000000")

# a user
oUser = new SentryUser()
oUser.Id = "42"
oUser.Username = "ann"
oUser.Email = "ann@example.com"
dnAssert("the user",oUser.Username,"ann")
dnAssert("the user mail",oUser.Email,"ann@example.com")

# a scope keeps the context that is added to every event, and a copy is separate
oScope = new Scope(oOptions)
oScope.SetTag("area","billing")
oScope.SetExtra("attempt",3)
oScope.User = oUser
dnAssert("the scope tags",oScope.Tags.Count,1)
dnAssert("the scope user",oScope.User.Id,"42")
dnAssert("the scope has a user",oScope.HasUser(),True)
oCopy = oScope.Clone()
oCopy.SetTag("extra","yes")
dnAssert("the copy has the new tag",oCopy.Tags.Count,2)
dnAssert("the scope is not changed by the copy",oScope.Tags.Count,1)
oScope.Clear()
dnAssert("a cleared scope has no tags",oScope.Tags.Count,0)

# an event has a text
cJson = oEvent.ToString()
dnAssert("the event text is not empty",len(cJson) > 0,True)

dnTestSummary()
