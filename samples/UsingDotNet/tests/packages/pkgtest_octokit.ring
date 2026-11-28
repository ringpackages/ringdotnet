# Octokit: the GitHub client without a network: product header, credentials, the client and its parts, request and issue objects, API addresses
load "pkg.ring"
pkgUse("octokit",[["Octokit","13.0.1"]],[["Octokit.dll",["Octokit"]]])
pkgImport("octokit","Octokit.dll","Octokit")

oHeader = new OctokitProductHeaderValue("ring-test")
oClient = new GitHubClient(oHeader)
dnAssert("the base address",oClient.BaseAddress.ToString(),"https://api.github.com/")
dnAssert("the user agent has the product",substr(oClient.Connection.UserAgent,"ring-test") > 0,True)
dnAssert("the client has the parts",isobject(oClient.Repository),True)

# credentials
oToken = new Credentials("a-token")
dnAssert("a token is the authentication type",oToken.AuthenticationType,"Oauth")
oPassword = dnNew("Octokit.Credentials",["octocat","pw"])
dnAssert("a login",oPassword.Login,"octocat")
dnAssert("a password credential is basic",oPassword.AuthenticationType,"Basic")
dnAssert("the anonymous credentials",oToken.getAnonymous().AuthenticationType,"Anonymous")
oClient.Credentials = oToken
dnAssert("the client keeps the credentials",oClient.Credentials.AuthenticationType,"Oauth")

# request and issue objects
oIssue = new NewIssue("Ring can call .NET")
oIssue.Body = "It does."
oIssue.Labels.Add("enhancement")
oIssue.Assignees.Add("octocat")
dnAssert("an issue: the title",oIssue.Title,"Ring can call .NET")
dnAssert("an issue: the body",oIssue.Body,"It does.")
dnAssert("an issue: a label",oIssue.Labels.Count,1)
dnAssert("an issue: an assignee",oIssue.Assignees.Count,1)

oRepository = new NewRepository("ring-samples")
oRepository.Description = "Samples"
oRepository.AutoInit = True
dnAssert("a repository: the name",oRepository.Name,"ring-samples")
dnAssert("a repository: auto init",oRepository.AutoInit,True)

oRequest = new RepositoryRequest()
oRequest.Sort = "Updated"
dnAssert("a request: the sort",oRequest.Sort,"Updated")
oPaging = new ApiOptions()
oPaging.PageSize = 50
oPaging.PageCount = 2
dnAssert("paging: the page size",oPaging.PageSize,50)
dnAssert("paging: the page count",oPaging.PageCount,2)

# the addresses of the API
oUrls = new ApiUrls()
dnAssert("the address of the e-mails",oUrls.Emails().ToString(),"user/emails")

dnTestSummary()
