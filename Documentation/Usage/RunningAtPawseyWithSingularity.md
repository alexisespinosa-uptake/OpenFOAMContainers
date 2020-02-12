# Running OpenFOAM containers at Pawsey Supercomputers using Singularity

## 0. Preparation

ssh to zeus or magnus:

```shell
localShell:$ ssh user@zeus.pawsey.org.au
```

Check the content in the folder you are using as repository for the singularity containers (in this case, your personal repository, but could be your project repository instead):

```shell
user@zeus-1:~> theRepo=$MYGROUP/singularity/myRepository/OpenFOAM
user@zeus-1:~> ls $theRepo
ls
openfoam-5.x_CFDEM-pawsey.sif  openfoam-7-mickey.sif  openfoam-v1912-pawsey.sif
openfoam-5.x-pawsey.sif        openfoam-7-pawsey.sif
```

Load the singularity module:

```shell
user@zeus-1:~> module load singularity
```


Define the image name (here we use several variables as pieces to build the name):

```shell
user@zeus-1:~> theType=openfoam
user@zeus-1:~> theVersion=7
user@zeus-1:~> theProvider=mickey
user@zeus-1:~> theImage=$theRepo/$theType-$theVersion-$theProvider.sif
```


## 1. The case to solve

User that count already with a case to solve can skip this section and move to the next one (execution). But if the user wants to perform a test from the tutorials provided by OpenFOAM, they can follow the instructions in this section.

First, find the tutorial to use. Users can do this in an interactive session of the container, but here we explain how to do it non-interacively. That is, the container executes what is indicated, but all the commands are executed from the host prompt:

```shell
user@zeus-1:~> singularity exec $theImage bash -c 'find $FOAM_TUTORIALS -type d -name "damBreak"'
/opt/OpenFOAM/OpenFOAM-7/tutorials/multiphase/interFoam/RAS/damBreak
/opt/OpenFOAM/OpenFOAM-7/tutorials/multiphase/interFoam/RAS/damBreak/damBreak
/opt/OpenFOAM/OpenFOAM-7/tutorials/multiphase/interFoam/laminar/damBreak
/opt/OpenFOAM/OpenFOAM-7/tutorials/multiphase/interFoam/laminar/damBreak/damBreak
/opt/OpenFOAM/OpenFOAM-7/tutorials/multiphase/interMixingFoam/laminar/damBreak
```
* **bash -c 'command'** is to execute the command recognising $FOAM_TUTORIALS inside the container
 
Copy the case you found above to the local host file system:

```shell
user@zeus-1:~> cd $MYSCRATCH
user@zeus-1:~> mkdir -p ./OpenFOAM/$USER-$theVersion/run/tutorials
user@zeus-1:~> cd ./OpenFOAM/$USER-$theVersion/run/tutorials
user@zeus-1:~> singularity exec $theImage bash -c 'cp -r $FOAM_TUTORIALS/multiphase/interFoam/RAS/damBreak/damBreak .'
```
* Note that: The submission directory is mounted by default for the container and then the container is able to write on it. Then, the cp command can copy the tutorial case into the desired directory.

## 2. Execute OpenFOAM pre- and post-processing tools and the parallel solver
Move to the case directory

```shell
user@zeus-1:~> cd $MYSCRATCH/OpenFOAM/$USER-$theVersion/run/tutorials/damBreak
```

### 2.1 Creating the mesh and decomposing (preprocessing)
Create the following script (preFOAM.sh) inside the case directory 

~~~shell
#!/bin/bash -l 
#SBATCH --export=NONE
#SBATCH --time=00:15:00
#SBATCH --ntasks=1
#SBATCH --partition=debugq
#SBATCH --clusters=zeus

#----------
# Load the necessary modules
module load singularity

#----------
#Setting some preliminary environmental variables
theRepo=$MYGROUP/singularity/myRepository/OpenFOAM
theType=openfoam
theVersion=7
theProvider=mickey
theImage=$theRepo/$theType-$theVersion-$theProvider.sif

#----------
# Execute the preprocessing tools
echo "I am in dir: $PWD"
echo "1: Creating the mesh:"
srun --export=all -n 1 -N 1 singularity exec $theImage blockMesh
echo "2: Initialising fields:"
srun --export=all -n 1 -N 1 singularity exec $theImage setFields
echo "3: Decomposing the case:"
srun --export=all -n 1 -N 1 singularity exec $theImage decomposePar
~~~
* The script is forced to run in **zeus** because, ideally, pre- and post-processing of OpenFOAM cases should be executed in this cluster: **--clusters=zeus**
* Singularity module needs to be loaded: **module load singularity**
* The **--export=NONE**, **--export=all** sequence: The first one guarantees a clean environment for the script, the second one guarantees that all the settings within the script (environmental variables set here and within the modules) will be recognised inside the job steps called by srun.
* All these tools are being executed in a single core, because these OpenFOAM tools are serial. But the solver needs to be executed in hibrid-mode of Singularity with the host MPICH. Read some paragraphs below.


And submit the job:

```shell
user@zeus-1:~> sbatch preFoam.slm
```

### 2.2 Executing the solver
Create the following script (runFOAM.sh) inside the case directory:

~~~shell
#!/bin/bash -l 
#SBATCH --export=NONE
#SBATCH --time=00:15:00
#SBATCH --ntasks=4
#SBATCH --partition=debugq

#----------
# Load the necessary modules
module load singularity

#----------
#Setting some preliminary environmental variables
theRepo=$MYGROUP/singularity/myRepository/OpenFOAM
theType=openfoam
theVersion=7
theProvider=mickey
theImage=$theRepo/$theType-$theVersion-$theProvider.sif

#----------
# Execute the solver
echo "I am in dir: $PWD"
echo "4: Executing the case in parallel"
srun --export=all -n $SLURM_NTASKS -N $SLURM_JOB_NUM_NODES singularity exec $theImage interFoam -parallel
~~~

And submit the job

```shell
user@zeus-1:~> sbatch runFoam.slm
```

### 2.3 Postprocess (reconsrtuct) the results
Create the following script (postFOAM.sh) inside the case directory:

```shell
#!/bin/bash -l
#SBATCH --export=NONE
#SBATCH --time=00:15:00
#SBATCH --ntasks=1
#SBATCH --partition=debugq
#SBATCH --clusters=zeus

#----------
# Load the necessary modules
module load singularity

#----------
#Setting some preliminary environmental variables
theRepo=$MYGROUP/singularity/myRepository/OpenFOAM
theType=openfoam
theVersion=7
theProvider=mickey
theImage=$theRepo/$theType-$theVersion-$theProvider.sif

#----------
# Execute the postprocessing tools
echo "I am in dir: $PWD"
echo "5: Reconstructing the case:"
srun --export=all -n 1 -N 1 singularity exec $theImage reconstructPar -latestTime
```

---
Back to the [README](../../README.md)