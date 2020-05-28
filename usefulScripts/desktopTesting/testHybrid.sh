#!/bin/bash

#Main Settings Singularity
SING_VERSION=3.5.2
source ~/bin/load/singularity-v$SING_VERSION.sh
myRepo=/vol2/singularity/myRepository/OpenFOAM
#NOTE: For the hybrid mode singularity runs, the right MPI needst to be loaded.
#      This is performed by sourcing loading scripts.
#      All the MPI loading scripts create the right environment variables for singularity:
#      SINGULARITYENV_LD_LIBRARY_PATH
#      SINGULARITY_BINDPATH

#Testing the different openmpi installations
testHere=openmpi-2.1.1
source ~/bin/load/openmpi-2.1.1.sh
##source ~/bin/load/openmpi-1.10.4.sh

#Checking the cores available and the mpi version
find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
mpirun --version

#Foundation 7 singularity.hybrid
mpirun -n 4 singularity exec $myRepo/openfoam-7-foundation.sif pimpleFoam -parallel | tee log.pimpleFoam.foundation-7.singularity.hybrid.XX
mv log.pimpleFoam.foundation-7.singularity.hybrid.XX log.pimpleFoam.foundation-7.singularity.hybrid.$testHere

#ESI v1912 singularity.hybrid
##mpirun -n 4 singularity exec $myRepo/openfoam-v1912-esi.sif pimpleFoam -parallel | tee log.pimpleFoam.esi-v1912.singularity.hybrid.XX
##mv log.pimpleFoam.esi-v1912.singularity.hybrid.XX log.pimpleFoam.esi-v1912.singularity.hybrid.$testHere
