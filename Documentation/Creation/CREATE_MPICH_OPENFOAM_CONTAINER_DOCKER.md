# I. Create a MPICH-OpenFOAM container with Docker

As mentioned previously, we are recommending to use Docker for building the MPICH-OpenFOAM container instead of using Singularity building tools from the very beginning. The reason for this is the "layering" approach utilized in Docker build tool. This layering keeps saved the different building steps defined in the Docker file into different layers. And when there is a need for modifying one of the steps of the Dockerfile for a new building, the previous steps are just recalled (not executed) for the rebuild (saving a lot of time). On the other hand, Singularity executes the whole definition file every time a rebuild is needed.

## 0. Install Docker in your host machine

Building Docker containers require a proper Docker installation in your linux local system. For that we recommend to follow the instructions of the Docker website: [Docker](https://www.docker.com/).

## 1. Use of the Dockerfile for building a container

There is plenty of documentation about building docker containers from a Dockerfile. Please refer to this documentation to understand the process: [Reference Docker builder](https://docs.docker.com/engine/reference/builder/).


## 2. Installing MPICH within the container

Pawsey provides a tested base image that contains an ABI compatible version of MPICH: [mpi-base](https://hub.docker.com/r/pawsey/mpi-base). Containers built from this base can run mpi applications in Pawsey supercomputers. The container also has the OSU-benchmarks installed and has been build from ubuntu:18.04.

In order to build a container from [mpi-base](https://hub.docker.com/r/pawsey/mpi-base), the Dockerfile of the new container should contain:

```Docker
FROM pawsey/mpi-base:latest
```

If for some reason, ubuntu 18.04 is not wanted for the creation of the new OpenFOAM container, then MPICH installation need to be explicitly defined within the new Dockerfile. For that, users should start from another version of ubuntu (or even another version of linux) but can still follow (copy/paste) the steps in the [MPICH Dockerfile](https://github.com/PawseySC/pawsey-dockerfiles/blob/master/mpi-base/Dockerfile) used for the creation of mpi-base.

## 3. Installing OpenFOAM within the container

This is not an easy process for newbies but, fortunately, there are several documentation resources from where to find a guide for installing OpenFOAM. The main resources we recommend to read are: [OpenFOAM Foundation source](https://openfoam.org/download/source/), [OpenFOAM ESI source] (https://www.openfoam.com/download/install-source.php), and [OpenFOAM wiki installation guides](https://openfoamwiki.net/index.php/Category:Installing_OpenFOAM_on_Linux).

What the user needs to do is to define all the configuration/compilation steps obtained from the resources mentioned in the previous paragraph within the Dockerfile. These steps should be defined below the MPICH steps described above.

**IMPORTANT: Do not install/use OpenMPI.** The new container should not use OpenMPI but the MPICH. Then, any step that involves the installation/usage of OpenMPI should be removed/modified in order to cancel the installation of OpenMPI and then use MPICH.

**IMPORTANT: Do not install OpenFOAM in the system directories.** Instead, we recommend to use "/opt/OpenFOAM"

**IMPORTANT: We are still recommending to create the user "ofuser"** inside the container (as in early versions of native developers' containers). We use it so that its "/home/ofuser/OpenFOAM/ofuser-VERSION" directory can be used as the target of the environmental variable "WM\_PROJECT\_USER\_DIR". And, also, to avoid the usage of root as the user of basic interactive sessions.

**IMPORTANT: Define the -fileHandler collated as default**. Ad this application is intended to run in Pawsey, in order to avoid the creation of massive amounts of files in the shared file system, the collated option should be used by default. (Default options are defined within $FOAM\_ETC/controlDict)

Examples of Dockerfiles used for the creation of MPICH-OpenFOAM containers tested to run correctly in Magnus and Zeus are available at: [Pawsey OpenFOAM containers git](https://github.com/alexisespinosa-uptake/OpenFOAMContainers). Inside the Dockerfiles there is some additional explanation of the reasoning of the steps included.

The building command is the following (We assume that your docker repository (username) is mickey and the version (tag) of the "openfoam" container is 7). Note that container names cannot have uppercase letters:

```Docker
localHost> docker build -t mickey/openfoam:7 .
```
Although, as the compilation takes a long time, it is recommended to build the container in the background and with the "no-hang-up" command. Also, it is very useful to save the output to a file:

```Docker
localHost> nohup docker build -t mickey/openfoam:7 > log.build.01 2>&1 &
```
(Of course, we have used "-t pawsey/openfoam:7" to build our own tested container which is ready to be used. If users want to use pawsey provided containers, they only need to use them directly from the repositories explained at the end of this document).

$
## 4. Testing correctnes of the Docker container

The final objective for OpenFOAM containers is to run in parallel using the host MPICH installed in Magnus or Zeus. For that we will need to port the container to Singularity. Unfortunately, as far as we know, Docker is still unable to run mpi applications using the host MPI installation, but still, we can test the Docker container using the internal MPICH. This will not test efficiency (as it is much more efficient to use the host installation, as will be shown later) but will test correctness.

To test the correctness of the installation, we use an interactive session with the following commands. We assume that your docker repository (username) is "mickey" and the version (tag) of the "openfoam" container is 7. (You could also test pawsey/openfoam:7  .). The case to be tested is "channel395":

```shell
localHost> docker run -it --rm mickey/openfoam:7

ofuser@111c7333a814:~$ source /opt/OpenFOAM/OpenFOAM-7/etc/bashrc            
ofuser@111c7333a814:~$ echo $FOAM_RUN
/home/ofuser/OpenFOAM/ofuser-7/run
ofuser@111c7333a814:~$ mkdir -p $FOAM_RUN
ofuser@111c7333a814:~$ cd $FOAM_RUN
ofuser@111c7333a814:~/OpenFOAM/ofuser-7/run$ find $FOAM_TUTORIALS -type d -name "*channel*"
/opt/OpenFOAM/OpenFOAM-7/tutorials/incompressible/pimpleFoam/LES/channel395
ofuser@111c7333a814:~/OpenFOAM/ofuser-7/run$ cp -r /opt/OpenFOAM/OpenFOAM-7/tutorials/incompressible/pimpleFoam/LES/channel395 .
ofuser@111c7333a814:~/OpenFOAM/ofuser-7/run$ ls
channel395
ofuser@111c7333a814:~/OpenFOAM/ofuser-7/run$ cd channel395/
ofuser@111c7333a814:~/OpenFOAM/ofuser-7/run/channel395$ ls
0  0.orig  Allrun  constant  system
ofuser@111c7333a814:~/OpenFOAM/ofuser-7/run/channel395$ ./Allrun
Running blockMesh on /home/ofuser/OpenFOAM/ofuser-7/run/channel395
Running decomposePar on /home/ofuser/OpenFOAM/ofuser-7/run/channel395
Running pimpleFoam in parallel on /home/ofuser/OpenFOAM/ofuser-7/run/channel395 using 4 processes
Running reconstructPar on /home/ofuser/OpenFOAM/ofuser-7/run/channel395
Running postChannel on /home/ofuser/OpenFOAM/ofuser-7/run/channel395
ofuser@1b1b768267df:~/OpenFOAM/ofuser-7/run/channel395$ 
ofuser@1b1b768267df:~/OpenFOAM/ofuser-7/run/channel395$ ls
0       120  240  360  440  560  680  80   880  Allrun         log.decomposePar  log.reconstructPar  system
0.orig  160  280  40   480  600  720  800  920  constant       log.pimpleFoam    postProcessing
1000    200  320  400  520  640  760  840  960  log.blockMesh  log.postChannel   processors4
ofuser@1b1b768267df:~/OpenFOAM/ofuser-7/run/channel395$ exit
exit

localHost>
```
As all the results are there, then everything seems to be running correctly.

Note that for using OpenFOAM environment, we still need to source the "/opt/OpenFOAM/OpenFOAM-7/etc/bashrc" file.

Be aware that after exiting the container, all the results are lost. This is not a problem here as we were just testing the correct execution of the pimpleFoam solver and other tools needed for the "channel395" case.

Several other ways of launching an interactive session are available (specially the use of mounting of directories of the localHost in order to be able to write the results to the disk of the localHost). For understanding different options for running Docker containers we recommend the user to check the official [Docker run reference](https://docs.docker.com/engine/reference/run/), and also our instructions for [running a case at your local linux host with Docker](./Documentation/ContainerUsage/RunningLocalWithDocker.md).

We also strongly recommend users to inspect the scripts that OpenFOAM developers have created for running their own native containers, for example: [foundation scripts](http://dl.openfoam.org/docker/) or [esi scripts: installOpenFOAM & startOpenFOAM](https://sourceforge.net/projects/openfoam/files/v1912/). (By the way, developers' scripts include the sourcing of the bashrc file within the Docker command, so that the user does not need to explicitly source it when entering to the interactive session.)



## 5. Porting to Singularity

First step to port to Singularity for the usage of the container at Pawsey is to push the container into DockerHub

### Push to DockerHub
To push the container into your repository just execute:

```Docker
localHost> docker push mickey/openfoam:7
```

### Porting to singularity

This is explained [here](II.PORT_DOCKER_CONTAINER_TO_SINGULARITY.md)



---
Back to the [README](../../README.md)
