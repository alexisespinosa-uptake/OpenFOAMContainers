# Using virtual file system OverlaFS

We recommend the use of virtual file systems to avoid the generation of a large number of result files. This my only be needed for old versions of OpenFOAM (older than OpenFOAM-6 and OpenFOAM-1712) as the "collated" option for result files was not fully functional, or not existent at all.

## 1. Preparation

Once in a session on Zeus or Magnus, load the singularity module:

```shell
user@zeus-1:~> module load singularity
```

Now, check the content in the directory to be used as a repository for the Singularity containers. The repository may be the one maintained by Pawsey:

```shell
user@zeus-1:~> theRepo=/group/singularity/pawseyRepository/OpenFOAM
user@zeus-1:~> ls $theRepo
openfoam-5.x-pawsey.sif  openfoam-7-pawsey.sif  openfoam-v1912-pawsey.sif
```

Or a project repository shared with the other members of your project:

```
user@zeus-1:~> theRepo=$MYGROUP/../singularity/groupRepository/OpenFOAM
user@zeus-1:~> ls $theRepo
openfoam-v1812-mickey.sif
```

Or your personal repository:

```
user@zeus-1:~> theRepo=$MYGROUP/singularity/myRepository/OpenFOAM
user@zeus-1:~> ls $theRepo
openfoam-7-mickey.sif
```

In the rest of this example, we'll use the openfoam-7-pawsey.sif within the pawseyRepository.

We recommend to use the following approach (or similar) to define the name of the container-image to use (specially if you are using or testing more than one container for your specific problem):

```
user@zeus-1:~> theRepo=/group/singularity/pawseyRepository/OpenFOAM
user@zeus-1:~> theContainerBaseName=openfoam
user@zeus-1:~> theVersion=7
user@zeus-1:~> theProvider=pawsey
user@zeus-1:~> theImage=$theRepo/$theContainerBaseName-$theVersion-$theProvider.sif
```

Execute a very basic test to see if the container is responding correctly (you should see a message similar to this):

```shell
user@zeus-1:~> singularity exec $theImage icoFoam -help

Usage: icoFoam [OPTIONS]
options:
  -case <dir>       specify alternate case directory, default is the cwd
  -fileHandler <handler>
                    override the fileHandler
  -hostRoots <(((host1 dir1) .. (hostN dirN))>
                    slave root directories (per host) for distributed running
  -libs <(lib1 .. libN)>
                    pre-load libraries
  -listFunctionObjects
                    List functionObjects
  -listRegisteredSwitches
                    List switches registered for run-time modification
  -listScalarBCs    List scalar field boundary conditions (fvPatchField<scalar>)
  -listSwitches     List switches declared in libraries but not set in
                    etc/controlDict
  -listUnsetSwitches
                    List switches declared in libraries but not set in
                    etc/controlDict
  -listVectorBCs    List vector field boundary conditions (fvPatchField<vector>)
  -noFunctionObjects
                    do not execute functionObjects
  -parallel         run in parallel
  -roots <(dir1 .. dirN)>
                    slave root directories for distributed running
  -srcDoc           display source code in browser
  -doc              display application documentation in browser
  -help             print the usage

Using: OpenFOAM-7 (see https://openfoam.org)
Build: 7-e84d903cab0c
```

## 1. Define the case to solve

Users that count already with a case to solve can skip this section and move to the next one (Best Practises). But if the user wants to perform a test from the tutorials provided by OpenFOAM itself, they can follow the instructions in this section.

Here, we plan to use the "damBreak" tutorial. Users can do this in an interactive session of the container, but here we explain how to do it non-interacively. That is, the container executes what is indicated in each line of the supercomputer command prompt, but will exit and come back to the supercomputer prompt immediately.

Check the definition of some of the OpenFOAM evironment variables inside the container:

