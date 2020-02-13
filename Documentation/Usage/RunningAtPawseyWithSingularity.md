# Running OpenFOAM containers at Pawsey Supercomputers using Singularity
Here we describe how to execute MPICH-OpenFOAM containers at Pawsey Supercomputers. Every parallel solver needs to be executed with the Supercomputer MPICH using the "hybrid mode" of Singularity.

## 0. Preparation

ssh to zeus or magnus:

```shell
localShell:$ ssh user@zeus.pawsey.org.au
```

Check the content in the repository directory for the singularity containers. You can use the containers maintained by Pawsey:

```shell
user@zeus-1:~> theRepo=/group/singularity/pawseyRepository/OpenFOAM
user@zeus-1:~> ls $theRepo
openfoam-5.x_CFDEM-pawsey.sif  openfoam-5.x-pawsey.sif  openfoam-7-pawsey.sif  openfoam-v1912-pawsey.sif
```
(The content listed here may be out of date. Please refer to the guide on how to [pull Pawsey's MPICH-OpenFOAM containers](./Documentation/Creation/PULL_PAWSEY_CONTAINERS.md) for more information.)

Or you can use your project repository, that you share with the other members of your group:

```shell
user@zeus-1:~> theRepo=$MYGROUP/../singularity/groupRepository/OpenFOAM
user@zeus-1:~> ls $theRepo
openfoam-v1812-mickey.sif
```

Or your personal repository:

```shell
user@zeus-1:~> theRepo=$MYGROUP/singularity/myRepository/OpenFOAM
user@zeus-1:~> ls $theRepo
openfoam-7-mickey.sif
```

In the following example, we'll use the pawseyRepository with openfoam-7. We use the following approach to define the image name:

```shell
user@zeus-1:~> theRepo=/group/singularity/pawseyRepository/OpenFOAM
user@zeus-1:~> theTool=openfoam
user@zeus-1:~> theVersion=7
user@zeus-1:~> theProvider=pawsey
user@zeus-1:~> theImage=$theRepo/$theTool-$theVersion-$theProvider.sif
```

And the main step in the preparation, load the singularity module:

```shell
user@zeus-1:~> module load singularity
```

## 1. The case to solve

Users that count already with a case to solve can skip this section and move to the next one (Best Practises). But if the user wants to perform a test from the tutorials provided by OpenFOAM, they can follow the instructions in this section.

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


## 2. Best Practices
The following best practises will avoid the problems of contention in Pawsey's shared file system.

Move to the case directory

```shell
user@zeus-1:~> cd $MYSCRATCH/OpenFOAM/$USER-$theVersion/run/tutorials/damBreak
```
and edit your configuration dictionaries to comply with Pawsey Best Practices.

### 2.1 Output binary result files
Users should set the result files to be written in binary. You can make some exceptions during the test and development phase of your project, but production runs should produce binary result files.

Edit the controlDict:

```shell
user@zeus-1:~>vi ./system/controlDict
```

comment the ascii setting and to set the binary output:

```bash
//writeFormat     ascii;
writeFormat     binary;
```

### 2.2 If possible, set "purgeWrite"
This parameter define the total number of time directories to be saved. Therefore, if this parameter is set to 10, then only 10 new time directories will be created. If the case reaches this number of time directories saved, then they will be recycled and replace, so that the 11th time directory to be saved replaces the 1st, the 12th replaces the 2nd, etc. At the end, only 10 time directories will appear in the result "processors*" directories.

Obviously, this is only useful whenever the results of the beginning of the simulation are not of interest to the user.

Edit the controlDict:

```shell
user@zeus-1:~>vi ./system/controlDict
```

comment the purgeWrite setting and to set it to "10":

```bash
//purgeWrite      0;
purgeWrite      10;
```

### 2.3 Never activate "runTimeModifiable"
Users should not use the runTimeModifiable mode of OpenFOAM. This option may produce a large number of reads to the shared file system, which can produce contention and reduction of performance.

Edit the controlDict:

```shell
user@zeus-1:~>vi ./system/controlDict
```

comment the runTimeModifiable setting and to set it to "no":

```bash
//runTimeModifiable yes;
runTimeModifiable no;
```


## 2. Execute OpenFOAM




### 2.1 Serial preprocessing
Most of OpenFOAM preprocessing tools are serial. Here we execute several preprocessing tools as serial substeps defined in a job script. Create the following script (preFOAM.sh) inside the case directory 

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
theRepo=/group/singularity/pawseyRepository/OpenFOAM
theTool=openfoam
theVersion=7
theProvider=pawsey
theImage=$theRepo/$theTool-$theVersion-$theProvider.sif

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
user@zeus-1:~> sbatch preFOAM.slm
```

### 2.2 Executing a parallel solver
As mentioned along this document. The MPICH-OpenFOAM container should be executed with the "hybrid mode" of singularity. This uses the Supercomputer's MPICH installation binded to the one defined inside the container. Binding is performed automatically if the singularity module is loaded.

For this example, create the following script (runFOAM.sh) inside the case directory:

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
theRepo=/group/singularity/pawseyRepository/OpenFOAM
theTool=openfoam
theVersion=7
theProvider=pawsey
theImage=$theRepo/$theTool-$theVersion-$theProvider.sif

#----------
# Execute the solver
echo "I am in dir: $PWD"
echo "4: Executing the case in parallel in hybrid-mode"
srun --export=all -n $SLURM_NTASKS -N $SLURM_JOB_NUM_NODES singularity exec $theImage interFoam -parallel
~~~

And submit the job

```shell
user@zeus-1:~> sbatch runFOAM.slm
```

### 2.3 Postprocessing
The reconstruction of the case is again a serial task. For this, create the following script (postFOAM.sh) inside the case directory:

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
theRepo=/group/singularity/pawseyRepository/OpenFOAM
theTool=openfoam
theVersion=7
theProvider=pawsey
theImage=$theRepo/$theTool-$theVersion-$theProvider.sif

#----------
# Execute the postprocessing tools
echo "I am in dir: $PWD"
echo "5: Reconstructing the case:"
srun --export=all -n 1 -N 1 singularity exec $theImage reconstructPar -latestTime
```
And submit the job

```shell
user@zeus-1:~> sbatch postFOAM.slm
```

## 3. Best Practices


---
Back to the [README](../../README.md)