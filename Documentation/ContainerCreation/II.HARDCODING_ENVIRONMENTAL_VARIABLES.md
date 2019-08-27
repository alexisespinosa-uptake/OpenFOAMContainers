# II. Hardcoding environmental variables to run OpenFOAM container at Pawsey with shifter

We have not found a way of robust way of sourcing the configuration files at the startup of the container that would work on shifter when running MPI applications. These configuration files define the needed environmental variables for the usage of openfoam, but without an automatic sourcing at startup, those variables will not be set and solvers would not be able to run properly.

Then, the only robust way we have found for things to work is to define all the environmental variables within the Dockerfile using the ENV command. That is, instead of sourcing the configuration files, all the relevant environmental variables will be set explicitly when building the container, then avoiding the need of further sourcing of any configuration file.

Unfortunately, each version of openfoam may have a different set-up for these environmental variables, making it a harder task to define the environmental variables with an ideal "clean" definition.Then, we opted to follow this series of steps that have proven to be simple and effective to "hardcode" these variables for each specific version of openfoam from the very creation of the image.

In order to create the full list of environmental variables to define, follow these steps:

## 0. Create a container without any explicit definition of ENV variables

Create a container with the installation of openfoam, but without definition of any ENV variable. This container should be capable of running openfoam properly in an interactive docker session (in your own desktop) after sourcing the configuration files as explained below. Then, if openfoam is working properly, we will print the environmental variables into a file, order it, clean it, and then copy and paste the final list into the Dockerfile, as explained in the final steps. This will setup the container to be able to run openfoam without the need of sourcing the
configuration files, and then allowing shifter to use properly the solvers in parallel mpi jobs.

The specific steps to follow in this stage are:

- 0.0 Comment or remove all the ENV lines immediately after the  the " i. Copy&Paste" indication within the Dockerfile.

- 0.1 Define some useful variables for the naming of the container:
```shell
localShell:$ theRepo=alexisespinosa
localShell:$ theContainer=openfoam
localShell:$ theTag=4.0
```
(This example considers my docker repository is "alexisespinosa", the image name is "openfoam" and the tag is "4.0") ("localShell:$" is the prompt, it is not part of the command)

- 0.2 Build the image:

```shell
localShell:$ docker build -t $theRepo/$theContainer:$theTag .
```

## 1. Print out a list of the environmental variables

- 1.1: Run an interactive session. For this, mount your current directory "$PWD" as "/localDir", and use your local "user:group" IDs in order to have writing permission to the local directory from inside the container:

```shell
localShell:$ docker run -it --rm -v $PWD:/localDir --user $(id -u):$(id -g) $theRepo/$theContainer:$theTag
I have no name!:$
```

(Your prompt will now change to "I have no name" inside the container, but that is fine as we have forced to use the local user:group in order to have writing permission)

- 1.2 Within the interactive session, source the configuration file in order to define openfoam environmental variables:

```shell
I have no name!:$ source /MySoftware/openfoam/openfoam-4.0/etc/bashrc
```

- 1.3 Find a tutorial case to test:

```shell
I have no name!:$ find $FOAM_TUTORIALS -type d -name "cavity"
```

- 1.4 Copy the tutorial case and test that openfoam is working properly:

```shell
I have no name!:$ mkdir -p /localDir/run/tutorials
I have no name!:$ cp -rp $FOAM_TUTORIALS/incompressible/icoFoam/cavity/cavity /localDir/run/tutorials/
I have no name!:$ cd /localDir/run/tutorials/cavity
I have no name!:$ blockMesh
I have no name!:$ icoFoam
```

- 1.5 If everything is working properly, then print the environment variables into a file in your local machine (remember that /localDir is a mount local working directory):

```shell
I have no name!:$ mkdir /localDir/variables
I have no name!:$ printenv > /localDir/variables/raw_vars.env
I have no name!:$ exit
```