```shell
user@zeus-1:~> singularity exec $theImage bash -c 'echo $WM_PROJECT_DIR'
/opt/OpenFOAM/OpenFOAM-7
user@zeus-1:~> singularity exec $theImage bash -c 'echo $FOAM_ETC'
/opt/OpenFOAM/OpenFOAM-7/etc
user@zeus-1:~> singularity exec $theImage bash -c 'echo $FOAM_TUTORIALS'
/opt/OpenFOAM/OpenFOAM-7/tutorials
```
* **bash -c 'command'** is to execute what is in between the apostrophes while using the value of $FOAM_TUTORIALS etc. inside the container (otherwise it will try to use the value of the variable in the supercomputer shell, which is not what we want).

Find the family of tutorial cases for "damBreak":

```shell
user@zeus-1:~> singularity exec $theImage bash -c 'find $FOAM_TUTORIALS -type d -name "damBreak"'
/opt/OpenFOAM/OpenFOAM-7/tutorials/multiphase/interFoam/RAS/damBreak
/opt/OpenFOAM/OpenFOAM-7/tutorials/multiphase/interFoam/RAS/damBreak/damBreak
/opt/OpenFOAM/OpenFOAM-7/tutorials/multiphase/interFoam/laminar/damBreak
/opt/OpenFOAM/OpenFOAM-7/tutorials/multiphase/interFoam/laminar/damBreak/damBreak
/opt/OpenFOAM/OpenFOAM-7/tutorials/multiphase/interMixingFoam/laminar/damBreak
```
 
Copy the desired case to /scratch:

```shell
user@zeus-1:~> cd $MYSCRATCH
user@zeus-1:~> mkdir -p ./OpenFOAM/$USER-$theVersion/run/tutorials
user@zeus-1:~> cd ./OpenFOAM/$USER-$theVersion/run/tutorials
user@zeus-1:~> singularity exec $theImage bash -c 'cp -r $FOAM_TUTORIALS/multiphase/interFoam/RAS/damBreak/damBreak .'
```
* Note that: /group and /scratch are mounted by default for singularity containers at Pawsey and containers are able to read/write on them. Also, by default, Singularity mounts the directory from where it is called.

Quick check of the content:

```shell
user@zeus-1:~> ls damBreak
0  Allclean  Allrun  constant  system
```

### (1.1 For the tutorial example, Increase the number of domains (processors) in the decomposition)
As we are demonstrating how to run a case in Pawsey supercomputers, we'll modify the numberOfSubdomains of the original tutorial case and use a larger number number. Edit the ./system/decomposeParDict file and define the use of 48 cores:

```c++
//numberOfSubdomains 4;
numberOfSubdomains 48;

method          simple;

simpleCoeffs
{
//    n               (2 2 1);
    n               (6 8 1);
        delta           0.001;
}
```


## 2. Adapt the case to use Best Practices
All the cases to be ran at Pawsey supercomputers need to comply with the Best Practises guidelines. These guidelines are defined to avoid the problems of contention in Pawsey's shared file system.

For that, "cd" to the case directory

```shell
user@zeus-1:~> cd $MYSCRATCH/OpenFOAM/$USER-$theVersion/run/tutorials/damBreak
```
and edit your configuration dictionaries to comply with Pawsey Best Practices.

### 2.1 Output binary result files
Users should set the result files to be written in binary format. You can make some exceptions during the test and development phase of your project, but production runs should produce binary result files.

Edit the "system/controlDict" dictionary file and comment/remove the writeFormat ascii setting and to set the binary output:

```c++
//writeFormat     ascii;
writeFormat     binary;
```

### 2.2 If possible, set "purgeWrite" to a low number
This parameter defines the total number of time snapshots of results to be saved. Therefore, if this parameter is set to 10, then only the last 10 time directories will be kept. Obviously, this is only useful whenever the results of the beginning of the simulation are not of interest to the user.

Edit the "system/controlDict" dictionary file and comment/remove the purgeWrite setting and to set it to "10":

