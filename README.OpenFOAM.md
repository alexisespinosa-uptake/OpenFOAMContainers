(This document is under development.)

# General Documentation

Here we provide some examples on how to build OpenFOAM containers that have been tested to run properly in Pawsey Supercomputers. Users are encouraged to use this document and the examples provided as a guide for building their own OpenFOAM containers.

The following directories contain:

* **basicInstallations**: examples of the Docker and Singularity definition files for building plain OpenFOAM containers are provided.
* **installationsWithAdditionalTools**: examples of the Docker and Singularity definition files for building-in additional tools on top of the basic OpenFOAM containers.
*  **Documentation**: several \*.md files describing steps for container creation and usage (linked from this document too).

## OpenFOAM containers at Pawsey's supercomputers

Unfortunately, native OpenFOAM containers provided by the original developers of OpenFOAM cannot be used in Pawsey supercomputers. The main reason is that developers' containers have been compiled with OpenMPI, which is not Application Binary Interface (ABI) compatible with CRAY's MPI. At present, all Pawsey systems have installed at least one MPICH ABI compatible implementation: CrayMPICH on the Crays (Magnus and *Galaxy) and IntelMPI on Zeus. With the aid of the Singularity container manager, images equipped with MPICH (and tools, like OpenFOAM, compiled with it) **can be used** on any of Pawsey's supercomputers.

### Usage of OpenFOAM containers at Pawsey

Please refer to our documentation for instructions for on how to use OpenFOAM containers at Pawsey with Singularity:
[Pawsey's Documentation: OpenFOAM](https://support.pawsey.org.au/documentation/display/US/OpenFOAM)

### Creation of a new OpenFOAM containers to be executed at Pawsey

A reduced number of OpenFOAM containers with different versions have already been built and are maintained by Pawsey. This repository contains the files utilised for their creation. User's are encouraged to check this repository and our documentation (see above) before staring their own building process.

If users still need to build their own container, we recommend to use the following approach for develop/build OpenFOAM containers for Pawsey's supercomputers. First create a Docker container, then port it into Singularity format:

* [I. Create the OpenFOAM container with Docker](./Documentation/Creation/CREATE_MPICH_OPENFOAM_CONTAINER_DOCKER.md)
* [II. Port your Docker container into Singularity](./Documentation/Creation/PORT_DOCKER_CONTAINER_TO_SINGULARITY.md)
* [A. Some other building hints](./Documentation/Creation/SOME_OTHER_BUILDING_HINTS.md)

{{{
Or, you can pull the containers already created and mantained by Pawsey:

* [XXX. Pull Pawsey's MPICH-OpenFOAM containers](./Documentation/Creation/PULL_PAWSEY_CONTAINERS.md)
}}}

Users can also expand the standard OpenFOAM containerised installations by compiling their own solver or adding tools:

* [III. Compiling your own OpenFOAM solver](./Documentation/Usage/COMPILING_YOUR_OWN_SOLVER.md) (under development, may be very out of date)
* [IV. Adding tools (like CFDEM-LIGGHTS or waves2FOAM) and produce a new container](./Documentation/Creation/ADDING_TOOLS_TO_NEW_IMAGE.md) (under development, may be very out of date)



### Running instructions

* [VII. Running MPICH-OpenFOAM containers **at Pawsey Supercomputers** with **Singularity**](./Documentation/Usage/RunningAtPawseyWithSingularity.md)
* [VIII. Using overlayfs to reduce the number of files](./Documentation/Usage/OverlayFS.md)

## Use of OpenFOAM containers at Pawsey's Nimbus Cloud Service (or your local linux desktop)
OpenFOAM is much more easier to install in a linux Nimbus virtual machine (or in your local linux desktop) than it is in a supercomputer. Therefore, installing and using your own version of OpenFOAM in Nimbus is a non-complicated task. 

Nevertheless, users may already count with a MPICH-OpenFOAM container that works fine on Pawsey's Supercomputers (as most of this documentation talks about). Or even may want to run the native OpenFOAM developers' Docker containers they provide.

All these three options are possible at Nimbus (or in your local linux desktop). Here we provide some instructions for the last two options, and also compare the performance between running with Docker, Singularity and Singularity-HibridMode:

* [IX. Executing (and testing performance) of MPICH-OpenFOAM containers **at Nimbus cloud service** (or your local linux desktop)](./Documentation/Usage/RunningLocalWithMPICH.md)
* [{X. Additional} Executing (and testing performance) of Foundation's and ESI's native OpenMPI-OpenFOAM containers **at Nimbus cloud service** (or your local linux desktop)](./Documentation/Usage/RunningLocalFoundationOrESI.md)






