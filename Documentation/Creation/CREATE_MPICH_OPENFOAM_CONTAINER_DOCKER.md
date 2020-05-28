# I. Create a MPICH-OpenFOAM container with Docker

As mentioned previously, we recommend to first use Docker for building the OpenFOAM container instead of using Singularity building tools. The reason for this is the practicality of the "layering" approach utilised in Docker build tool. This layering saves the different building steps defined in the Docker file into different layers. And when there is a need for modifying one intermediate step of the Dockerfile, all the previous steps are just recalled (not executed) for the rebuild, saving a lot of time. Once the building process has been checked for correctness, we then port the container into Singularity format to allow its execution at Pawsey's supercomputers.

## 0. Install Docker in your host machine

Building Docker containers require a proper Docker installation in your linux local system. For that we recommend to follow the instructions of the Docker website: [Docker](https://www.docker.com/).

## 1. Use of the Dockerfile for building a container

There is plenty of documentation about building docker containers from a Dockerfile. Please refer to this documentation to understand the process: [Reference Docker builder](https://docs.docker.com/engine/reference/builder/). Also refer to Pawsey's notes and workshops about containers.

### 1.1 Example Dockerfiles and their corresponding Docker images

Pawsey maintains a reduced number of OpenFOAM containers. Users can check the definition files utilised for its creation and use them as example and reference:

[https://github.com/PawseySC/pawsey-containers/tree/master/OpenFOAM](https://github.com/PawseySC/pawsey-containers/tree/master/OpenFOAM)

[https://hub.docker.com/r/pawsey/openfoam](https://hub.docker.com/r/pawsey/openfoam)



## 2. Start from a base container with MPI prepared by Pawsey

Pawsey provides tested base images that contain a version of MPI which is ABI compatible with CrayMPI and IntelMPI:

[https://hub.docker.com/r/pawsey/mpich-base](https://hub.docker.com/r/pawsey/mpich-base)

[https://github.com/PawseySC/pawsey-containers/tree/master/mpich-base](https://github.com/PawseySC/pawsey-containers/tree/master/mpich-base)

Containers built from these base images can run MPI applications in Pawsey supercomputers. The containers also has the OSU-benchmarks installed and have been built for different versions of ubuntu.

For example, in order to build the _pawsey/openfoam:7_ image, we used the base image with MPICH 3.1.4 and Ubuntu 18.04. After inspecting the corresponding Dockerfile you can read at the very beginning:

```Docker
FROM pawsey/mpich-base:3.1.4_ubuntu18.04
```

If for some reason, the existing base images does not fit to your needs (probably because of the flavour or version of the operating system of the container), then users can utilise the existing definition files as a guide to create their own base images.

## 3. Installing OpenFOAM within the container

This is not an easy process but, fortunately, there are several documentation resources from where to find a guide for installing OpenFOAM. 

Developers' resources for latest versions are: [OpenFOAM Foundation source](https://openfoam.org/download/source/), [OpenFOAM ESI source] (https://www.openfoam.com/download/install-source.php).

Developers' instructions for old versions of the Foundation's flavour are still available. You can find them by navigating from the release history page: [https://openfoam.org/download/history/](https://openfoam.org/download/history/) and, from there, reach the installation instructions. For example, for OpenFOAM-2.2.0 at: [https://openfoam.org/download/2-2-0-source/](https://openfoam.org/download/2-2-0-source/). It seems that official installation instructions for old versions of the ESI flavour are not available anymore.

And, instructions for current and old versions of all flavours, with fixes to the official instructions for different operating systems can be found at: [OpenFOAM wiki installation guides](https://openfoamwiki.net/index.php/Category:Installing_OpenFOAM_on_Linux).

In order to install OpenFOAM within the container, the steps described in the guides (with some small changes and additions) need to be set within the Dockerfile. Users are encouraged to use the existing Dockerfiles maintained by Pawsey as templates, where installation steps have been included and changes/additions have been documented.


### 3.1 Important installation settings

* **IMPORTANT: Do not install/use OpenMPI.** The new container should not install MPI (like OpenMPI) again. MPICH has already been provided from the base images described above. Then, any step that force the installation/usage of OpenMPI should be avoided/removed/modified in order to cancel the automatic/forced installation of OpenMPI.

* **IMPORTANT: Do not install OpenFOAM in the system directories.** Instead, we recommend to use "/opt/OpenFOAM" as the installation directory.

* **IMPORTANT: We are still recommending to create the user "ofuser"** inside the container (as in early versions of native developers' containers). We use "ofuser" to avoid the usage of "root" for basic interactive sessions. Also, the directory "/home/ofuser/OpenFOAM/ofuser-VERSION" is recommended as the target of the environmental variable "WM\_PROJECT\_USER\_DIR".

### 3.2 Best Practices
If possible, the recommended best practices to be used at Pawsey should be defined within the file **"$FOAM\_ETC/controlDict"**. Therefore, this file should be modified to add the following best practices.

###### From Foundation's OpenFOAM-6 and ESI's OpenFOAM-v1806 or newer

* **IMPORTANT: Define the -fileHandler collated** as default to avoid the creation of massive amounts of files in the shared file system.

### 3.4 Build

The building command is the following (We assume that your docker repository (username) is mickey and the version (tag) of the "openfoam" container is 7). Note that container names cannot have uppercase letters:

```Shell
localHost> docker build -t mickey/openfoam:7 .
```
Although, as the compilation takes a long time, it is recommended to build the container in the background and with the "no-hang-up" command. Also, it is very useful to save the output to a file:

```Shell
localHost> nohup docker build -t mickey/openfoam:7 > log.build.01 2>&1 &
```

(

Of course, for the images that pawsey maintain we have used the following command:

```Shell
localHost> nohup docker build -t pawsey/openfoam:7 > log.build.01 2>&1 &
```
)

If users want to use pawsey provided containers, they only need to use them directly from the repositories explained in the guide on how to [pull Pawsey's MPICH-OpenFOAM containers](../Creation/PULL_PAWSEY_CONTAINERS.md).

$
## 4. Testing correctnes of the Docker container

The final objective for OpenFOAM containers is to run in parallel using the host MPICH installed in Magnus or Zeus. For that we will need to port the container to Singularity. Unfortunately, as far as we know, Docker is still unable to run mpi applications using the host MPI installation, but still, we can test the Docker container using the internal MPICH. This will not test efficiency (as it is much more efficient to use the host installation, as will be shown later) but will test correctness.

To test the correctness of the installation, we use an interactive session with the following commands. We assume that your docker repository (username) is "mickey" and the version (tag) of the "openfoam" container is 7. (You could also test pawsey/openfoam:7  .). The case to be tested is "channel395":

###### 4.1 Run the container interactivelly

```shell
localHost> docker run -it --rm mickey/openfoam:7
ofuser@111c7333a814:~$ 
```

###### 4.2 Source the bashrc to set up OpenFOAM environment

```shell 
ofuser@111c7333a814:~$ source /opt/OpenFOAM/OpenFOAM-7/etc/bashrc
ofuser@111c7333a814:~$ echo $WM_MPLIB
SYSTEMMPI
ofuser@111c7333a814:~$ echo $WM_PROJECT_INST_DIR
/opt/OpenFOAM
ofuser@111c7333a814:~$ echo $FOAM_MPI
mpi-system          
ofuser@111c7333a814:~$ echo $FOAM_RUN
/home/ofuser/OpenFOAM/ofuser-7/run
```

###### 4.3 Execute a tutorial
```shell
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
All the results were generated properly, so everything seems to be working fine.

Note that for this Docker container, we still need to source the "/opt/OpenFOAM/OpenFOAM-7/etc/bashrc" file to set the OpenFOAM environment.

Be aware that after exiting the container, all the results will be lost. This is not a problem here because we are just testing the correct execution of a containerised solver with Docker. Furthermore, we still need to port the Docker container into Singularity for its usage at Pawsey.

If users are interested to use the Docker container itself for their own purposes, they will need to mount a directory in localHost in order to keep the results. For understanding the different options for running Docker containers we recommend to check the official [Docker run reference](https://docs.docker.com/engine/reference/run/), and also our instructions for [running a case at your local linux host with Docker](../Usage/RunningLocalWithMPICH.md). Users can also inspect the scripts that OpenFOAM developers have created for running their own native Docker containers, for example: [foundation scripts](http://dl.openfoam.org/docker/) or [esi scripts: installOpenFOAM & startOpenFOAM](https://sourceforge.net/projects/openfoam/files/v1912/). (By the way, developers' scripts include the sourcing of the bashrc file within the Docker command, so that the user does not need to explicitly source it when entering to the interactive session.)


## 5. Porting to Singularity

The first step to port our container into Singularity is to push it into DockerHub. After the container is available in the DockerHub, user can then port it into Singularity format.

### Push to DockerHub
To push the container into your repository just execute:

```Shell
localHost> docker push mickey/openfoam:7
```

### Porting to singularity

The final step of porting to Singularity is explained in the guide about: [ porting your Docker container into Singularity and copying it into Pawsey](../Creation/PORT_DOCKER_CONTAINER_TO_SINGULARITY.md).



---
Back to the [README.OpenFOAM](../../README.OpenFOAM.md)
