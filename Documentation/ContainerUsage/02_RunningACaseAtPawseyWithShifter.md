# Running OpenFOAM containers at Pawsey using shifter

## 0. Preparation

ssh to zeus or magnus:

```shell
localShell:$ ssh user@zeus.pawsey.org.au
```

Run the following commands to "pull" the image from the Docker repository:

```shell
user@zeus-1:~> theRepo=alexisespinosa
user@zeus-1:~> theContainer=openfoam
user@zeus-1:~> theTag=4.x
user@zeus-1:~> module load shifter/18.06.00
user@zeus-1:~> sg $PAWSEY_PROJECT -c "shifter pull $theRepo/$theContainer:$theTag"
```
(For more info on how to pull images into our systems read the Pawsey Documentation.)

## 1. Define a case. (In this example we'll use a tutorial)
Find the tutorial to use:

```shell
user@zeus-1:~> shifter run $theRepo/$theContainer:$theTag bash -c 'find $FOAM_TUTORIALS -type d -name "damBreak"'
```
* **bash -c 'command'** is to execute the command recognising $FOAM_TUTORIALS inside the container
 
Copy the case you found above to the local host file system:

```shell
user@zeus-1:~> cd $MYSCRATCH
user@zeus-1:~> mkdir -p ./OpenFOAM/user-$theTag/run/tutorials
user@zeus-1:~> cd ./OpenFOAM/user-$theTag/run/tutorials
user@zeus-1:~> shifter run $theRepo/$theContainer:$theTag bash -c 'cp -r $FOAM_TUTORIALS/multiphase/interFoam/RAS/damBreak/damBreak .'  
```

## 2. Execute openfoam tools and solver
Move to the case directory and create the needed job scripts

```shell
user@zeus-1:~> cd $MYSCRATCH/OpenFOAM/user-$theTag/run/tutorials/damBreak
```

### 2.1 Creating the mesh and decomposing (preprocessing)
* Use the following script (preFOAM.slm) inside the case directory 

~~~shell
#!/bin/bash -l 
#SBATCH --export=NONE
#SBATCH --time=00:15:00
#SBATCH --ntasks=1
#SBATCH --partition=debugq
#SBATCH --clusters=zeus

#----------
# Load the necessary modules
module load shifter/18.06.00

#----------
#Setting some preliminary environmental variables
theRepo=alexisespinosa
theContainer=openfoam
theTag=4.x

#----------
# Execute the preprocessing tools
echo "I am in dir: $PWD"
echo "1: Creating the mesh:"
srun --export=all -n 1 -N 1 shifter run $theRepo/$theContainer:$theTag blockMesh
echo "2: Initialising fields:"
srun --export=all -n 1 -N 1 shifter run $theRepo/$theContainer:$theTag setFields
echo "3: Decomposing the case:"
srun --export=all -n 1 -N 1 shifter run $theRepo/$theContainer:$theTag decomposePar
~~~
* (**module load shifter** Shifter module needs to be loaded)
* (**--export=NONE**, **--export=all** sequence: The first one guarantees a clean environment for the script, the second one guarantees that all the settings within the script [environmental variables set here and within the modules] will be recognised inside the different job steps called by srun.)


* And submit the job

```shell
user@zeus-1:~> sbatch preFoam.slm
```
##### Note that: The submission directory is mounted by default for the container
There is no need for mounting the local directory, as shifter mounts the submission directory by default. In case a user needs to mount another directory it can still be done.

### 2.2 Executing the solver
* Use the following script (runFOAM.slm) inside the case directory 

~~~shell
#!/bin/bash -l 
#SBATCH --export=NONE
#SBATCH --time=00:15:00
#SBATCH --ntasks=4
#SBATCH --partition=debugq

#----------
# Load the necessary modules
module load shifter/18.06.00

#----------
#Setting some preliminary environmental variables
theRepo=alexisespinosa
theContainer=openfoam
theTag=4.x

#----------
# Execute the preprocessing tools
echo "I am in dir: $PWD"
echo "4: Executing the case in parallel"
srun --export=all -n $SLURM_NTASKS shifter run --mpi $theRepo/$theContainer:$theTag interFoam -parallel
~~~

* And submit the job

```shell
user@zeus-1:~> sbatch runFoam.slm
```



---
Back to the [README](../../README.md)