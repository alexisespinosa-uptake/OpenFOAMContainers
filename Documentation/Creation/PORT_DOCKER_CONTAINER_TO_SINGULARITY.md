# II. Porting the Docker MPICH-OpenFOAM container into Singularity

## 0. Installation of Singularity in your personal computer

For the developing and maintenance of OpenFOAM containers, we recommend you have an installation of Singularity in your local host. (Currently, we are using v3.5.2). For installing Singularity in your own computer, you can follow the official documentation of [Sylabs](https://sylabs.io/).

## 1. Porting the Docker container into Singularity

General porting rules of any Docker container into Singularity are explained in the Singularity documentation: [Singularity-&-Docker documentation](https://sylabs.io/guides/3.5/user-guide/singularity_and_docker.html#). And also in the [Pawsey documentation of Singularity](https://support.pawsey.org.au/documentation/display/US/Singularity).

Nevertheless, the recommended procedure for OpenFOAM containers will be explained here because we'll use some specific recommendations. In particular, in the Singularity definition file, we indicate to source the OpenFOAM environment definition file "bashrc" every time the container is executed. This is important, because this avoids the need to source the bashrc file when in an interactive session is required. But more importantly, because this allows OpenFOAM MPI applications to recognise the environmental variables correctly when ran in the so called **"hybrid mode"** (that is, when MPI tasks are spawned from the host computer and not within the container itself). Otherwise, the environmental variables would have to be defined one by one within the Dockerfile or the Singularity definition file, as was the case for older container managers. (The hybrid mode is used for executing any MPI containerised application at Pawsey, as explained in the [Pawsey documentation of Singularity](https://support.pawsey.org.au/documentation/display/US/Singularity).)

The procedure for porting the OpenFOAM Docker container into Singularity is simple. First, you need to create a Singularity definition file that indicates the use of the already existing Docker container. Secondly, this definition file should also indicate the sourcing of the OpenFOAM "bashrc" file to set the environment. So, the definition file ("Singularity.openfoam.def") should contain:

```Singularity
Bootstrap: docker
From: mickey/openfoam:7

%post
/bin/mv /bin/sh /bin/sh.original
/bin/ln -s /bin/bash /bin/sh
echo ". /opt/OpenFOAM/OpenFOAM-7/etc/bashrc" >> $SINGULARITY_ENVIRONMENT
```
The meaning of the commands can be examined in the [Sylabs documentation](https://sylabs.io/). But, basically, the first two lines are indicating that the new Singularity container will be constructed from a Docker container and the name that the container has in the DockerHub repository. (Here we are considering that your docker repository (username in Dockerhub) is "mickey", the name is "openfoam" and the version (tag) is 7).

The commands in the "%post" section are not that intuitive. But the steps are the following: first, the shell definition "/bin/sh" is backed up to "bin/sh/original"; second, a new link with the name "/bin/sh" is now pointing to "bin/bash"; and third, the line ". /opt/OpenFOAM/OpenFOAM-7/etc/bashrc" is added to the file accessed through the variable SINGULARITY_ENVIRONMENT. The third command allows to define environmental variables by sourcing a definition script (bashrc in this case). This is explained in the Singularity documentation [environment & metadata](https://sylabs.io/guides/3.5/user-guide/environment_and_metadata.html). The first two commands are used to change the /bin/sh symlink to /bin/bash instead of the default /bin/dash, as explained here: [github issue 3838](https://github.com/sylabs/singularity/issues/3838).


Finally, the command to perform the build is:

```bash
localHost> export myRepository=/singularity/myRepository
localHost> sudo singularity build $myRepository/openfoam-7-mickey.sif Singularity.openfoam.def
```
This will create the singularity image:
```bash
/singularity/myRepository/openfoam-7-mickey.sif
```
Obviously, images can be placed and named wherever the user wants. We recommend to collect them into a single directory that the user can manage as a repository.

## 2. Correctness test of the Singularity image

The test for the singularity image is similar to the test we performed for the Docker container. But with some small differences. The first difference is that the singularity container is now not able to write anything into the directory tree that already exists within the container. Therefore, we won't be able to copy the tutorial case to "/home/ofuser/OpenFOAM/ofuser-7". But that is not a problem, as Singularity allows to keep using the local disk and directories and there is where we are going to copy the tutorial case. At the end, this is more useful as the results will be kept intact after exiting the container.

The second difference is that the default user in the interactive session of the container is not "ofuser" but the original user in the local host. Again, this is not a problem. Indeed, both differences are more a desirable advantage over the default basic behaviour of Docker.

Then, to test the image with singularity, execute the following commands:

```bash
localHost> singularity shell $myRepository/OpenFOAM/openfoam-7-mickey.sif 

Singularity> mkdir run
Singularity> cd run
Singularity> find $FOAM_TUTORIALS -type d -name "*channel*"
/opt/OpenFOAM/OpenFOAM-7/tutorials/incompressible/pimpleFoam/LES/channel395
Singularity> cp -r /opt/OpenFOAM/OpenFOAM-7/tutorials/incompressible/pimpleFoam/LES/channel395 .
Singularity> ls
channel395
Singularity> cd channel395/
Singularity> ls
0  0.orig  Allrun  constant  system
Singularity> ./Allrun
Running blockMesh on /vol2/ubuntu/containers/OpenFOAM-Pawsey-Containers/openfoam-7/02_PortingToSingularity/localDisk/run/channel395
Running decomposePar on /vol2/ubuntu/containers/OpenFOAM-Pawsey-Containers/openfoam-7/02_PortingToSingularity/localDisk/run/channel395
Running pimpleFoam in parallel on /vol2/ubuntu/containers/OpenFOAM-Pawsey-Containers/openfoam-7/02_PortingToSingularity/localDisk/run/channel395 using 4 processes
Running reconstructPar on /vol2/ubuntu/containers/OpenFOAM-Pawsey-Containers/openfoam-7/02_PortingToSingularity/localDisk/run/channel395
Running postChannel on /vol2/ubuntu/containers/OpenFOAM-Pawsey-Containers/openfoam-7/02_PortingToSingularity/localDisk/run/channel395
Singularity> ls
0	120  240  360  440  560  680  80   880	Allrun	       log.decomposePar  log.reconstructPar  system
0.orig	160  280  40   480  600  720  800  920	constant       log.pimpleFoam	 postProcessing
1000	200  320  400  520  640  760  840  960	log.blockMesh  log.postChannel	 processors4
Singularity> exit
exit

localHost> ls
run
localHost> cd run
localHost> ls
channel395
localHost> cd channel395
localHost> ls
0       120  240  360  440  560  680  80   880  Allrun         log.decomposePar  log.reconstructPar  system
0.orig  160  280  40   480  600  720  800  920  constant       log.pimpleFoam    postProcessing
1000    200  320  400  520  640  760  840  960  log.blockMesh  log.postChannel   processors4
```
For more general instructions on how to run a Singularity container, please refer to the [Sylabs documentation](https://sylabs.io/). We have also prepared additional information on how to [run a case at your local linux host with Singularity](./Documentation/ContainerUsage/RunningLocalWithSingularity.md) and how to [run a case at Pawsey Supercomputers with Singularity](./Documentation/ContainerUsage/RunningAtPawseyWithSingularity.md).

---
Back to the [README](../../README.md)