```c++
//purgeWrite      0;
purgeWrite      10;
```

### 2.3 Never use "runTimeModifiable"
Users should not use the runTimeModifiable mode of OpenFOAM. This option may produce a large number of reads to the shared file system, which can produce contention and reduction of performance.

Edit the "system/controlDict" dictionary file and comment/remove the runTimeModifiable setting and to set it to "no":

```c++
//runTimeModifiable yes;
runTimeModifiable no;
```

### 2.4 Use -fileHandler collated -ioRanks '(0 G 2G ... mG)' to reduce the number of result directories and files

New versions of OpenFOAM (since OpenFOAM-6 and OpenFOAM-v1806) provide the "-fileHandler collated -ioRanks '(0 G 2G ... mG)'" combined option. This combined option allows for a huge reduction in the number of result directories and files generated (see explanation above). Therefore, if you are using a recent version of OpenFOAM, you should make use of it.

For recent OpenFOAM versions, containers maintained by Pawsey have already defined the first part of the combined option as default: "-fileHandler collated". But, if for your container it is not set by default, then it needs to be set with one of the methods described here. For example, edit the "system/controlDict" dictionary file and add:

```c++
OptimisationSwitches
{
    fileHandler collated;
}
```

##### ioRanks should be defined at execution time

Unfortunately, the second part of the combined option ("-ioRanks '(0 G 2G ... mG)'") cannot be defined in the system/controlDict.

Therefore, users must define ioRanks at execution time following one the methods explained in this documentation (see explanation here). It's usage will be exemplified in the following section.

Remember to always define the second part of the combined option when a large number of processors (numberOfSubdomains) are to be used. Just defining the basic first part (-fileHandler collated) and not the second part may reduce performance, as all the results will be collated through a single processor for the whole parallel simulation.


## 3. Execute OpenFOAM tools and solvers within a container

### 3.1 Serial preprocessing
Most of OpenFOAM pre-processing tools are serial. Here we execute several pre-processing tools as serial substeps defined in a job script. Use the following script (preFOAM.sh) as an example for executing the serial pre-processing tools in Zeus using a container: 

~~~shell
#!/bin/bash -l 
#SBATCH --export=NONE
#SBATCH --time=00:15:00
#SBATCH --ntasks=1
#SBATCH --partition=workq
#SBATCH --clusters=zeus

#----------
# Load the necessary modules
module load singularity

#----------
# Defining the container to be used
theRepo=/group/singularity/pawseyRepository/OpenFOAM
theContainerBaseName=openfoam
theVersion=7
theProvider=pawsey
theImage=$theRepo/$theContainerBaseName-$theVersion-$theProvider.sif

#----------
# Defining the case directory
myCase=$MYSCRATCH/OpenFOAM/$USER-$theVersion/run/tutorials/damBreak

#----------
# Defining the ioRanks for collating I/O
# groups of 24 as the intended parallel run will be executed in Magnus:
export FOAM_IORANKS='(0 24 48 72 96 120 144 168 192 216 240 264 288 312 336 360 384 408 432 456 480 504 528 552 576 600 624 648 672 696 720 744 768 792 816 840 864 888 912 936 960 984 1008 1032 1056 1080 1104 1128 1152 1176 1200)'

#----------
# Execute the pre-processing tools
echo "0: cd into the case directory"
cd $myCase
echo "I am in dir: $PWD"

echo "1: Creating the mesh:"
srun --export=all -n 1 -N 1 singularity exec $theImage blockMesh 2>&1 | tee log.blockMesh.$SLURM_JOBID

echo "2: Initialising fields:"
srun --export=all -n 1 -N 1 singularity exec $theImage setFields 2>&1 | tee log.setFields.$SLURM_JOBID

echo "3: Decomposing the case (ioRanks list will be picked up from FOAM_IORANKS environment variable):"
 #A: When collated option is set by default or within system/controlDict:
