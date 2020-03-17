#!/bin/bash

#Main Settings Singularity
SING_VERSION=3.5.2
source ~/bin/load/singularity-v$SING_VERSION.sh
myRepo=/vol2/singularity/myRepository/OpenFOAM

#Test mark
testMark=2000


#Cycling 5 times big
iMax=5
for ii in `seq 1 $iMax`; do
   testHere=$(( testMark + ii ))
   echo $testHere
   #Pawsey 7 docker.internal
   find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
   docker run --rm -u $(id -u):$(id -g) --mount=type=bind,source=$PWD,target=/localDir -w /localDir alexisespinosa/openfoam:7 /bin/bash -c 'source /opt/OpenFOAM/OpenFOAM-7/etc/bashrc; mpirun -np 4 pimpleFoam -parallel | tee log.pimpleFoam.pawsey-7.docker.internal.XX'
   mv log.pimpleFoam.pawsey-7.docker.internal.XX log.pimpleFoam.pawsey-7.docker.internal.$testHere

   #Pawsey 7 singularity.internal
   find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
   singularity exec $myRepo/openfoam-7-pawsey.sif mpirun -n 4 pimpleFoam -parallel | tee log.pimpleFoam.pawsey-7.singularity.internal.XX
   mv log.pimpleFoam.pawsey-7.singularity.internal.XX log.pimpleFoam.pawsey-7.singularity.internal.$testHere

   #Pawsey 7 singularity.hybrid
   find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
   source ~/bin/load/mpich-3.1.4.sh
   mpirun --version
   mpirun -n 4 singularity exec $myRepo/openfoam-7-pawsey.sif pimpleFoam -parallel | tee log.pimpleFoam.pawsey-7.singularity.hybrid.XX
   mv log.pimpleFoam.pawsey-7.singularity.hybrid.XX log.pimpleFoam.pawsey-7.singularity.hybrid.$testHere

   #Pawsey v1912 internal
   find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
   docker run --rm -u $(id -u):$(id -g) --mount=type=bind,source=$PWD,target=/localDir -w /localDir alexisespinosa/openfoam:v1912 /bin/bash -c 'source /opt/OpenFOAM/OpenFOAM-v1912/etc/bashrc; mpirun -np 4 pimpleFoam -parallel | tee log.pimpleFoam.pawsey-v1912.docker.internal.XX'
   mv log.pimpleFoam.pawsey-v1912.docker.internal.XX log.pimpleFoam.pawsey-v1912.docker.internal.$testHere
   
   #Pawsey v1912 singularity.internal
   find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
   singularity exec $myRepo/openfoam-v1912-pawsey.sif mpirun -n 4 pimpleFoam -parallel | tee log.pimpleFoam.pawsey-v1912.singularity.internal.XX
   mv log.pimpleFoam.pawsey-v1912.singularity.internal.XX log.pimpleFoam.pawsey-v1912.singularity.internal.$testHere

   #Pawsey v1912 singularity.hybrid
   find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
   source ~/bin/load/mpich-3.1.4.sh
   mpirun --version
   mpirun -n 4 singularity exec $myRepo/openfoam-v1912-pawsey.sif pimpleFoam -parallel | tee log.pimpleFoam.pawsey-v1912.singularity.hybrid.XX
   mv log.pimpleFoam.pawsey-v1912.singularity.hybrid.XX log.pimpleFoam.pawsey-v1912.singularity.hybrid.$testHere
done
