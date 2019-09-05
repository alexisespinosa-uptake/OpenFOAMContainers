(This document is under development.)

## OpenFOAM containers
All the OpenFOAM folders in this repo have the Dockerfile used to create an OpenFOAM container image that works properly in Pawsey supercomputers. The corresponding image would exist in the DockerHub repo account: **alexisespinosa**.

There are for main directories in this repository:

- latest
- previous
- very_old
- on_development

All of them contain folders that keep the Dockerfiles used to build the container specified by its name. All of them are functional, but the directory "latest" keeps what we consider the latest "Best Practise" up-to-date for the definition of a Dockefile. The other directories have Dockerfiles that have not been converted to the latest best practices, but which created functional containers. (These Dockerfiles and the corresponding containers will be updated to the latest best practices bit by bit). The folder "on_development" may contain non-finished work (if the container image does not exist in the DockerHub, then that means that the Dockerfile is still not functional).

As mentioned above, the container images built from these Dockerfiles are archived in DockerHub. For example, the folder **openfoam-v1812** corresponds to the dockerHub image **alexisespinosa/openfoam:v1812**. And the command to pull the image from the DockerHub would be:

```shell
localShell:$ theRepo=alexisespinosa
localShell:$ theContainer=openfoam
localShell:$ theTag=v1812
localShell:$ docker pull $theRepo/$theContainer:$theTag
```



## General Documentation
Several instructions for the use of containers are available:

* [1. Running a case with docker in your local host](./Documentation/ContainerUsage/01_RunningACaseWithDocker.md)
* [2. Running a case at Pawsey with **shifter**](./Documentation/ContainerUsage/02_RunningACaseAtPawseyWithShifter.md)
* [3. Compiling your own OpenFOAM solver](./Documentation/ContainerUsage/03_CompilingYourOwnSolver.md) (under development)


Several instructions for the creation of containers are available:

* [I. Create an openfoam container](./Documentation/ContainerCreation/I.CREATE_OPENFOAM_CONTAINER.md) (under development)
* [II. Hardcoding environmental variables](./Documentation/ContainerCreation/II.HARDCODING_ENVIRONMENTAL_VARIABLES.md)
* [III.Adding tools to a new Image](./Documentation/ContainerCreation/III.ADDING_TOOLS_TO_NEW_IMAGE.md)(under development)
* [Some other comments](./Documentation/ContainerCreation/GeneralComments.md) (under development)
