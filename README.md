Generys, wanna-be web framework for Io
======================================

What's the point?
-----------------
Mostly it was a personal goal to learn a bit more about this amazing language called Io. 
Another goal was to create a simple web framework which could
reliably serve lots of **data** -- no Views, templates, etc. -- all that can be done within browser,
why should I waste my money on expensive servers?

How to use
----------
Explore. :)

Place all your controllers into app/controllers/ and make sure you assign to
a variable whose name ends with "Controller", like `CarsController := Controller clone do(...)`

Model?
------
The "framework" is DB-agnostic, yet it contains a small CouchDB library, which is
far from complete. IORM seems like a good choice.

View
----
SelectorDecomposer comes to the rescue! SelectorDecomposer provides jQuery-like mechanism
for querying and modifying SGMLElements.
Take a look at samples/Chat/app/Controllers/ExceptionController.io on how to use it.

How to run
----------
You can `cd` to directory where your application is placed and run `io`.
You can also, run `generys -r=/path/to/project`, assuming you've installed generys "binary".

Io additions
------------
To work more easily with Io, Generys has few tricks:
### First of all, you can use JSON syntax for Maps!
Yes, this is a valid Io code:  
`{colour: "Red", favourite: false, numbers:[1, 2, 3]}`  

### To access an item from Map or List you can use square brackets:  
`anMap["colour"] == anMap at("colour")`  
`anMap["colour", "favourite"] == anMap select(key, value, key == "colour" or key == "favourite")`
  
`anList[0] == anList at(0)`  
`anList[1,-1] == anList exSlice(1, -1)`  
  
`"string"[0] == 115`  
`"string"[0, 1] == "string" exSlice(0, 1)`  

Code conventions
----------------
Just to make it more fun, all closing brackets are in the same line:  
`lispy := method(`  
`  self isThisLispInspired ifTrue(`  
`  Yes, it is!" println))`  
  
With one exception:
`Object clone do(`  
`  ...`  
`)`  

"Class" variables have are addressed with `self` before, just to differentiate them from "instance" variables.
`Car := Object clone do(`  
`  a := 4`  
`  b := 5`  
  
`  switchPlaces := method(`  
`    c := self a`  
`    self a = self b`  
`    self b = c`  
`    self)`  
)`
