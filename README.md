(This document is under development.)

# General Documentation

Here we provide some examples of how to build OpenFOAM containers that have been tested to run properly in Pawsey Supercomputers. Users are encouraged to use this document and the examples provided as a guide for building their own OpenFOAM containers.

In the directory "basicInstallations" examples of the Docker and Singularity definition files for building plain OpenFOAM containers are provided.

In the directory "installationsWithAdditionalTools" we provide examples of the Docker and Singularity definition files for building-in additional tools on top of the basic OpenFOAM containers.

## Use of OpenFOAM containers at Pawsey's supercomputers
The installation of any version of OpenFOAM on our Supercomputers is not an easy task. There are always some details to be fixed/replaced from the typical basic installation instructions. Therefore, if the OpenFOAM version that you require is not available already in our supercomputers, we strongly recommend you to use a container with MPICH and OpenFOAM installed inside.

Unfortunately, native OpenFOAM containers provided by the original developers of OpenFOAM cannot be used in Pawsey supercomputers. The main reason is that developers' containers have been compiled with OpenMPI, which is not Application Binary Interface (ABI) compatible with current MPI installations in Pawsey systems. At present, all Pawsey systems have installed at least one MPICH ABI compatible implementation: CrayMPICH on the Crays (Magnus and *Galaxy), IntelMPI on Zeus. Therefore, any container to be running MPI applications at Pawsey's supercomputers should be equipped with MPICH and tools (OpenFOAM in this case) compiled with its libraries.

On the other hand, the preferred container manager for Pawsey supercomputers is Singularity and containers need to be prepared for it. We recommend the following approach for developing/using OpenFOAM containers at Pawsey's supercomputers: (i) build a Docker OpenFOAM container from scratch compiled with MPICH, (ii) port the Docker container into a Singularity container and (iii) use Singularity to run your OpenFOAM container.

### Creation/download of MPICH-OpenFOAM containers to be used at Pawsey

The following two steps are needed for the creation of MPICH-OpenFOAM containers to be executed at Pawsey:

* [I. Create a MPICH-OpenFOAM container with Docker](./Documentation/Creation/CREATE_MPICH_OPENFOAM_CONTAINER_DOCKER.md)
* [II. Port your Docker container into Singularity and copy it into Pawsey](./Documentation/Creation/PORT_DOCKER_CONTAINER_TO_SINGULARITY.md)

Or, you can pull the containers already created and mantained by Pawsey:

* [III. Pull Pawsey's MPICH-OpenFOAM containers](./Documentation/Creation/PULL_PAWSEY_CONTAINERS.md)


You can also compile your own solver or add tools:

* [IV. Compiling your own OpenFOAM solver](./Documentation/Creation/COMPILING_YOUR_OWN_SOLVER.md) (under development, may be very out of date)
* [V. Adding tools (like CFDEM-LIGGHTS or waves2FOAM) and produce a new container](./Documentation/Creation/ADDING_TOOLS_TO_NEW_IMAGE.md) (under development, may be very out of date)
* [VI. Some other building hints](./Documentation/Creation/SOME_OTHER_BUILDING_HINTS.md)


### Running instructions

* [VII. Running MPICH-OpenFOAM containers **at Pawsey Supercomputers** with **Singularity**](./Documentation/Usage/RunningAtPawseyWithSingularity.md)

## Use of OpenFOAM containers at Pawsey's Nimbus Cloud Service (or your local linux desktop)
OpenFOAM is much more easier to install in a linux Nimbus virtual machine (or in your local linux desktop) than it is in a supercomputer. Therefore, installing and using your own version of OpenFOAM in Nimbus is a non-complicated task. 

Nevertheless, users may already count with a MPICH-OpenFOAM container that works fine on Pawsey's Supercomputers (as most of this documentation talks about). Or even may want to run the native OpenFOAM developers' Docker containers they provide.

All these three options are possible at Nimbus (or in your local linux desktop). Here we provide some instructions for the last two options, and also compare the performance between running with Docker, Singularity and Singularity-HibridMode.

* [VIII. Running MPICH-OpenFOAM containers **at Nimbus cloud service** (or your local linux desktop) with **Docker**](./Documentation/Usage/RunningLocalWithDocker.md) (under development)
* [IX. Running MPICH-OpenFOAM containers **at Nimbus cloud service** (or your local linux desktop) with **Singularity**](./Documentation/Usage/RunningLocalWithSingularity.md)  (under development)
* [X. Running Foundation's or ESI's native OpenMPI-OpenFOAM containers **at Nimbus cloud service** (or your local linux desktop)](./Documentation/Usage/RunningLocalFoundationOrESI.md) (under development)
* [(XI.)(Additional) Comparing performance of Docker, Singularity and Singularity-HybridMode in a linux desktop or VM](./Documentation/Usage/ComparingPerformance.md)





