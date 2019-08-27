This document is under development.

## OpenFOAM containers
All the OpenFOAM folders in this repo have the Dockerfile used to create an image that will work in Pawsey supercomputers. The corresponding image would exist in the DockerHub repo for the account:

```
alexisespinosa
```
Therefore, for example, for pulling the openfoam:v1812 image, the docker command would be:

```shell
localShell:$ theRepo=alexisespinosa
localShell:$ theContainer=openfoam
localShell:$ theTag=4.0
localShell:$ docker pull $theRepo/$theContainer:$theTag
```


## General Documentation
Several instructions for the use of containers are available:

* [01_RunningACaseWithDocker](./Documentation/ContainerUsage/01_RunningACaseWithDocker.md)
* [02_RunningACaseAtPawseyWithShifter](./Documentation/ContainerUsage/02_RunningACaseAtPawseyWithShifter.md)
* [03_CompilingYourOwnSolver](./Documentation/ContainerUsage/03_CompilingYourOwnSolver.md)(under development)


Several instructions for the creation of containers are available:

* [I. Create an openfoam container](./Documentation/ContainerCreation/I.CREATE_OPENFOAM_CONTAINER.md) (under development)
* [II. Hardcoding environmental variables](./Documentation/ContainerCreation/II.HARDCODING_ENVIRONMENTAL_VARIABLES.md)
* [III.Adding tools to a new Image](./Documentation/ContainerCreation/III.ADDING_TOOLS_TO_NEW_IMAGE.md)(under development)
* [Some other comments](./Documentation/ContainerCreation/GeneralComments.md) (under development)
