Installing Generys
==================
 1. Make sure you checked out Generys repository to path/to/io/repo_clone/addons.
 2. Type `make addon Generys && sudo make install` in console (from path/to/io/repo_clone)
 3. `sudo cp _build/binaries/generys /usr/local/bin (or ln -s _build-binaries/generys ~/bin)`
 4. That's it!
 
Creating new Generys project
----------------------------
From terminal run:  
`generys -i=ProjectName`

And then:
`generys -r=ProjectName`
or simply:
`cd ProjectName
generys`

For list of available switches take a look into binaries/generys (within this repo, it's just an Io file)