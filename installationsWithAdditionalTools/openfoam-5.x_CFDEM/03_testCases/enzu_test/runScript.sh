#!/bin/bash -l
#SBATCH --export=NONE
#SBATCH --time=00:15:00
#SBATCH --ntasks=48
#SBATCH --ntasks-per-node=24
#SBATCH --partition=debugq

#------------------------
#Loading the right singularity module
#module load singularity/3.5.2
module load singularity
if [[ $SLURM_WORKING_CLUSTER = *zeus* ]]; then module rm xalt; fi

#------------------------
#Choosing the container image to use
#export containerImage=/group/d77/ezheng/singularity_container/CFDEM_Enzu_fixed.sif
#export containerImage=/group/pawsey0001/espinosa/singularity/myRepo/OpenFOAM/CFDEM-Enzu.sif.try09
export containerImage=/group/pawsey0001/singularity/groupRepo/OpenFOAM/openfoam-5.x_CFDEM-pawsey.sif

#------------------------
#Replace existing directories with the fresh new ones
rm -rf CFD DEM
cp -r CFD.base CFD
cp -r DEM.base DEM
cd CFD

#------------------------
#Running the several steps
#Decomposition is a serial substep
srun --export=all -n 1 -N 1 singularity exec $containerImage decomposePar 2>&1 | tee log.decomposePar

#The solver runs in parallel using supercomputer mpi (hybrid mode)
srun --export=all -n 48 -N 2 singularity exec $containerImage cfdemSolverPiso -parallel 2>&1 | tee log.cfdemSolver

#The reconstruction is a serial substep
srun --export=all -n 1 -N 1 singularity exec $containerImage reconstructPar -latestTime 2>&1 | tee log.reconstructPar