srun --export=all -n 1 -N 1 singularity exec $theImage decomposePar 2>&1 | tee log.decomposePar.$SLURM_JOBID
 #B: When collated option needs to be set explictly in the command line:
 ##srun --export=all -n 1 -N 1 singularity exec $theImage decomposePar -fileHandler collated 2>&1 | tee log.decomposePar.$SLURM_JOBID
~~~

* The script is forced to run in **zeus** because serial pre- and post-processing of OpenFOAM cases should be executed in this cluster: **--clusters=zeus**
* Singularity module needs to be loaded: **module load singularity**
* The collated/ioRanks combined option needs to be set for the decomposePar ​to properly decompose the domain.
* It is practical to keep a large list for the ioRanks. Those numbers larger than the real number of processors (numberOfSubdomains) are ignored.


And then, submit the job:

```shell
user@zeus-1:~> sbatch preFOAM.sh
```

The case directory will be now prepared for executing the parallel solver. Notice that decomposed initial conditions are in the processors4_0-3 directory:

```shell
user@zeus-1:~> ls $MYSCRATCH/OpenFOAM/$USER-7/run/tutorials/damBreak
0  Allclean  Allrun  constant  processors48_0-23 processors48_24-47 system
log.blockMesh.34333 log.setFields.34333 log.decomposePar.34333
user@zeus-1:~> ls $MYSCRATCH/OpenFOAM/$USER-7/run/tutorials/damBreak/processors48_0-23/
0  constant
```

You should always check your slurm-jobID.out file created in the submission directory for confirming a correct execution or for identifying errors. With the "2>&1 | tee" combination of commands, we are also creating the files log.tool.jobID in the case directory with the same purposes.

### 3.2 Executing the parallel solver (in hybrid mode to make use of Supercomputer's MPICH)
As mentioned previously, the OpenFOAM containers (and any MPI application) should be executed with the "hybrid mode" of singularity. This mode makes use of the Supercomputer's MPICH installation binded to the MPICH installation inside the container. In Pawsey Supercomputers, binding is performed automatically when the singularity module is loaded.

Use the following script (runFOAM.sh) as an example for executing the parallel solver:

~~~shell
#!/bin/bash -l 
#SBATCH --export=NONE
#SBATCH --time=00:15:00
#SBATCH --ntasks=48
#SBATCH --partition=workq
#SBATCH --clusters=magnus

#----------
# Load the necessary modules
module load singularity

#----------
# Defining the container to be used
theRepo=/group/singularity/pawseyRepository/OpenFOAM
theContainerBaseName=openfoam
theVersion=7
theProvider=pawsey
theImage=$theRepo/$theContainerBaseName-$theVersion-$theProvider.sif

#----------
# Defining the case directory
myCase=$MYSCRATCH/OpenFOAM/$USER-$theVersion/run/tutorials/damBreak

#----------
# Defining the solver
of_solver=interFoam

#----------
# Defining the ioRanks for collating I/O
# groups of 24 as the intended parallel run will be executed in Magnus:
export FOAM_IORANKS='(0 24 48 72 96 120 144 168 192 216 240 264 288 312 336 360 384 408 432 456 480 504 528 552 576 600 624 648 672 696 720 744 768 792 816 840 864 888 912 936 960 984 1008 1032 1056 1080 1104 1128 1152 1176 1200)'

#----------
# Execute the parallel solver
echo "4: cd into the case directory"
cd $myCase
echo "I am in dir: $PWD"

echo "5: Executing the case in parallel in hybrid-mode (ioRanks list will be picked up from FOAM_IORANKS environment variable):"
#A: When collated option is set by default or within system/controlDict:
srun --export=all -n $SLURM_NTASKS -N $SLURM_JOB_NUM_NODES singularity exec $theImage $of_solver -parallel 2>&1 | tee log.$of_solver.$SLURM_JOBID
#B: When collated option needs to be set explictly in the command line:
#srun --export=all -n $SLURM_NTASKS -N $SLURM_JOB_NUM_NODES singularity exec $theImage $of_solver -parallel -fileHandler collated 2>&1 | tee log.$of_solver.$SLURM_JOBID
~~~

