# Downloading (pulling) Pawsey's containers
## OpenFOAM containers
All the OpenFOAM subdirectories inside the "basicInstallations" or "installationsWithAdditionalTools" folders contain a Dockerfile used to create the Docker OpenFOAM container image and a "Singularity.XX.def" file used to port the container into a Singularity image that works properly in Pawsey supercomputers. The corresponding images would exist in the DockerHub repo account: **alexisespinosa** and in the Sylab account **Pawsey**.

As mentioned above, the container images built from these Dockerfiles are archived in DockerHub. For example, the folder **basicInstallations/openfoam-7** corresponds to the dockerHub image **alexisespinosa/openfoam:7**. And the command to pull the image from the DockerHub would be:

```shell
localShell:$ theRepo=alexisespinosa
localShell:$ theContainer=openfoam
localShell:$ theTag=7
localShell:$ docker pull $theRepo/$theContainer:$theTag