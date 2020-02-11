## Compiling your own solver using a container

### The environmental variable **$WM\_PROJECT\_USER\_DIR**

The variable **WM\_PROJECT\_USER\_DIR** should point to the path where users' applications
will reside. Usually, users also put their own code there and could also be used as a place for their
cases to be ran. Indeed, the common setup for related variables is:

```
FOAM_RUN=$WM_PROJECT_USER_DIR/run
FOAM_USER_APPBIN=$WM_PROJECT_USER_DIR/platforms/linux64GccDPInt32Opt/bin
FOAM_USER_LIBBIN=$WM_PROJECT_USER_DIR/platforms/linux64GccDPInt32Opt/lib
```

We suggest that OpenFOAM containers to be ran at Pawsey count with a user other than just "root". For example, we use the user: **"ofuser"**. And we also recommend that the environmental variable WM\_PROJECT\_USER\_DIR points somewhere into the "home" directory of that user. You can check the value to which it has been set by running in your local computer:

```
localHost> cName=alexisespinosa/openfoam:v1812
localHost> docker run --rm $cName bash -c 'echo $WM_PROJECT_USER_DIR'
/home/ofuser/OpenFOAM/ofuser-v1812
```
or

```
localHost> cName=openfoam-v1812.sif
localHost> singularity exec $cName bash -c 'echo $WM_PROJECT_USER_DIR'
/home/ofuser/OpenFOAM/ofuser-v1812
```

You can also check for the other variables: $FOAM\_RUN, $FOAM\_USER\_APPBIN and $FOAM\_USER\_LIBBIN.

### Mounting your a local-host directory to be understood as $WM_PROJECT_USER_DIR

What is suggested here is to mount a directory in your local host to play the role of $WM_PROJECT_USER_DIR.
Your own code will be in the local host, but the container will be able to read and write from there.
Therefore, when you compile your solver, it will be compiled within the container but the executable will be
written back to the local host.

Then, every time you need to use your own solver, you will need to mount the local host directory again.

This is very useful in a development phase of the solver. But once your solver is ready for good and will not change
at all, then you can copy it into the image and have it permanently inside it. (This will be explained later). But first
the process of mounting and compiling.

For this example, I will use the following local directory to take the place of "/home/ofuser/OpenFOAM/ofuser-v1812":
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

The ticket with foam-extend:

```
localHost> internalProjectUserDir=$(docker run --rm alexisespinosa/foam-extend:4.0 bash -c 'echo $WM_PROJECT_USER_DIR')
localHost> echo $internalProjectUserDir
/home/ofuser/foam/ofuser-4.0


localHost> myProjectUserDir=/home/espinosa/containers/espinosa-4.0
localHost> mkdir -p $myProjectUserDir/solvers


localHost> docker run -it --rm -u $(id -u):$(id -g) -v $myProjectUserDir:$internalProjectUserDir -w $internalProjectUserDir alexisespinosa/foam-extend:4.0
Docker> pwd
/home/ofuser/foam/ofuser-4.0
Docker> ls
solvers 


Docker> cp -r $WM_PROJECT_DIR/applications/solvers/incompressible/pimpleFoam $WM_PROJECT_USER_DIR/solvers/myPimpleFoam
Docker> cd $WM_PROJECT_USER_DIR/solvers/myPimpleFoam
Docker> rename 's,pimple,myPimple,' *
Docker> sed -i 's,pimple,myPimple,g' *
Docker> cd Make
Docker> sed -i 's,pimple,myPimple,g' *
Docker> sed -i 's/FOAM_APPBIN/FOAM_USER_APPBIN/g' files
Docker> cd ..
Docker> wclean
Docker> wmake
Docker> exit

localHost> docker run --rm -v $myProjectUserDir:$internalProjectUserDir alexisespinosa/foam-extend:4.0 myPimpleFoam -help
Usage: myPimpleFoam [-DebugSwitches key1=val1,key2=val2,...] [-DimensionedConstants key1=val1,key2=val2,...] [-InfoSwitches key1=val1,key2=val2,...] [-OptimisationSwitches key1=val1,key2=val2,...] [-Tolerances key1=val1,key2=val2,...] [-case dir] [-dumpControlSwitches] [-noFunctionObjects] [-parallel]  [-help] [-doc] [-srcDoc]


```

To run it in magnus or zeus with shifter:

```
localHost> scp -r $myProjectUserDir/applications espinosa@hpc-data.pawsey.org.au:/group/pawsey0001/espinosa/foam/espinosa-4.0
localHost> ssh espinosa@zeus.pawsey.org.au
zeus> salloc -p debugq
zeus> module load shifter
zeus> module rm xalt
zeus> myProjectUserDir=/group/pawsey0001/espinosa/foam/espinosa-4.0
zeus> internalProjectUserDir=/home/ofuser/foam/ofuser-4.0
zeus> shifter run --mount=type=bind,source=$myProjectUserDir,destination=$internalProjectUserDir alexisespinosa/foam-extend:4.0 myPimpleFoam -help
Usage: myPimpleFoam [-DebugSwitches key1=val1,key2=val2,...] [-DimensionedConstants key1=val1,key2=val2,...] [-InfoSwitches key1=val1,key2=val2,...] [-OptimisationSwitches key1=val1,key2=val2,...] [-Tolerances key1=val1,key2=val2,...] [-case dir] [-dumpControlSwitches] [-noFunctionObjects] [-parallel]  [-help] [-doc] [-srcDoc]

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

