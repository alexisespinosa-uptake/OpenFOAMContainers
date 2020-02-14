# Executing (and testing performance) of OpenFOAM developers' containers using Docker and Singularity with OpenMPI at Nimbus cloud service (or your local linux desktop)

For the sake of completeness, here we present the performance results when using the developers' containers. It is important to stress again that, under current configuration, developers' containers cannot be used in Pawsey Supercomputers due to their implementation with OpenMPI and not with MPICH. Nevertheless, this information may still be important for users of the Nimbus Cloud Service at Pawsey (for for their usage in your local linux desktop) running OpenFOAM applications with the official developers' containers.

Here we test the performance of the **OpenMPI** containers from the **Foundation (Docker name: openfoam/openfoam7-paraview56)** and **ESI (Docker name: openfoamplus/of\_v1912\_centos73)** while running the **channel395 tutorial** on a personal computer. This "channel395" tutorial is the same that was used to test the correctness of the containers' implementation. And the same that was for the test of performance of the MPICH-OpenFOAM Pawsey containers (above).

All the Docker containers were pulled following the instructions on the [Foundation website](https://openfoam.org) and [ESI website](https://www.openfoam.com). The containers were then ported to Singularity following the guide: [Port your Docker container into Singularity and copy it into Pawsey](../Creation/PORT_DOCKER_CONTAINER_TO_SINGULARITY.md):

###### Porting of the Foundation's OpenFOAM-7 original container into Singularity
First create the definition file "Singularity.foundation.def":

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
localHost> myRepo=/vol2/singularity/myRepository/OpenFOAM
localHost> sudo singularity build $myRepo/openfoam-7-foundation.sif Singularity.foundation.def
```
###### Porting of the ESI's OpenFOAM-v1912 original container into Singularity
First create the definition file "Singularity.esi.def":

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
localHost> myRepo=/vol2/singularity/myRepository/OpenFOAM
localHost> sudo singularity build $myRepo/openfoam-v1912-esi.sif Singularity.esi.def
```
###### The local repository

All the Singularity container images to be used are considered to be in a local directory (repository) of your host. For example:

```shell
localHost> myRepo=/vol2/singularity/myRepository/OpenFOAM
localHost> ls $myRepo
openfoam-7-foundation.sif  openfoam-v1912-esi.sif
openfoam-7-pawsey.sif      openfoam-v1912-pawsey.sif
```

## Extracting the tutorial case into your local disk

The instructions on how to create the tutorial case in your local disk were already described in the guide for [executing (and testing performance) of MPICH-OpenFOAM containers **at Nimbus cloud service** (or your local linux desktop)](../Usage/RunningLocalWithMPICH.md).

## Using the collated option for the tests

The MPICH-OpenFOAM Pawsey containers were built to use the "--fileHandler collated;" option by default (as can be seen in the guide: [Create a MPICH-OpenFOAM container with Docker](./Documentation/Creation/CREATE_MPICH_OPENFOAM_CONTAINER_DOCKER.md)). In order to use the same option for the testing of the developers' OpenMPI-OpenFOAM containers, the dictionary "controlDict" needs to be updated:

```shell
localHost> vi ./system/controlDict
```

add the following section:

```bash
OptimisationSwitches
{
    fileHandler collated;
}
```
## Preprocessing

The instructions on how to preproces the case (meshing and decomposing) described in the guide for [executing (and testing performance) of MPICH-OpenFOAM containers **at Nimbus cloud service** (or your local linux desktop)](../Usage/RunningLocalWithMPICH.md).

## Running the parallel solver with Foundation's OpenFOAM-7 container

#### Foundation's OpenFOAM-7 Docker container interactive: run in parallel with internal OpenMPI
For this image, the developer has created a series of scripts containing the necessary Docker commands for executing their container. Users can follow the instructions in the [Foundation website](https://openfoam.org) for executing their Docker container.

Nevertheless, the container can also be utilised with standard Docker commands. Here, we use the following approach for the internal MPI run (OpenMPI) with Docker of the OpenFOAM-7 foundation container:

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

For the internal MPI run (OpenMPI) with Singularity of the OpenFOAM-7 foundation container:

```shell
localHost> singularity shell $myRepo/openfoam-7-foundation.sif

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
#### Foundation's OpenFOAM-7 Singularity container: run in parallel outside the container with local host OpenMPI in "hybrid mode" (non interactive)
For the hybrid MPI run (host OpenMPI) with Singularity of the OpenFOAM-7 foundation container.

###### Check the internal OpenMPI installed in the container

```shell
localHost> singularity exec $myRepo/openfoam-7-foundation.sif mpirun --version
mpirun (Open MPI) 2.1.1

Report bugs to http://www.open-mpi.org/community/help/
```
###### Checking that the local host installation of OpenMPI is the same
```shell
localHost> mpirun --version
mpirun (Open MPI) 2.1.1

Report bugs to http://www.open-mpi.org/community/help/
```
###### Defining the binding paths for host OpenMPI
```shell
localHost> export SINGULARITY_BINDPATH="/opt/openmpi/openmpi-2.1.1/apps"
localHost> export SINGULARITYENV_LD_LIBRARY_PATH="/opt/openmpi/openmpi-2.1.1/apps/lib"
```
###### Execution
Then execute the container in hybrid mode:

```shell
localHost> find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
localHost> mpirun -n 4 singularity exec $myRepo/openfoam-7-foundation.sif pimpleFoam -parallel | tee log.pimpleFoam.foundation-7.singularity.hybrid
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
localHost> tail -15 log.pimpleFoam.foundation-7.singularity.hybrid | grep Time
ExecutionTime = 767.18 s  ClockTime = 770 s
```
## Running the parallel solver with ESI's OpenFOAM-v1912 container

#### ESI's OpenFOAM-v1912 Docker container interactive: run in parallel with internal OpenMPI
For this image, the developer has created a series of scripts containing the necessary Docker commands for executing their container. Users can follow the instructions in the [ESI website](https://www.openfoam.com) for executing their Docker container.

Nevertheless, the container can also be utilised with standard Docker commands. Here, we use the following approach for the internal MPI run (OpenMPI) with Docker of the OpenFOAM-v1912 ESI container:

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

For the internal MPI run (OpenMPI) with Singularity of the OpenFOAM-v1912 ESI container:

```shell
localHost> singularity shell $myRepo/openfoam-v1912-esi.sif

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
#### ESI's OpenFOAM-v1912 Singularity container: run in parallel outside the container with local host OpenMPI in "hybrid mode" (non interactive)
For the hybrid MPI run (host OpenMPI) with Singularity of the OpenFOAM-v1912 ESI container.

###### Check the internal OpenMPI installed in the container

```shell
localHost> singularity exec $myRepo/openfoam-v1912-esi.sif mpirun --version
mpirun (Open MPI) 1.10.4

Report bugs to http://www.open-mpi.org/community/help/
```
###### Checking that the local host installation of OpenMPI is the same
```shell
localHost> mpirun --version
mpirun (Open MPI) 1.10.4

Report bugs to http://www.open-mpi.org/community/help/
```
###### Defining the binding paths for host OpenMPI
```shell
localHost> export SINGULARITY_BINDPATH="/opt/openmpi/openmpi-1.10.4/apps"
localHost> export SINGULARITYENV_LD_LIBRARY_PATH="/opt/openmpi/openmpi-1.10.4/apps/lib"
```
###### Execution
Then execute the container in hybrid mode:

```shell
localHost> find processors4 -maxdepth 1 -mindepth 1 -type d -name "*" ! -name "0" ! -name "constant" -exec rm -rf \{} \;
localHost> mpirun -n 4 singularity exec $myRepo/openfoam-v1912-esi.sif pimpleFoam -parallel | tee log.pimpleFoam.esi-v1912.singularity.hybrid
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
## Summary
The summary of our results so far show that performance increases when using Singularity. And increases even more when using the hybrid approach (host MPI):

| Tutorial | Container | Mode | Computer | ClockTime |
|----------|-----------|------|-----------|----------|
| channel395 | openfoam/openfoam7-paraview56:latest | Docker-internalOpenMPI | 4 AMD Opteron 63xx Virtual Machine | 936 s|
| channel395 | openfoam-7-foundation.sif | Singularity-internalOpenMPI | 4 AMD Opteron 63xx Virtual Machine | 782 s|
| channel395 | openfoam-7-foundation.sif | Singularity-hybrid-HostOpenMPI | 4 AMD Opteron 63xx Virtual Machine | 770 s|
| channel395 | openfoamplus/of\_v1912_centos73:latest | Docker-internalOpenMPI | 4 AMD Opteron 63xx Virtual Machine | 933 s|
| channel395 | openfoam-v1912-esi.sif | Singularity-internalOpenMPI | 4 AMD Opteron 63xx Virtual Machine | 786 s|
| channel395 | openfoam-v1912-esi.sif | Singularity-hybrid-HostOpenMPI | 4 AMD Opteron 63xx Virtual Machine | 757 s|

---
Back to the [README](../../README.md)