## 2. Clean and edit the list and finally copy/paste it into the Dockerfile
Here, we are going to edit the file containing the variables and finally copy paste the list into the Dockerfile.

- 2.1 First, we are going to sort the list for makeing it easier to choose the variables we are interested on:

```shell
localShell:$ cd variables
localShell:$ sort raw_vars.env -o sorted_vars.env
```

- 2.2 Remove unnecessary variables (not related to openfoam) and save it into another file as "cleaned_vars.env":

```shell
localShell:$ cp sorted_vars.env cleaned_vars.env
localShell:$ vi cleaned_vars.env
```
Use the editor to delete all the lines not related to openfoam. The names of the variables to keep can be identified with:

```
Variables whose name is related directly to openfoam:
FOAM_*, WM_*,

Variables related to the ThirdParty tools, like:
BOOST_*, CGAL_*, FFTW_*, ParaView_*, PV_*, SCOTCH_*, BISON_*, HWLOC_*, MESQUITE_*, METIS_*, PARMETIS_*, PARMGRIDGEN_*, PYFOAM_*, 
but may be others.

Variables related to compiler, mpi and paths:
LD_LIBRARY_PATH, MPI_*, PATH,

And also check for variables whose definition contains OpenFOAM, foam, ThirdParty, etc.

```
Be careful and identify any other variable that may be related to your openfoam installation. If you miss any, you will notice it while finally using the container. Then you may need to come back to this point and keep that specific variable that may be missing.

- 2.3 Copy the list into a ready_vars.env file, where the lines to be added to the Dockerfile will be put ready to be copied/pasted.

```shell
localShell:$ cp cleaned_vars.env ready_vars.env
localShell:$ vi ready_vars.env
```

First, add double quotes for variables with spaces (for example for flags) within the list:

```
        For example, change:
WM_CXXFLAGS=-m64 -fPIC -std=c++0x

                         to:
WM_CXXFLAGS="-m64 -fPIC -std=c++0x"
```
(You can perform a search for blank spaces within the file to catch those variables).

Now add the Docker command "ENV" at the begining of all lines in the list, like:

```
.
.
.
ENV WM_CFLAGS="-m64 -fPIC"
ENV WM_COMPILER=Gcc
ENV WM_COMPILER_LIB_ARCH=64
ENV WM_COMPILER_TYPE=system
ENV WM_COMPILE_OPTION=Opt
ENV WM_CXX=g++
ENV WM_CXXFLAGS="-m64 -fPIC -std=c++0x"
ENV WM_DIR=/MySoftware/OpenFOAM/OpenFOAM-4.x/wmake
ENV WM_LABEL_OPTION=Int32
ENV WM_LABEL_SIZE=32
.
.
.
```
(column editing is very useful in this case, rather than typing ENV for each line)

## 3. Copy/paste the list into the Dockerfile
Copy the list into the right section of the Dockerfile, just below the " i. Copy&Paste" indication:

```
.
.
.
#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
## I. HARDCODING THE ENVIRONMENTAL VARIABLES TO RUN OPENFOAM.
#
# Please follow the relevant document inside ../Documentation/ContainerCreation
#----------------------------:
# i. Copy&Paste the list of environmental variables below this comment.
#and before the ii. "Fixing" comment.
#(Replace all the existing ENV settings already in this file):
#----------------------------:
ENV FOAM_APP=/MySoftware/OpenFOAM/OpenFOAM-4.x/applications
ENV FOAM_APPBIN=/MySoftware/OpenFOAM/OpenFOAM-4.x/platforms/linux64GccDPInt32Opt/bin
ENV FOAM_ETC=/MySoftware/OpenFOAM/OpenFOAM-4.x/etc
ENV FOAM_EXT_LIBBIN=/MySoftware/OpenFOAM/ThirdParty-4.x/platforms/linux64GccDPInt32/lib
ENV FOAM_INST_DIR=/MySoftware/OpenFOAM
ENV FOAM_JOB_DIR=/MySoftware/OpenFOAM/jobControl
ENV FOAM_LIBBIN=/MySoftware/OpenFOAM/OpenFOAM-4.x/platforms/linux64GccDPInt32Opt/lib
ENV FOAM_MPI=mpi-system
ENV FOAM_RUN=/home/ofuser/OpenFOAM/ofuser-4.x/run
ENV FOAM_SETTINGS=
.
.
.
```
## 4. Test if the container works with the defined variables 

