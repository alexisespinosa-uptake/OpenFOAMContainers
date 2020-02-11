(This document is under development.)

# General Documentation

Here we provide some examples of how to build OpenFOAM containers that have been tested to run properly in Pawsey Supercomputers. Users are encouraged to use this document and the examples provided as a guide for building their own OpenFOAM containers.

In the directory "basicInstallations" examples of the Docker and Singularity definition files for building plain OpenFOAM containers are provided.

In the directory "installationsWithAdditionalTools" we provide examples of the Docker and Singularity definition files for building-in additional tools on top of the basic OpenFOAM containers.

## Use of OpenFOAM containers at Pawsey's supercomputers
The installation of any version of OpenFOAM on our Supercomputers is not an easy task. There are always some details to be fixed/replaced from the typical basic installation instructions. Therefore, if the OpenFOAM version that you require is not available already in our supercomputers, we strongly recommend you to use a container with MPICH and OpenFOAM installed inside.

Unfortunately, native OpenFOAM containers provided by the original developers of OpenFOAM cannot be used in Pawsey supercomputers. The main reason is that developers' containers have been compiled with OpenMPI, which is not Application Binary Interface (ABI) compatible with current MPI installations in Pawsey systems. At present, all Pawsey systems have installed at least one MPICH ABI compatible implementation: CrayMPICH on the Crays (Magnus and *Galaxy), IntelMPI on Zeus. Therefore, any container to be running MPI applications at Pawsey's supercomputers should be equipped with MPICH and tools (OpenFOAM in this case) compiled with its libraries.

On the other hand, the preferred container manager for Pawsey supercomputers is Singularity and containers need to be prepared for it. We recommend the following approach for developing/using OpenFOAM containers at Pawsey's supercomputers: (i) build a Docker OpenFOAM container from scratch compiled with MPICH, (ii) port the Docker container into a Singularity container and (iii) use Singularity to run your OpenFOAM container.

### Create a MPICH-OpenFOAM container

Here we describe each of the steps needed for the creation/use of OpenFOAM containers at Pawsey:

* [I. First, create a MPICH-OpenFOAM container with Docker](./Documentation/Creation/CREATE_MPICH_OPENFOAM_CONTAINER_DOCKER.md)
* [II. Then, port your Docker container into Singularity and copy it into Pawsey](./Documentation/Creation/PORT_DOCKER_CONTAINER_TO_SINGULARITY.md)
* [III. Pull Pawsey's containers](./Documentation/Creation/PULL_PAWSEY_CONTAINERS.md) (under development)
* [IV. Compiling your own OpenFOAM solver](./Documentation/Creation/COMPILING_YOUR_OWN_SOLVER.md) (under development, may be very out of date)
* [V. Adding tools (like CFDEM-LIGGHTS or waves2FOAM) and produce a new container](./Documentation/Creation/ADDING_TOOLS_TO_NEW_IMAGE.md) (under development, may be very out of date)


### Running instructions

* [IV. Running a case **at your local linux host** with **Docker**](./Documentation/Usage/RunningLocalWithDocker.md) (under development)
* [V. Running a case **at your local linux host** with **Singularity**](./Documentation/Usage/RunningLocalWithSingularity.md)  (under development)
* [VI. Running a case **at Pawsey Supercomputers** with **Singularity**](./Documentation/Usage/RunningAtPawseyWithSingularity.md)  (under development)
* [VII. Running a case **at Pawsey Nimbus cloud service**](./Documentation/Usage/RunningAtNimbus.md) (under development)
* [(VIII.)(Additional) Comparing performance of Docker, Singularity and Singularity-Hybrid](./Documentation/Usage/ComparingPerformance.md) (under development)


### Some other comments
* [Some other comments](./Documentation/Creation/GeneralComments.md)


## Use of OpenFOAM containers at Nimbus (Pawsey's cloud)
OpenFOAM is much more easier to install in a linux Nimbus virtual machine than it is in a supercomputer. Therefore, installing your own version of OpenFOAM in Nimbus is a non-complicated task. Nevertheless, users may already count with an OpenFOAM container that works fine on Pawsey's Supercomputers (as most of this documentation talks about). Or even may want to run the native OpenFOAM developers' Docker containers as provided. All these three options are possible at Nimbus, but here we only describe the last two.


