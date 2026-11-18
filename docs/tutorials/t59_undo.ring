# Tutorial 59: stacks and queues - undo/redo with two stacks, and a first-come-first-served job queue
load "dotnet.ring"
using {
	"System.Collections.Generic"
}

func main
	# A STACK: last in, first out (a pile of plates). A QUEUE: first in, first out (people waiting in a line).

	# 1. Stack basics
	oStack = new StringStack()
	oStack.Push("a")
	oStack.Push("b")
	oStack.Push("c")
	? "1. Peek (look at the top): " + oStack.Peek() + ", Pop (take it): " + oStack.Pop() + ", now " + oStack.Count + " items, the top is " + oStack.Peek()

	# 2. Undo and redo with two stacks: every change pushes the old text on the undo stack; Undo moves a text to the redo stack
	oEditor = new TextHistory()
	oEditor.type("Hello")
	oEditor.type("Hello Ring")
	oEditor.type("Hello Ring and .NET")
	? nl + "2. text: " + oEditor.text()
	oEditor.undo()
	? "   undo : " + oEditor.text()
	oEditor.undo()
	? "   undo : " + oEditor.text()
	oEditor.redo()
	? "   redo : " + oEditor.text()
	oEditor.type("Hello again")
	? "   a new change: " + oEditor.text() + "  (can redo now? " + yesNo(oEditor.canRedo()) + ")"

	# 3. A queue
	oQueue = new StringQueue()
	oQueue.Enqueue("print report")
	oQueue.Enqueue("send email")
	oQueue.Enqueue("backup files")
	? nl + "3. jobs waiting: " + oQueue.Count
	while oQueue.Count > 0
		? "   doing: " + oQueue.Dequeue()
	end

	# 4. Where stacks and queues are used: the Back button of a browser (stack), a printer (queue), a to-do order, a call stack
	? nl + "4. The queue is empty now. Look at Count first, because Dequeue on an empty queue raises an error:"
	try
		oQueue.Dequeue()
	catch
		? "   Dequeue on an empty queue raised an error: " + left(cCatchError,45)
	done

func yesNo lValue
	if lValue
		return "yes"
	ok
	return "no"

# a text with undo and redo: two stacks of earlier texts
class TextHistory

	cCurrent = ""
	oUndo = ""
	oRedo = ""

	func init
		oUndo = new StringStack()
		oRedo = new StringStack()
		return self

	func type cNewText
		oUndo.Push(cCurrent)
		cCurrent = cNewText
		oRedo.Clear()                     # a new change makes the old future impossible

	func undo
		if oUndo.Count = 0
			return
		ok
		oRedo.Push(cCurrent)
		cCurrent = oUndo.Pop()

	func redo
		if oRedo.Count = 0
			return
		ok
		oUndo.Push(cCurrent)
		cCurrent = oRedo.Pop()

	func canRedo
		return oRedo.Count > 0

	func text
		return cCurrent
