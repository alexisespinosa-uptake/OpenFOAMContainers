## Compiling your own solver using a container

### The environmental variable **$WM_PROJECT_USER_DIR**

The variable $WM_PROJECT_USER_DIR is supposed to be pointing to the root of the path where users' applications
will reside. Usually, users also put their own code there and even posibly use it as the root of the path for their
cases to be ran. Indeed, the common setup is that FOAM_RUN=$WM_PROJECT_USER_DIR/run

The Pawsey container has already this variable pointing to a directory within the **"ofuser"** home directory.
You can check that with:
```
docker run --rm alexisespinosa/openfoam:3.0.1 bash -c 'echo $WM_PROJECT_USER_DIR'

/home/ofuser/OpenFOAM/ofuser-3.0.1
```
and
```
docker run --rm alexisespinosa/openfoam:3.0.1 bash -c 'echo $FOAM_RUN'

/home/ofuser/OpenFOAM/ofuser-3.0.1/run
```
You can also check $FOAM_USER_APPBIN and $FOAM_USER_LIBBIN.

### Mounting your a local-host directory to be understood as $WM_PROJECT_USER_DIR

What is suggested here is to mount a directory in your local host to play the role of $WM_PROJECT_USER_DIR.
Your own code will be in the local host, but the container will be able to read and write from there.
Therefore, when you compile your solver, it will be compiled within the container but the executable will be
written back to the local host.

Then, every time you need to use your own solver, you will need to mount the local host directory again.

This is very useful in a development phase of the solver. But once your solver is ready for good and will not change
at all, then you can copy it into the image and have it permanently inside it. (This will be explained later). But first
the process of mounting and compiling.

For this example, I will use the following local directory to take the place of "/home/ofuser/OpenFOAM/ofuser-3.0.1":
```
/Users/MyMac/Pawsey/OpenFOAM/espinosa-3.0.1
```

And in the tree of that directory I have my own solver directory with the right structure:
```
ls /Users/MyMac/Pawsey/OpenFOAM/espinosa-3.0.1/solvers/my_pimpleFoam
Make		SRFPimpleFoam	UEqn.H		createFields.H	pEqn.H		pimpleDyMFoam	my_pimpleFoam.C
```
And inside the Make/files:
```
my_pimpleFoam.C  
EXE = $(FOAM_USER_APPBIN)/my_pimpleFoam
```

Then, in order to compile the solver:
```
docker run --rm -v /Users/MyMac/Pawsey/OpenFOAM/espinosa-3.0.1:/home/ofuser/OpenFOAM/ofuser-3.0.1 alexisespinosa/openfoam:3.0.1 bash -c 'cd $WM_PROJECT_USER_DIR/solvers/my_pimpleFoam && wclean'
docker run --rm -v /Users/MyMac/Pawsey/OpenFOAM/espinosa-3.0.1:/home/ofuser/OpenFOAM/ofuser-3.0.1 alexisespinosa/openfoam:3.0.1 bash -c 'cd $WM_PROJECT_USER_DIR/solvers/my_pimpleFoam && wmake'
```

### The same, but in an interactive session:
It may be easier to run the container in an interactive way and do all your development and testing in a usual way.
So, in order to run interactively and being able to read and write in the correct folder of your local host:
```
docker run -it --rm -v /Users/MyMac/Pawsey/OpenFOAM/espinosa-3.0.1:/home/ofuser/OpenFOAM/ofuser-3.0.1 alexisespinosa/openfoam:3.0.1
```
Once you are in the container, you can work normally:
```
cd $WM_PROJECT_USER_DIR/solvers/my_pimpleFoam
wclean
wmake
```

