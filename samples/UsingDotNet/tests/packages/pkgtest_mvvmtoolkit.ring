# CommunityToolkit.Mvvm: commands (RelayCommand with the action and the check as callbacks, and its CanExecuteChanged event) and the messenger
# (a message of a generic type is sent to the recipients that registered for it)
load "pkg.ring"
pkgUse("mvvmtoolkit",[["CommunityToolkit.Mvvm","8.4.0"]],[["CommunityToolkit.Mvvm.dll",["CommunityToolkit.Mvvm.Input","CommunityToolkit.Mvvm.Messaging","CommunityToolkit.Mvvm.ComponentModel"]]])
pkgImport("mvvmtoolkit","CommunityToolkit.Mvvm.dll","CommunityToolkit.Mvvm.Input")
pkgImport("mvvmtoolkit","CommunityToolkit.Mvvm.dll","CommunityToolkit.Mvvm.Messaging")

aLog = []
nAllowed = 1
oCommand = dnNew("CommunityToolkit.Mvvm.Input.RelayCommand",[dnCallback("runCommand"),dnCallback("checkCommand")])
dnAssert("a command that is allowed",oCommand.CanExecute(NULL),1)
oCommand.Execute(NULL)
oCommand.Execute(NULL)
dnAssert("the action ran twice",len(aLog),2)
nAllowed = 0
dnAssert("a command that is not allowed",oCommand.CanExecute(NULL),0)

# the event that tells a view to ask again, and a command with a parameter (the generic RelayCommand<T>)
nChanged = 0
oCommand.setCanExecuteChangedEvent("commandChanged")
oCommand.NotifyCanExecuteChanged()
dnAssert("CanExecuteChanged reached the Ring callback",nChanged,1)
oCommand.clearCanExecuteChangedEvent()
oCommand.NotifyCanExecuteChanged()
dnAssert("a cleared handler is not called",nChanged,1)
cPlus = "CommunityToolkit.Mvvm.Input.RelayCommand`1[[System.Int32]]"
nTotal = 0
oPlus = dnNew(cPlus,[dnCallback("addToTotal")])
oPlus.Execute(5)
oPlus.Execute(7)
dnAssert("a command with a parameter",nTotal,12)

# the messenger: a recipient registers for a type of message, and the message is sent to it
oMessenger = dnStatic("CommunityToolkit.Mvvm.Messaging.WeakReferenceMessenger","get_Default",[])
aGot = []
cRecipientType = "CommunityToolkit.Mvvm.Input.RelayCommand`1[[System.Int32]]"
oExtensions = dnType("CommunityToolkit.Mvvm.Messaging.IMessengerExtensions")
oExtensions.callGeneric("Register",[cRecipientType,"System.String"],[oMessenger,oPlus,dnCallback("onMessage")])
oMessenger.callGeneric("Send",["System.String"],["hello"])
oMessenger.callGeneric("Send",["System.String"],["again"])
dnAssert("the recipient got both messages",len(aGot),2)
dnAssert("the first message",aGot[1],"hello")
oMessenger.UnregisterAll(oPlus)
oMessenger.callGeneric("Send",["System.String"],["nobody listens"])
dnAssert("a recipient that was unregistered gets nothing",len(aGot),2)
dnTestSummary()

func runCommand aArgs

	aLog + "ran"

func checkCommand aArgs

	return nAllowed

func commandChanged aArgs

	nChanged++

func addToTotal aArgs

	nTotal += aArgs[1]

func onMessage aArgs

	aGot + aArgs[2]
