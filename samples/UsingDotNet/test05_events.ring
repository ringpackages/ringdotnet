load "../../libraries/dotnetlib/dotnetlib.ring"
dnImport("System.Collections.ObjectModel")

# .NET events: setXXXEvent(cRingCode) like RingQt, the code reads aDotNetArgs = [sender, eventArgs]
oList = new ObservableStringList()
nChanges = 0
oList.setCollectionChangedEvent("nChanges++ ? '  CollectionChanged event #' + nChanges")

oList.Add("one")
oList.Add("two")
oList.RemoveAt(0)
? "Events received : " + nChanges
? "Items           : " + oList.getCount()

# One handler per event: setting it again replaces it, clear removes it
oList.setCollectionChangedEvent("? '  (second handler)'")
oList.Add("three")
oList.clearCollectionChangedEvent()
oList.Add("four")
? "Items           : " + oList.getCount()

# The event arguments are .NET objects
oList.setCollectionChangedEvent("? '  action = ' + aDotNetArgs[2].getProp('Action')")
oList.Add("five")
