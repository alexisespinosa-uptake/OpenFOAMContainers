## (Additional). Performance test of Docker and Singularity MPICH images

Besides the usage of the internal MPI, singularity allows the usage of the host MPI instead. This is known as the "hybrid approach" in the documentation of Sylabs: [mpi](https://sylabs.io/guides/3.3/user-guide/mpi.html). This gives a performance advantage as MPI applications are allowed to use "bare metal" communications instead of an emulaton of MPI processes within the container manager environment.

Here we test the time needed for the execution of the channel395 tutorial on a personal computer.

#### Docker container interactive: run in parallel with internal MPICH

First, we generate results for the internal run with an interactive session with Docker (using internal MPICH):

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
Now we generate results using the Singularity image interactively (using internal MPICH)

```bash

localHost> singularity shell $myRepository/OpenFOAM/openfoam-7-pawsey.sif

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
localHost> mpirun -n 4 singularity exec $myRepository/OpenFOAM/openfoam-7-pawsey.sif pimpleFoam -parallel | tee log.pimpleFoam.pawsey-7.singularity.hybrid
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

#### Summary
The summary of our results so far show that performance increases when using Singularity. And increases even more when using the hybrid approach (host MPI):

| Tutorial | Container | Mode | Computer | ClockTime |
|----------|-----------|------|-----------|----------|
| channel395 | pawsey/openfoam:7 | Docker-internalMPICH | 4 AMD Opteron 63xx Virtual Machine | 964 s|
| channel395 | openfoam-7-pawsey.sif | Singularity-internalMPICH | 4 AMD Opteron 63xx Virtual Machine | 790 s|
| channel395 | openfoam-7-pawsey.sif | Singularity-hybrid-HostMPICH | 4 AMD Opteron 63xx Virtual Machine | 772 s|



## (Additional) Performance test of OpenFOAM developers' containers using Docker and Singularity with OpenMPI

For the sake of completeness, here we present the performance results when using the developers' containers. It is important to stress again that, under current configuration, developers' containers cannot be used in Pawsey Supercomputers due to their implementation with OpenMPI and not with MPICH. Nevertheless, this information may still be important for Nimbus users running OpenFOAM applications and for the OpenFOAM community in general.

Here we test the time needed for the execution of the channel395 tutorial on a personal computer with foundation's OpenFOAM-7 container (openfoam/openfoam7-paraview56) and ESI OpenFOAM-v1912 container (openfoamplus/of_v1912_centos73).

#### Foundation's OpenFOAM-7 Docker container interactive: run in parallel with internal OpenMPI
For the internal MPI run (OpenMPI) with Docker of the OpenFOAM-7 foundation container:

```shell
localHost> docker run -it --rm -u $(id -u):$(id -g) --mount=type=bind,source=$PWD,target=/localDir -w /localDir openfoam/openfoam7-paraview56:latest bash

[ofuser@a7960016f4fa localDir]$ find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
[ofuser@a7960016f4fa localDir]$ mpirun -n 4 pimpleFoam -parallel | tee log.pimpleFoam.foundation-7.docker.internal
--------------------------------------------------------------------------
[[6676,1],3]: A high-performance Open MPI point-to-point messaging module
was unable to find any relevant network interfaces:

Module: OpenFabrics (openib)
  Host: 986d837ac257

Another transport will be used instead, although this may result in
lower performance.

NOTE: You can disable this warning by setting the MCA parameter
btl_base_warn_component_unused to 0.
--------------------------------------------------------------------------
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
[ofuser@a7960016f4fa localDir]$ exit
exit

localHost> tail -15 log.pimpleFoam.foundation-7.docker.internal | grep Time
ExecutionTime = 924.32 s  ClockTime = 936 s
```
#### Foundation's OpenFOAM-7 Singularity container interactive: run in parallel with internal OpenMPI

###### Porting of the Foundation's OpenFOAM-7 original container into Singularity
For the internal MPI run (OpenMPI) with Singularity of the OpenFOAM-7 foundation container. First create the definition file "Singularity.foundation.def":

```Singularity
Bootstrap: docker
From: openfoam/openfoam7-paraview56

%post
/bin/mv /bin/sh /bin/sl.original
/bin/ln -s /bin/bash /bin/sh
echo ". /opt/openfoam7/etc/bashrc" >> $SINGULARITY_ENVIRONMENT
```
Then create the Singularity image:

```shell
localHost> sudo singularity build $myRepository/openfoam-7-foundation.sif Singularity.foundation.def
```

###### Execution
And, finally, execute the singularity container interactively:

```shell
localHost> singularity shell $myRepository/OpenFOAM/openfoam-7-foundation.sif

Singularity> find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
Singularity> mpirun -n 4 pimpleFoam -parallel | tee log.pimpleFoam.foundation-7.singularity.internal
--------------------------------------------------------------------------
[[29841,1],1]: A high-performance Open MPI point-to-point messaging module
was unable to find any relevant network interfaces:

Module: OpenFabrics (openib)
  Host: alexis

Another transport will be used instead, although this may result in
lower performance.

NOTE: You can disable this warning by setting the MCA parameter
btl_base_warn_component_unused to 0.
--------------------------------------------------------------------------
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

localHost> tail -15 log.pimpleFoam.foundation-7.singularity.internal | grep Time
ExecutionTime = 780.43 s  ClockTime = 782 s
```
#### OpenFOAM-7 Singularity container: run in parallel outside the container with local host OpenMPI in "hybrid mode" (non interactive)
For the hybrid MPI run (host OpenMPI) with Singularity of the OpenFOAM-7 foundation container. First define the binding paths for host OpenMPI:

###### Checking the local host installation of OpenMPI
```shell
localHost> mpirun --version
mpirun (Open MPI) 1.10.4

Report bugs to http://www.open-mpi.org/community/help/

localHost> export SINGULARITY_BINDPATH="/opt/openmpi/openmpi-1.10.4/apps"
localHost> export SINGULARITYENV_LD_LIBRARY_PATH="/opt/openmpi/openmpi-1.10.4/apps/lib"
```
###### Execution
Then execute the container in hybrid mode:

```shell
localHost> find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
localHost> mpirun -n 4 singularity exec $myRepository/OpenFOAM/openfoam-7-foundation.sif pimpleFoam -parallel | tee log.pimpleFoam.foundation-7.singularity.hybrid
--------------------------------------------------------------------------
It looks like MPI_INIT failed for some reason; your parallel process is
likely to abort.  There are many reasons that a parallel process can
fail during MPI_INIT; some of which are due to configuration or environment
problems.  This failure appears to be an internal failure; here's some
additional information (which may only be relevant to an Open MPI
developer):

  ompi_mpi_init: ompi_rte_init failed
  --> Returned "(null)" (-43) instead of "Success" (0)
--------------------------------------------------------------------------
.
.
.
-------------------------------------------------------
Primary job  terminated normally, but 1 process returned
a non-zero exit code.. Per user-direction, the job has been aborted.
-------------------------------------------------------
```
(Something is failing for the hybrid OpenMPI for the hybrid approach for the foundation container)

#### ESI's OpenFOAM-v1912 Docker container interactive: run in parallel with internal OpenMPI
For the internal MPI run (OpenMPI) with Docker of the OpenFOAM-v1912 ESI container:

```shell
localHost> docker run -it --rm -u $(id -u):$(id -g) --mount=type=bind,source=$PWD,target=/localDir -w /localDir ope
nfoamplus/of_v1912_centos73:latest bash

[ofuser@a7960016f4fa localDir]$ find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
[ofuser@a7960016f4fa localDir]$ mpirun -n 4 pimpleFoam -parallel | tee log.pimpleFoam.esi-v1912.docker.internal
/*---------------------------------------------------------------------------*\
| =========                 |                                                 |
| \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox           |
|  \\    /   O peration     | Version:  v1912                                 |
|   \\  /    A nd           | Website:  www.openfoam.com                      |
|    \\/     M anipulation  |                                                 |
\*---------------------------------------------------------------------------*/
.
.
.
End

Finalising parallel run
[ofuser@a7960016f4fa localDir]$ exit
exit

localHost> tail -15 log.pimpleFoam.esi-v1912.docker.internal | grep Time
ExecutionTime = 921.56 s  ClockTime = 933 s
```
#### ESI's OpenFOAM-v1912 Singularity container interactive: run in parallel with internal OpenMPI

###### Porting of the ESI's OpenFOAM-v1912 original container into Singularity
For the internal MPI run (OpenMPI) with Singularity of the OpenFOAM-v1912 ESO container. First create the definition file "Singularity.esi.def":

```Singularity
Bootstrap: docker
From: openfoamplus/of_v1912_centos73

%post
/bin/mv /bin/sh /bin/sl.original
/bin/ln -s /bin/bash /bin/sh
echo ". /opt/OpenFOAM/setImage_v1912.sh" >> $SINGULARITY_ENVIRONMENT
```
(Note that this container has an upper level script "setImage_v1912.sh" to set all the needed environment rather than just sourcing the bashrc)

Then create the Singularity image:

```shell
localHost> sudo singularity build $myRepository/openfoam-v1912-esi.sif Singularity.esi.def
```

###### Execution
```shell
localHost> singularity shell $myRepository/OpenFOAM/openfoam-v1912-esi.sif

Singularity> find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
Singularity> mpirun -n 4 pimpleFoam -parallel | tee log.pimpleFoam.esi-v1912.singularity.internal
/*---------------------------------------------------------------------------*\
| =========                 |                                                 |
| \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox           |
|  \\    /   O peration     | Version:  v1912                                 |
|   \\  /    A nd           | Website:  www.openfoam.com                      |
|    \\/     M anipulation  |                                                 |
\*---------------------------------------------------------------------------*/
.
.
.
End

Finalising parallel run
Singularity> exit
exit

localHost> tail -15 log.pimpleFoam.esi-v1912.singularity.internal | grep Time
ExecutionTime = 784.59 s  ClockTime = 786 s
```
#### OpenFOAM-v1912 Singularity container: run in parallel outside the container with local host OpenMPI in "hybrid mode" (non interactive)
For the hybrid MPI run (host OpenMPI) with Singularity of the OpenFOAM-v1912 ESI container:

```shell
localHost> find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
localHost> mpirun -n 4 singularity exec $myRepository/OpenFOAM/openfoam-v1912-esi.sif pimpleFoam -parallel | tee log.pimpleFoam.esi-v1912.singularity.hybrid
/*---------------------------------------------------------------------------*\
| =========                 |                                                 |
| \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox           |
|  \\    /   O peration     | Version:  v1912                                 |
|   \\  /    A nd           | Website:  www.openfoam.com                      |
|    \\/     M anipulation  |                                                 |
\*---------------------------------------------------------------------------*/
.
.
.
End

Finalising parallel run
localHost> tail -15 log.pimpleFoam.esi-v1912.singularity.hybrid | grep Time
ExecutionTime = 755.29 s  ClockTime = 757 s
```
#### Summary
The summary of our results so far show that performance increases when using Singularity. And increases even more when using the hybrid approach (host MPI):

| Tutorial | Container | Mode | Computer | ClockTime |
|----------|-----------|------|-----------|----------|
| channel395 | openfoam/openfoam7-paraview56:latest | Docker-internalOpenMPI | 4 AMD Opteron 63xx Virtual Machine | 936 s|
| channel395 | openfoam-7-foundation.sif | Singularity-internalOpenMPI | 4 AMD Opteron 63xx Virtual Machine | 782 s|
| channel395 | openfoam-7-foundation.sif | Singularity-hybrid-HostOpenMPI | 4 AMD Opteron 63xx Virtual Machine | FAILED|
| channel395 | openfoamplus/of\_v1912_centos73:latest | Docker-internalOpenMPI | 4 AMD Opteron 63xx Virtual Machine | 933 s|
| channel395 | openfoam-v1912-esi.sif | Singularity-internalOpenMPI | 4 AMD Opteron 63xx Virtual Machine | 786 s|
| channel395 | openfoam-v1912-esi.sif | Singularity-hybrid-HostOpenMPI | 4 AMD Opteron 63xx Virtual Machine | 757 s|

---
Back to the [README](../../README.md)