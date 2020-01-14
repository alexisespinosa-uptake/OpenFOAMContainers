(This document is under development.)

## OpenFOAM containers
All the OpenFOAM folders in this repo have the Dockerfile used to create an OpenFOAM container image that works properly in Pawsey supercomputers. The corresponding image would exist in the DockerHub repo account: **alexisespinosa**.

As mentioned above, the container images built from these Dockerfiles are archived in DockerHub. For example, the folder **openfoam-v1812** corresponds to the dockerHub image **alexisespinosa/openfoam:v1812**. And the command to pull the image from the DockerHub would be:

```shell
localShell:$ theRepo=alexisespinosa
localShell:$ theContainer=openfoam
localShell:$ theTag=v1812
localShell:$ docker pull $theRepo/$theContainer:$theTag
```

There are some other directories in this repository:

- very_old
- on_development

The folder "on_development" may contain non-finished work (if the container image does not exist in the DockerHub, then that means that the Dockerfile is still not functional).


## General Documentation
Several instructions for the use of containers are available.

### Basic OpenFOAM containers

Running instructions

* [1. Running a case **at your local host** with **docker**](./Documentation/ContainerUsage/01_RunningACaseWithDocker.md)
* [2. Running a case **at Pawsey** with **shifter**](./Documentation/ContainerUsage/02_RunningACaseAtPawseyWithShifter.md)

Creation instructions:

* [I. Create an openfoam container](./Documentation/ContainerCreation/I.CREATE_OPENFOAM_CONTAINER.md) (under development)
* [II. Hardcoding environmental variables](./Documentation/ContainerCreation/II.HARDCODING_ENVIRONMENTAL_VARIABLES.md)

### OpenFOAM containers equipped with your own solver

* [3. Compiling your own OpenFOAM solver](./Documentation/ContainerUsage/03_CompilingYourOwnSolver.md) (under development)

### OpenFOAM containers equipped with additional tools

Installing VTK, CFDEM and LIGGGTHS:

* [III.Adding tools to a new Image](./Documentation/ContainerCreation/III.ADDING_TOOLS_TO_NEW_IMAGE.md)( under development)

Installing waves2Foam:

* [IV. Installing and testing waves2Foam](./Documentation/ContainerCreation/IV.ADDING_WAVES2FOAM.md) (under development) 

### Some other comments
* [Some other comments](./Documentation/ContainerCreation/GeneralComments.md) (under development)