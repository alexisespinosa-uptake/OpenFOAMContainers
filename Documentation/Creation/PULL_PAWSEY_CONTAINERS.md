# Downloading (pulling) Pawsey's containers

## OpenFOAM Docker containers maintained by Pawsey
**Remember that Docker images cannot run in Pawsey Supercomputers.** The only container engine (and images) that can be used at Pawsey is Singularity. Nevertheless, we use Docker to create the initial containers with a Dockerfile and, as a second step, we port the images to Singularity. (Anyway, users are free to use these Docker images anywhere Docker is functional, for example in their own desktop or Nimbus VM; although we recommend to install and use Singularity to improve performance.)

All the OpenFOAM subdirectories inside the "basicInstallations" or "installationsWithAdditionalTools" folders contain a Dockerfile used to create the Docker OpenFOAM container image. The corresponding images exist in the DockerHub repo account: **alexisespinosa**.

For example, the folder **basicInstallations/openfoam-7** corresponds to the DockerHub image **alexisespinosa/openfoam:7**. And the command to pull the image from the DockerHub would be:

```shell
localShell:$ theRepo=alexisespinosa
localShell:$ theContainer=openfoam
localShell:$ theTag=7
localShell:$ docker pull $theRepo/$theContainer:$theTag
```

## OpenFOAM Singularity containers maintained by Pawsey
All the OpenFOAM subdirectories inside the "basicInstallations" or "installationsWithAdditionalTools" folders contain a "Singularity.XX.def" definition file used to port the container from Docker into a Singularity. The corresponding images exist in the Sylabs library **Pawsey**.

Instructions for pulling these images will soon be available.

