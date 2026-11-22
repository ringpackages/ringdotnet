# Stateless: a state machine; the generic type is made with its type arguments, states and triggers are texts, the rules are chained
load "pkg.ring"
pkgUse("stateless",[["Stateless","5.20.1"]],[["Stateless.dll",["Stateless"]]])
pkgImport("stateless","Stateless.dll","Stateless")

oMachine = new StateMachine([ :typeArguments = ["System.String","System.String"], :initialState = "off" ])
dnAssert("the initial state",oMachine.State,"off")

oOff = oMachine.Configure("off")
oOff.Permit("switch","on")
oOn = oMachine.Configure("on")
oOn.Permit("switch","off")
oOn.Permit("break","broken")

dnAssert("a trigger that is allowed",oMachine.CanFire([ :trigger = "switch" ]),1)
dnAssert("a trigger that is not allowed",oMachine.CanFire([ :trigger = "break" ]),0)
oMachine.Fire([ :trigger = "switch" ])
dnAssert("the state after a trigger",oMachine.State,"on")
oMachine.Fire([ :trigger = "switch" ])
dnAssert("and back",oMachine.State,"off")
oMachine.Fire([ :trigger = "switch" ])
oMachine.Fire([ :trigger = "break" ])
dnAssert("another state",oMachine.State,"broken")
dnAssert("IsInState",oMachine.IsInState("broken"),1)

# a trigger that no rule allows is an error
try
	oMachine.Fire([ :trigger = "switch" ])
	dnAssert("an invalid trigger is an error",1,0)
catch
	dnAssert("an invalid trigger is an error",substr(cCatchError,"InvalidOperationException") > 0 or substr(cCatchError,"No valid leaving transitions") > 0,1)
done

# the triggers that are allowed in a state
oOther = new StateMachine([ :typeArguments = ["System.String","System.String"], :initialState = "on" ])
oOther.Configure("on").Permit("switch","off")
dnAssert("the permitted triggers",oOther.GetPermittedTriggers().Count,1)

dnTestSummary()
