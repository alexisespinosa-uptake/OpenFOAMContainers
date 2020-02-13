# Downloading (pulling) Pawsey's containers

## OpenFOAM Singularity containers maintained by Pawsey

All the MPICH-OpenFOAM Singularity images maintained by Pawsey are available in Pawsey's File System. The general repository is the following directory:

```shell
/group/singularity/pawseyRepository
```
And the specific repository for MPICH-OpenFOAM containers is:

```shell
/group/singularity/pawseyRepository/OpenFOAM
```
Users can list the containers available:

```
user@zeus-1:~> theRepo=/group/singularity/pawseyRepository/OpenFOAM
user@zeus-1:~> ls $theRepo
openfoam-5.x_CFDEM-pawsey.sif  openfoam-5.x-pawsey.sif  openfoam-7-pawsey.sif  openfoam-v1912-pawsey.sif
```
(The content listed here may be out of date.)

Please refer to the guide: [Running MPICH-OpenFOAM containers **at Pawsey Supercomputers** with **Singularity**](../Usage/RunningAtPawseyWithSingularity.md) for a detailed explanation on how to use the containers at Pawsey Supercomputers.

All the OpenFOAM subdirectories inside the "basicInstallations" or "installationsWithAdditionalTools" folders of the GIT repository contain a _"Singularity.pawsey.def"_ definition file used to port the container from Docker into a Singularity. The corresponding images exist in the Sylabs library **XX**. (Instructions for pulling these images directly from Sylabs will soon be available.)

## OpenFOAM Docker containers maintained by Pawsey
**Remember that Docker images cannot run in Pawsey Supercomputers.** They can only run in a Nimbus VM or in your local linux desktop. The only container engine (and images) that can be used at Pawsey Supercomputers is Singularity.

Nevertheless, we use Docker to create the initial containers with a Dockerfile and, in a second step, we port the images to Singularity. Anyway, users are free to use these Docker images wherever Docker is functional, for example, in their own desktop or Nimbus VM. Although we recommend to install and use Singularity and the Singularity images in order to improve performance. (Read the guide: [Comparing performance of Docker, Singularity and Singularity-HybridMode in a linux desktop or VM](../Usage/ComparingPerformance.md).)

All the OpenFOAM subdirectories inside the "basicInstallations" or "installationsWithAdditionalTools" folders in the GIT repository contain a Dockerfile used to create the Docker OpenFOAM container image (which was then used to create the Singularity image in a second step). The corresponding images exist in the DockerHub repo account: **X**.

For example, the folder **basicInstallations/openfoam-7** in the GIT repository corresponds to the DockerHub image **X/openfoam:7**. And the command to pull the image from the DockerHub would be:

```shell
localShell:$ theDockerRepo=X
localShell:$ theContainer=openfoam
localShell:$ theTag=7
localShell:$ docker pull $theDockerRepo/$theContainer:$theTag
```





---
Back to the [README](../../README.md)