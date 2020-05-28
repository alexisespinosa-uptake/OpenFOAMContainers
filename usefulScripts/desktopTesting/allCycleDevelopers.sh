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

#Test mark
testMark=1000


#Cycling 5 times big
iMax=5
for ii in `seq 1 $iMax`; do
   testHere=$(( testMark + ii ))
   echo $testHere
   #Foundation 7 docker.internal
   find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
   docker run --rm -u $(id -u):$(id -g) --mount=type=bind,source=$PWD,target=/localDir -w /localDir --entrypoint /localDir/entryFoundation-7.sh openfoam/openfoam7-paraview56:latest
   mv log.pimpleFoam.foundation-7.docker.internal.XX log.pimpleFoam.foundation-7.docker.internal.$testHere

   #Foundation 7 singularity.internal
   find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
   singularity exec $myRepo/openfoam-7-foundation.sif mpirun -n 4 pimpleFoam -parallel | tee log.pimpleFoam.foundation-7.singularity.internal.XX
   mv log.pimpleFoam.foundation-7.singularity.internal.XX log.pimpleFoam.foundation-7.singularity.internal.$testHere

   #Foundation 7 singularity.hybrid
   find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
   source ~/bin/load/openmpi-2.1.1.sh
   mpirun --version
   mpirun -n 4 singularity exec $myRepo/openfoam-7-foundation.sif pimpleFoam -parallel | tee log.pimpleFoam.foundation-7.singularity.hybrid.XX
   mv log.pimpleFoam.foundation-7.singularity.hybrid.XX log.pimpleFoam.foundation-7.singularity.hybrid.$testHere

   #ESI v1912 internal
   find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
   docker run --rm -u $(id -u):$(id -g) --mount=type=bind,source=$PWD,target=/localDir -w /localDir openfoamplus/of_v1912_centos73:latest /bin/bash -c 'source /opt/OpenFOAM/setImage_v1912.sh; mpirun -np 4 pimpleFoam -parallel | tee log.pimpleFoam.esi-v1912.docker.internal.XX'
   mv log.pimpleFoam.esi-v1912.docker.internal.XX log.pimpleFoam.esi-v1912.docker.internal.$testHere
   
   #ESI v1912 singularity.internal
   find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
   singularity exec $myRepo/openfoam-v1912-esi.sif mpirun -n 4 pimpleFoam -parallel | tee log.pimpleFoam.esi-v1912.singularity.internal.XX
   mv log.pimpleFoam.esi-v1912.singularity.internal.XX log.pimpleFoam.esi-v1912.singularity.internal.$testHere

   #ESI v1912 singularity.hybrid
   find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
   source ~/bin/load/openmpi-1.10.4.sh
   mpirun --version
   mpirun -n 4 singularity exec $myRepo/openfoam-v1912-esi.sif pimpleFoam -parallel | tee log.pimpleFoam.esi-v1912.singularity.hybrid.XX
   mv log.pimpleFoam.esi-v1912.singularity.hybrid.XX log.pimpleFoam.esi-v1912.singularity.hybrid.$testHere
done