- 4.1 Generate the openfoam image again as in point "0" above.

```shell
localShell:$ docker build -t $theRepo/$theContainer:$theTag .
```

- 4.2 Test that openfoam works WITHOUT SOURCING ANY CONFIGURATION FILE:

```shell
localShell:$ docker run -it --rm -v $PWD:/localDir --user $(id -u):$(id -g) $theRepo/$theContainer:$theTag
I have no name!:$ cd /localDir/run/tutorials/cavity
I have no name!:$ rm -rf 0.*
I have no name!:$ blockMesh
I have no name!:$ icoFoam
I have no name!:$ exit
```
Everything should have ran correctly without sourcing any configuration file.

- 4.3 Now test the container non interactively:

```shell
localShell:$ cd ./run/tutorials/cavity
localShell:$ rm -rf 0.*
localShell:$ docker run --rm -v $PWD:/cavity -w /cavity --user $(id -u):$(id -g) $theRepo/$theContainer:$theTag blockMesh
localShell:$ docker run --rm -v $PWD:/cavity -w /cavity --user $(id -u):$(id -g) $theRepo/$theContainer:$theTag icoFoam
localShell:$ cd ../../..
```
(Notice that now we are naming the local directory in your computer [the one with the case to be ran] as "/cavity" within the container.)
Everything should have ran correctly without sourcing any configuration file.
If so, then this container is pretty much ready for Pawsey.

## 5. Generate the final environmental variables list from Docker
This is IMPORTANT because this list NEED TO BE COMPARED to the one that shifter creates in Pawsey systems.

- 5.1 You can execute the printenv in a command line non-interactive run:

```shell
localShell:$ docker run --rm -v $PWD:/localDir --user $(id -u):$(id -g) $theRepo/$theContainer:$theTag bash -c 'printenv > /localDir/variables/raw_docker.env'
```

- 5.2 This is not strictly necessary, but you can sort and clean the list as in point "2" above and generate the sorted\_docker.env and cleaned\_docker.env files. Then compare the files in order to see if you have set everything you needed:

```shell
localShell:$ cd variables
localShell:$ sort raw_docker.env -o sorted_docker.env
localShell:$ diff sorted_vars.env sorted_docker.env
```
(If you see any difference IN THE VARIABLES RELATED TO OPENFOAM, then adjust whatever is necessary in step "2" and proceed again.)
 
## 6. Upload the container image to your docker repository

- 6.1 If everything is working and lists are consistent, then push the container to the repo:

```shell
localShell:$ docker push $theRepo/$theContainer:$theTag
```

## 7. Download the container image into Pawsey

- 7.1 ssh to zeus or magnus:

```shell
localShell:$ ssh user@zeus.pawsey.org.au
```

- 7.2 Run the following commands to "pull" the image from the Docker repository:

```shell
user@zeus-1:~> theRepo=alexisespinosa
user@zeus-1:~> theContainer=openfoam
user@zeus-1:~> theTag=4.0
user@zeus-1:~> module load shifter/18.06.00
user@zeus-1:~> sg $PAWSEY_PROJECT -c "shifter pull $theRepo/$theContainer:$theTag"
```
(For more info on how to pull images into our systems read the Pawsey Documentation.)

