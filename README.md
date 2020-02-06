(This document is under development.)

# General Documentation

Here we provide some examples of how to build OpenFOAM containers that have been tested to run properly in Pawsey Supercomputers. Users are encouraged to use this document and the examples provided as a guide for building their own OpenFOAM containers.

In the directory "basicInstallations" examples of the Docker and Singularity definition files for building plain OpenFOAM containers are provided.

In the directory "installationsWithAdditionalTools" examples of the Docker and Singularity definition files for building OpenFOAM containers with additional tools are provided.

## Use of OpenFOAM containers at Pawsey's supercomputers
Installations of OpenFOAM are not easy to perform in supercomputers. There are always some details to be fixed/replaced from the typical installation instructions. Therefore, if the OpenFOAM version that you need is not available in our supercomputers, we strongly recommend to use an container with OpenFOAM on it.

Unfortunately, native OpenFOAM containers provided by the original developers of OpenFOAM cannot be used in Pawsey supercomputers. The main reason is that developers' containers have been compiled with OpenMPI, which is not Application Binary Interface (ABI) compatible with current MPI installations in Pawsey systems. At present, all Pawsey systems have installed at least one MPICH ABI compatible implementation: CrayMPICH on the Crays (Magnus and *Galaxy), IntelMPI on Zeus. Therefore, any container to be running MPI applications at Pawsey's supercomputers should be equipped with MPICH and tools (OpenFOAM in this case) compiled with its libraries.

On the other hand, the preferred container manager for Pawsey supercomputers is Singularity and containers need to be prepared for it. We recommend the following approach for developing/using OpenFOAM containers at Pawsey's supercomputers: (i) build a Docker OpenFOAM container from scratch compiled with MPICH, (ii) port the Docker container into a Singularity container and (iii) use Singularity to run your OpenFOAM container.

### Create a MPICH-OpenFOAM container

Here we describe each of the steps needed for the creation/use of OpenFOAM containers at Pawsey:

* [I. Create a MPICH-OpenFOAM container with Docker](./Documentation/ContainerCreation/I.CREATE_MPICH_OPENFOAM_CONTAINER_DOCKER.md)
* [II. Port your Docker container to Singularity](./Documentation/ContainerCreation/II.PORT_DOCKER_CONTAINER_TO_SINGULARITY.md)
* [III. Hardcoding environmental variables for Shifter containers to run at Pawsey (Old documentation, not maintained anymore)](./Documentation/ContainerCreation/III.HARDCODING_ENVIRONMENTAL_VARIABLES.md)

### Running instructions

* [1. Running a case **at your local linux host (or Nimbus)** with **docker**](./Documentation/ContainerUsage/01_RunningACaseWithDocker.md)
* [2. Running a case **at Pawsey supercomputers** with **singularity**](./Documentation/ContainerUsage/02_RunningACaseAtPawseyWithSingularity.md)
* [3. (Running a case **at Pawsey** with **shifter**) (Old documentation, not maintained anymore)](./Documentation/ContainerUsage/03_RunningACaseAtPawseyWithShifter.md)

### OpenFOAM containers equipped with your own solver

* [4. Compiling your own OpenFOAM solver](./Documentation/ContainerUsage/04_CompilingYourOwnSolver.md) (under development)

### OpenFOAM containers equipped with additional tools

Installing VTK, CFDEM and LIGGGTHS:

* [III.Adding tools to a new Image](./Documentation/ContainerCreation/III.ADDING_TOOLS_TO_NEW_IMAGE.md)( under development)

Installing waves2Foam:

* [IV. Installing and testing waves2Foam](./Documentation/ContainerCreation/IV.ADDING_WAVES2FOAM.md) (under development) 

### Some other comments
* [Some other comments](./Documentation/ContainerCreation/GeneralComments.md) (under development)

## OpenFOAM containers
All the OpenFOAM subdirectories at the root of this repository have a Dockerfile used to create an OpenFOAM container image that works properly in Pawsey supercomputers. The corresponding image would exist in the DockerHub repo account: **alexisespinosa**.

As mentioned above, the container images built from these Dockerfiles are archived in DockerHub. For example, the folder **openfoam-v1812** corresponds to the dockerHub image **alexisespinosa/openfoam:v1812**. And the command to pull the image from the DockerHub would be:

```shell
localShell:$ theRepo=alexisespinosa
localShell:$ theContainer=openfoam
localShell:$ theTag=v1812
localShell:$ docker pull $theRepo/$theContainer:$theTag
```

There are some other subdirectories in this repository:

- very_old
- on_development

The folder "on_development" may contain non-finished work (if the container image does not exist in the DockerHub, then that means that the Dockerfile is still not functional).

## Use of OpenFOAM containers at Nimbus (Pawsey's cloud)
OpenFOAM is much more easier to install in a linux Nimbus virtual machine than it is in a supercomputer. Therefore, installing your own version of OpenFOAM is a non-complicated task. Nevertheless, users may already count with a working OpenFOAM container. For example, users may already count with an OpenFOAM container with MPICH that was prepared to run at Pawsey's supercomputers (as described above). Or even may want to run the native OpenFOAM developers' Docker containers with OpenMPI. All these three options are possible at Nimbus, but here we only describe the last two.


