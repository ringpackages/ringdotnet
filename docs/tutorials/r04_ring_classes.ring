# Ring in 15 minutes, part 4: classes and objects (the code at the top comes first, the classes go LAST: a func or class swallows what follows)

func main
	# 1. new makes an object. The parentheses call init().
	oAnn = new Person("Ann",31)
	? oAnn.name
	oAnn.birthday()
	? oAnn.describe()

	# 2. Attributes are read and written with a dot. An attribute that the class does not have is an error.
	oAnn.age = 40
	? oAnn.age

	# 3. Braces: set attributes (and call methods) of the object inside { }. This is the style of this documentation.
	oBob = new Person("Bob",25) {
		city = "Oslo"
	}
	? oBob.describe()

	# 4. Inheritance: "from" takes everything of the parent and adds or replaces
	oEva = new Student("Eva",20,"Physics")
	? oEva.describe()
	? oEva.isAdult()

	# 5. Objects are COPIED when assigned to another variable: change the copy and the original stays
	oCopy = oAnn
	oCopy.name = "Copy"
	? oAnn.name

	# 6. Objects in a list
	aPeople = [oAnn,oBob,oEva]
	for oPerson in aPeople
		? oPerson.name + " " + oPerson.age
	next

class Person

	name = ""
	age = 0
	city = "Cairo"

	# init runs when the object is made with new Person(...). Give a class an init (even an empty one) if you write new Person()
	# with parentheses, and end it with "return self" if the object is used with braces: new Person(...) { ... }
	func init cName, nAge
		name = cName
		age = nAge
		return self

	func birthday
		age++

	func describe
		return name + " is " + age + " and lives in " + city

	func isAdult
		return age >= 18

class Student from Person

	subject = ""

	func init cName, nAge, cSubject
		super.init(cName,nAge)           # the init of the parent
		subject = cSubject
		return self

	func describe
		return super.describe() + ", studies " + subject
