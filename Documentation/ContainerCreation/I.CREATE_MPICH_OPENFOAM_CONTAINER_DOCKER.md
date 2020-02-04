# I. Create a MPICH-OpenFOAM container with Docker

As mentioned previously, we are recommending to use Docker for building the MPICH-OpenFOAM container instead of using Singularity building tools from the very beginning. The reason for this is the "layering" approach utilized in Docker build tool. This layering keeps saved the different building steps defined in the Docker file into different layers. And when there is a need for modifying one of the steps of the Dockerfile for a new building, the previous steps are just recalled (not executed) for the rebuild (saving a lot of time). On the other hand, Singularity executes the whole definition file every time a rebuild is needed.

## Use of the Dockerfile for building a container

There is plenty of documentation about building docker containers from a Dockerfile. Please refer to this documentation to understand the process: [Reference Docker builder](https://docs.docker.com/engine/reference/builder/).


## Installing MPICH within the container

Pawsey provides a tested base image that contains an ABI compatible version of MPICH: [mpi-base](https://hub.docker.com/r/pawsey/mpi-base). Containers built from this base can run mpi applications in Pawsey supercomputers. The container also has the OSU-benchmarks installed and has been build from ubuntu:18.04.

In order to build a container from [mpi-base](https://hub.docker.com/r/pawsey/mpi-base), the Dockerfile of the new container should contain:

```Docker
FROM pawsey/mpi-base:latest
```

If for some reason, ubuntu 18.04 is not wanted for the creation of the new OpenFOAM container, then MPICH installation need to be explicitly defined within the new Dockerfile. For that, users should start from another version of ubuntu (or even another version of linux) but can still follow (copy/paste) the steps in the [MPICH Dockerfile](https://github.com/PawseySC/pawsey-dockerfiles/blob/master/mpi-base/Dockerfile) used for the creation of mpi-base.

For the installation of MPICH, users can build their OpenFOAM container from the provided mpi-base container here:

In the case that a different version of Ubuntu is needed, then the user should include all the MPICH installation steps

There are two main complications. The first is that for an mpi tool to work properly in Pawsey systems, the container needs to have installed mpich (NOT openmpi or other). The second complication is that the container manager "shifter" can't source the bashrc file in the entry point. Then, the whole list of environmental variables that this configuration file sets for openfoam needs to be set from the creation of the container. For the explanation on how to hardcode the environmental variables read [II. Hardcoding environmental variables](./Documentation/ContainerCreation/II.HARDCODING_ENVIRONMENTAL_VARIABLES.md)

---
Back to the [README](../../README.md)
