# I. CREATE AN OpenFOAM CONTAINER

These instructions are under development, but please use the example Dockerfiles within this repository to have an idea of what to do.

There are two main complications. The first is that for an mpi tool to work properly in Pawsey systems, the container needs to have installed mpich (NOT openmpi or other). The second complication is that the container manager "shifter" can't source the bashrc file in the entry point. Then, the whole list of environmental variables that this configuration file sets for openfoam needs to be set from the creation of the container. For the explanation on how to hardcode the environmental variables read [II. Hardcoding environmental variables](./Documentation/ContainerCreation/II.HARDCODING_ENVIRONMENTAL_VARIABLES.md)

---
Back to the [README](../../README.md)