## 8. Execute a basic test (display the help message of icoFoam):
```shell
user@zeus-1:~> shifter run $theRepo/$theContainer:$theTag icoFoam -help
```
(Note that shifter will not mount the /tmp directory of the container, so you may see a warning message about it, but that is fine.)
You should have seen the help message correctly without errors. If errors occurred, it is possible that some environmental variables went missing. But even if this has worked, it is important that you go through the following steps to catch possible problems and finalise the creation of the container.

## 9. VERY IMPORTANT: Confirm that variables are preserved by shifter
For some weird reason, shifter may forget/loose some variables when running the image. If that happens, your solver may fail. (More info is in the helpdesk ticket: GS-10054). In order to workaround this bug, these variables need to be defined in different order within the initial Dockerfile and hope for shifter to be able to preserve them. So far, this has worked with all the containers we have created:

- 9.1 Print the environmental variables that shifter recognises in the container:

```shifter
user@zeus-1:~> shifter run $theRepo/$theContainer:$theTag printenv > raw_shifter.env
```
- 9.2 Now copy the file into your local system

```shell
localShell:$ cd variables
localShell:$ scp user@hpc-data.pawsey.org.au:raw_shifter.env .
```
And sort the file and clean it ( as in section "2") in order to check the differences and identify the missing variables. Cleaning might be a bit more tedious, as the shifter list will contain a huge list of variables related to Pawsey systems. But, as indicated in section "2" the cleaned file should contain only the list of variables relevant to openfoam.

- 9.3 Compare the two cleaned list of variables (then check the differences):

```shell
localShell:$ diff cleaned_vars.env cleaned_shifter.env
```
(If shifter was tested in zeus, you will find that BOOST_ROOT variable is different. This will not cause any problem. Openfoam will use the boost installation in zeus then.)
	
* Two things to check:
	1.  The PATH variable will be different, but this should not be a problem. Just check that all the path definitions for the cleaned\_vars.env also exist within the path definition observed for the cleaned\_shifter.env file.
	2. All the variables (like FOAM\_\*, WM\_\*, etc.) within the "cleaned\_vars.env" list SHOULD also exist within the "cleaned\_shifter.env" file and be identical. (Unfortunately, IT IS VERY POSSIBLE THAT SOME VARIABLES ARE INITIALLY LOST BY SHIFTER.)

- 9.4 If variables are preserved, the container is ready to be tested with tutorials and production runs. If not, you will need to go to the next step to correct the Dockerfile and then back to the creation of the corrected container.

## 10. If differences between the cleaned list appear, then fix them and test again:
If variables were lost after the check in previous step, then we need to correct the problem. For that:

- 10.1 Comment the initial definition of the lost variables within the original list created inside the Dockerfile. (If you read another existing working Dockerfile, you may read examples of those variables commented with the tag "#WillBeDefinedAtTheEndDueToShifterFailure".)
- 10.2 Now, define them as the last variables to be defined within the Dockerfile. Basically, cut the original lines and paste them below the section "ii. Fixing shifter bug.." like:

```
.
.
.
#----------------------------:
#ii. Fixing shifter bug with environment variables.
#If loss of variables environment variables occurred to you,
#Comment the problematic variables in the list above and mark them with some tag like #WillBeDefinedAtTheEndDueToShifterFailure
#and define them at the end of the list (immediately below this comment)
#----------------------------:
ENV FOAM_APPBIN=/MySoftware/OpenFOAM/OpenFOAM-4.0/applications/bin/linux64GccDPOpt
ENV FOAM_LIBBIN=/MySoftware/OpenFOAM/OpenFOAM-4.0/lib/linux64GccDPOpt
ENV WM_COMPILER_ARCH=
ENV WM_CXXFLAGS="-m64 -fPIC -std=c++0x"
ENV WM_PROJECT_DIR=/MySoftware/OpenFOAM/OpenFOAM-4.0
.
.
.
```

- 10.3 Repeat the whole process from the step "4. Test if the container works with the defined variables", until you succeed without losing any variable after the check in step "9".

---
Back to the [README](../../README.md)