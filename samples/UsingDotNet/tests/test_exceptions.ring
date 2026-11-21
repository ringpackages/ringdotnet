# Exceptions and attributes have Ring classes: objects that .NET gives back (an inner exception, a task's exception, an attribute) are wrapped
load "dotnet.ring"
dnImport("System")
dnImport("System.ComponentModel")
dnImport("System.Threading.Tasks")

# an exception object: made, read, and wrapped when it comes back
oError = new ArgumentException().@New([ :message = "not good", :paramName = "value" ])
dnAssert("exception class",classname(oError),"argumentexception")
dnAssert("exception message",left(oError.Message,8),"not good")
dnAssert("exception parameter name",oError.ParamName,"value")
oOuter = new InvalidOperationException().@New([ :message = "outer", :innerException = oError ])
oInner = oOuter.InnerException
dnAssert("inner exception is wrapped",classname(oInner),"argumentexception")
dnAssert("inner exception, a property",oInner.ParamName,"value")
dnAssert("the base class members are there",oOuter.GetBaseException().ParamName,"value")

# an exception that a task keeps
oTask = new Task().FromException(oError)
dnAssert("exception of a task",classname(oTask.Exception),"aggregateexception")
dnAssert("exception of a task, inner",oTask.Exception.InnerException.ParamName,"value")

# an attribute that a type has
oAttribute = new DisplayNameAttribute().@New([ :displayName = "Total" ])
dnAssert("attribute class",classname(oAttribute),"displaynameattribute")
dnAssert("attribute property",oAttribute.DisplayName,"Total")

dnTestSummary()
