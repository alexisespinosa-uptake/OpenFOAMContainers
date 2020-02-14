# Executing (and testing performance) of Docker and Singularity MPICH-OpenFOAM images at Nimbus cloud service (or your local linux desktop)

Besides the usage of the internally installed MPI, Singularity allows the usage of the host MPI instead. This is known as the "hybrid approach" in the documentation of Sylabs: [mpi](https://sylabs.io/guides/3.3/user-guide/mpi.html). This gives a performance advantage as MPI applications are allowed to use "bare metal" communications instead of an emmulaton of MPI processes within the container manager environment. Here we test the performace of these approaches, together with the use of the internally installed MPI in a Docker container.

The Docker container images exist in DockerHub: alexisespinosa/openfoam:7 and alexisespinosa/openfoam-v1912 and were build following the guide: [Create a MPICH-OpenFOAM container with Docker](../Creation/CREATE_MPICH_OPENFOAM_CONTAINER_DOCKER.md).

The Singularity images were built following the guide: [Port your Docker container into Singularity and copy it into Pawsey](../Creation/PORT_DOCKER_CONTAINER_TO_SINGULARITY.md). All the singularity containers are considered to be in a local directory (repository) of your host. For example:

```shell
localHost> myRepo=/vol2/singularity/myRepository/OpenFOAM
localHost> ls $myRepo
openfoam-7-foundation.sif  openfoam-v1912-esi.sif
openfoam-7-pawsey.sif      openfoam-v1912-pawsey.sif
```
Here we test the time needed for the execution of the **channel395** tutorial on a personal computer with Pawsey's MPICH-OpenFOAM containers. This "channel395" tutorial is the same that was used to test the correctness of the containers' implementation.

## Extracting the tutorial case into your local disk
To write (and therefore, to copy) a directory that already exists inside the container into the local disk requires the mounting of the local disk on the container. This is done by default in Singularity. Therefore, to perform the copy is a simple task for singularity containers. For Docker containers it is not that easy.

#### Extracting the tutorial case with Docker
Here we explain how to do it with Docker. First, find the tutorial to use:

```shell
localHost> theProvider=alexisespinosa
localHost> theType=openfoam
localHost> theVersion=7
localHost> theImage=$theProvider/$theType:$theVersion
localHost> docker pull $theImage
localHost> docker run --rm $theImage bash -c 'source /opt/OpenFOAM/OpenFOAM-7/etc/bashrc; find $FOAM_TUTORIALS -type d -name "channel395"'
/opt/OpenFOAM/OpenFOAM-7/tutorials/incompressible/pimpleFoam/LES/channel395
```
* **\-\-rm** is for avoiding Docker to keep the container alive after execution
* **bash -c 'command'** is to be able to source the OpenFOAM "bashrc" file, and to execute the find command recognising the internal value of $FOAM_TUTORIALS
 
Now copy the tutorial case the local host file system:

```shell
localHost> mkdir -p ./run/tutorials
localHost> docker run --rm --mount=type=bind,source=$PWD,destination=/localDir -u $(id -u):$(id -g) $theImage bash -c 'cp -r /opt/OpenFOAM/OpenFOAM-7/tutorials/incompressible/pimpleFoam/LES/channel395 /localDir/run/tutorials'
```
* **---mount=type=bind,source=$PWD,destination=/localDir** mounts the local directory into the directory /localDir
* **-u $(id -u):$(id -g)** tells docker to use the host user identity in order to allow access/permissions to the host file system

#### Extracting the tutorial case with Singularity
Using the singularity container is easier:

```shell
localHost> theRepo=/vol2/singularity/myRepository/OpenFOAM
localHost> theTool=openfoam
localHost> theVersion=7
localHost> theProvider=pawsey
localHost> theImage=$theRepo/$theTool-$theVersion-$theProvider.sif
localHost> singularity exec $theImage bash -c 'find $FOAM_TUTORIALS -type d -name "channel395"'
/opt/OpenFOAM/OpenFOAM-7/tutorials/incompressible/pimpleFoam/LES/channel395
```
* **bash -c 'command'** is to execute the find command recognising the internal value of $FOAM_TUTORIALS

```shell
localHost> mkdir -p ./run/tutorials
localHost> singularity exec $theImage bash -c 'cp -r $FOAM_TUTORIALS/incompressible/pimpleFoam/LES/channel395 /localDir/run/tutorials'
```

## Preprocessing
Any OpenFOAM tool can be ran through the container. Here we only explain the usage with Singularity (non interactive):

```shell
localHost> cd ./run/tutorials/channel395
localHost> singularity exec $theImage blockMesh 2>&1 | tee log.blockMesh
localHost> singularity exec $theImage decomposePar -cellDist 2>&1 | tee log.decomposePar
```

## Running the parallel solver

#### Docker container interactive: run in parallel with internal MPICH

Here we generate results for the internal run with an interactive session with Docker (using internal MPICH):

```bash
localHost> docker run -it --rm -u $(id -u):$(id -g) --mount=type=bind,source=$PWD,target=/localDir -w /localDir alexisespinosa/openfoam:7
groups: cannot find name for group ID 1000

I have no name!@841e2f6969d2:/localDir$ ls
0	160  320  440  600  760  880	 constant	   log.pimpleFoam.singularity.hybrid	postProcessing
0.orig	200  360  480  640  80	 920	 log.blockMesh	   log.pimpleFoam.singularity.internal	processors4
1000	240  40   520  680  800  960	 log.decomposePar  log.postChannel			system
120	280  400  560  720  840  Allrun  log.pimpleFoam    log.reconstructPar
I have no name!@841e2f6969d2:/localDir$ find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf {} \;
I have no name!@841e2f6969d2:/localDir$ source /opt/OpenFOAM/OpenFOAM-7/etc/bashrc
I have no name!@841e2f6969d2:/localDir$ mpirun -n 4 pimpleFoam -parallel | tee log.pimpleFoam.pawsey-7.docker.internal
/*---------------------------------------------------------------------------*\
  =========                 |
  \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox
   \\    /   O peration     | Website:  https://openfoam.org
    \\  /    A nd           | Version:  7
     \\/     M anipulation  |
\*---------------------------------------------------------------------------*/
.
.
.
End

Finalising parallel run
I have no name!@841e2f6969d2:/localDir$ exit
exit

localHost> tail -15 log.pimpleFoam.pawsey-7.docker.internal | grep Time
ExecutionTime = 902.04 s  ClockTime = 964 s
```


#### Singularity container interactive: run in parallel with internal MPICH
Here we generate results using the Singularity image interactively (using internal MPICH)

```bash

localHost> singularity shell $myRepo/openfoam-7-pawsey.sif

Singularity> ls
0	120  240  360  440  560  680  80   880	Allrun	       log.decomposePar  log.reconstructPar  system
0.orig	160  280  40   480  600  720  800  920	constant       log.pimpleFoam	 postProcessing
1000	200  320  400  520  640  760  840  960	log.blockMesh  log.postChannel	 processors4
Singularity> find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
Singularity> mpirun -n 4 pimpleFoam -parallel | tee log.pimpleFoam.pawsey-7.singularity.internal
/*---------------------------------------------------------------------------*\
  =========                 |
  \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox
   \\    /   O peration     | Website:  https://openfoam.org
    \\  /    A nd           | Version:  7
     \\/     M anipulation  |
\*---------------------------------------------------------------------------*/
.
.
.
End

Finalising parallel run
Singularity> exit
exit

localHost> tail -15 log.pimpleFoam.pawsey-7.singularity.internal | grep Time
ExecutionTime = 734.68 s  ClockTime = 790 s
```

#### Singularity container: run in parallel outside the container with local host MPICH in "hybrid mode" (non interactive)
Now, we can use the "hybrid approach". For that, it is necessary to count with an MPICH installation in the local host. Then, the host installation of MPICH needs to be binded to the container. This is accomplished by defining the environmental variables SINGULARITY\_BINDPATH and SINGULARITY\_LD\_LIBRARY_PATH:

```bash
localHost> mpirun --version
HYDRA build details:
    Version:                                 3.1.4
    Release Date:                            Fri Feb 20 15:02:56 CST 2015
    CC:                              gcc    
    CXX:                             g++    
    F77:                             gfortran   
    F90:                             gfortran   
    Configure options:                       '--disable-option-checking' '--prefix=/opt/mpich/mpich-3.1.4/apps' '--enable-fast=all,O3' '--cache-file=/dev/null' '--srcdir=.' 'CC=gcc' 'CFLAGS= -DNDEBUG -DNVALGRIND -O3' 'LDFLAGS= ' 'LIBS=-lpthread ' 'CPPFLAGS= -I/opt/mpich/mpich-3.1.4/src/mpl/include -I/opt/mpich/mpich-3.1.4/src/mpl/include -I/opt/mpich/mpich-3.1.4/src/openpa/src -I/opt/mpich/mpich-3.1.4/src/openpa/src -D_REENTRANT -I/opt/mpich/mpich-3.1.4/src/mpi/romio/include'
    Process Manager:                         pmi
    Launchers available:                     ssh rsh fork slurm ll lsf sge manual persist
    Topology libraries available:            hwloc
    Resource management kernels available:   user slurm ll lsf sge pbs cobalt
    Checkpointing libraries available:       
    Demux engines available:                 poll select
    
localHost> export SINGULARITY_BINDPATH="/opt/mpich/mpich-3.1.4/apps"
localHost> export SINGULARITYENV_LD_LIBRARY_PATH="/opt/mpich/mpich-3.1.4/apps/lib"
```

And now, the solver inside the container is executed using the host MPICH installation (MPI is called from the host):

```bash
localHost> find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
localHost> mpirun -n 4 singularity exec $myRepo/openfoam-7-pawsey.sif pimpleFoam -parallel | tee log.pimpleFoam.pawsey-7.singularity.hybrid
/*---------------------------------------------------------------------------*\
  =========                 |
  \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox
   \\    /   O peration     | Website:  https://openfoam.org
    \\  /    A nd           | Version:  7
     \\/     M anipulation  |
\*---------------------------------------------------------------------------*/
.
.
.
End

Finalising parallel run
localHost> tail -15 log.pimpleFoam.pawsey-7.singularity.hybrid | grep Time
ExecutionTime = 717.55 s  ClockTime = 772 s
```

## Summary
The summary of our results so far show that performance increases when using Singularity. And increases even more when using the hybrid approach (host MPI):

| Tutorial | Container | Mode | Computer | ClockTime |
|----------|-----------|------|-----------|----------|
| channel395 | pawsey/openfoam:7 | Docker-internalMPICH | 4 AMD Opteron 63xx Virtual Machine | 964 s|
| channel395 | openfoam-7-pawsey.sif | Singularity-internalMPICH | 4 AMD Opteron 63xx Virtual Machine | 790 s|
| channel395 | openfoam-7-pawsey.sif | Singularity-hybrid-HostMPICH | 4 AMD Opteron 63xx Virtual Machine | 772 s|


---
Back to the [README](../../README.md)