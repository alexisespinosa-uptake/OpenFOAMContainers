## Running at Pawsey

### Using a job script (common practice)

First, the case directory should exist in /scratch, in my case I'm running a copy of the tutorial damBreak
and I have a copy of the case directory in scratch:
```
cd /scratch/pawseyxxxx/espinosa/OpenFOAM/espinosa-3.0.1/tutorials/damBreak
ls

0  Allrun  constant  runContainerFOAM.slm  system
```

Job execution in pawsey systems is usually not interactive, so the workflow should be managed in a script.
Obviously, this script needs to be sumitted to scheduler:
```
sbatch runContainerFOAM.slm
```

In this case, the runContainerFOAM.slm script has:
```
#!/bin/bash -l
#SBATCH --export=NONE
#SBATCH --time=00:15:00
#SBATCH --ntasks=4
#SBATCH --ntasks-per-node=24
#SBATCH --partition=debugq

module load shifter
#----------
#Setting some preliminary environmental variables
export OF_VERSION=3.0.1

echo "Trying 1:"
srun --export=all -n 1 shifter run alexisespinosa/openfoam:$OF_VERSION blockMesh > logBlockMesh 2>&1
echo "Trying 2:"
srun --export=all -n 1 shifter run alexisespinosa/openfoam:$OF_VERSION setFields > logSetFields 2>&1
echo "Trying 3:"
srun --export=all -n 1 shifter run alexisespinosa/openfoam:$OF_VERSION decomposePar > logDecompose 2>&1
echo "Trying 4:"
srun --export=all -n $SLURM_NTASKS shifter run --mpi alexisespinosa/openfoam:$OF_VERSION interFoam -parallel >logRun 2>&1
```

* **module load shifter** Shiftr needs to be loaded as a first step
* **--export=NONE**, **--export=all** squence: The first one guarantees a clean environment for the script,
the second one guarantees that all the settings within the script (environmental variables set here and within the modules)
will be recognized inside the different sruns.
* **shifter** is the container manager installed in Pawsey systems (the Docker equivalent).
* **run** same command as with Docker. But the additional parameters are a bit different to the docker case:

#### No need for **--rm**
In this case, there is no need to use the --rm as containers are
not saved in the process list by default.

#### Submission directory is mounted by default
There is no need for mounting the local directory, as shifter mounts
the submission directory by default. In case a user needs to mount another directory it can still be done.

#### No need to cd to the case directory
If the submission is perfomed from the case directory, there is no need to cd to the case directory before
executing openfoam commands