And then, submit the job

```shell
user@zeus-1:~> sbatch runFOAM.sh
```

The results are in the processors48_0-23, processors48_24-47 directories:

```shell
user@zeus-1:~> ls $MYSCRATCH/OpenFOAM/$USER-7/run/tutorials/damBreak/processors48_0-23/
0  0.55  0.6  0.65  0.7  0.75  0.8  0.85  0.9  0.95  1  constant
```

You should always check your slurm-jobID.out file created in the submission directory for confirming a correct execution or for identifying errors. With the "2>&1 | tee" combination of commands, we are also creating the files log.tool.jobID in the case directory with the same purposes.

### 3.3 Postprocessing
The reconstruction of the case is again a serial task. For this, you can use the following script (postFOAM.sh) as an example for executing the serial post-processing tools in Zeus using a container:

```shell
#!/bin/bash -l
#SBATCH --export=NONE
#SBATCH --time=00:15:00
#SBATCH --ntasks=1
#SBATCH --partition=workq
#SBATCH --clusters=zeus

#----------
# Load the necessary modules
module load singularity

#----------
# Defining the container to be used
theRepo=/group/singularity/pawseyRepository/OpenFOAM
theContainerBaseName=openfoam
theVersion=7
theProvider=pawsey
theImage=$theRepo/$theContainerBaseName-$theVersion-$theProvider.sif

#----------
# Defining the case directory
myCase=$MYSCRATCH/OpenFOAM/$USER-$theVersion/run/tutorials/damBreak

#----------
# Defining the ioRanks for collating I/O
# groups of 24 as the intended parallel run will be executed in Magnus:
export FOAM_IORANKS='(0 24 48 72 96 120 144 168 192 216 240 264 288 312 336 360 384 408 432 456 480 504 528 552 576 600 624 648 672 696 720 744 768 792 816 840 864 888 912 936 960 984 1008 1032 1056 1080 1104 1128 1152 1176 1200)'

#----------
# Execute the pre-processing tools
echo "6: cd into the case directory"
cd $myCase
echo "I am in dir: $PWD"

echo "7: Reconstructing the case (ioRanks list will be picked up from FOAM_IORANKS environment variable):"
#A: When collated option is set by default or within system/controlDict:
srun --export=all -n 1 -N 1 singularity exec $theImage reconstructPar -latestTime 2>&1 | tee log.reconstructPar.$SLURM_JOBID
#B: When collated option needs to be set explictly in the command line:
##srun --export=all -n 1 -N 1 singularity exec $theImage reconstructPar -latestTime -fileHandler collated 2>&1 | tee log.reconstructPar.$SLURM_JOBID
```

And then, submit the job

```shell
user@zeus-1:~> sbatch postFOAM.sh
```

The reconstructed directory should be available in the root of the case directory:

```shell
user@zeus-1:~> ls $MYSCRATCH/OpenFOAM/$USER-7/run/tutorials/damBreak
0  Allclean  constant  log.blockMesh.4199306     log.interFoam.4773027       log.setFields.4199306  processors48_24-47
1  Allrun    core      log.decomposePar.4199306  log.reconstructPar.4199472  processors48_0-23      system
user@zeus-1:~> ls $MYSCRATCH/OpenFOAM/$USER-7/run/tutorials/damBreak/1
alphaPhi0.water  alpha.water  epsilon  k  nut  p  phi  p_rgh  U  uniform
```

You should always check your slurm-jobID.out file created in the submission directory for confirming a correct execution or for identifying errors. With the "2>&1 | tee" combination of commands, we are also creating the files log.tool.jobID in the case directory with the same purposes.

---
Back to the [README.OpenFOAM](../../README.OpenFOAM.md)