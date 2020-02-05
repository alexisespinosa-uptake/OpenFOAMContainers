# II. Porting the Docker MPICH-OpenFOAM container into Singularity

## 0. Local installation of Singularity

Obviously, you need an installation of Singularity in your local host. For installing singularity you can follow the official documentation: [Sylabs](https://sylabs.io/)

## 1. Porting the container

General porting rules of Docker containers are explained in the Singularity documentation: [Singularity-&-Docker documentation](https://sylabs.io/guides/3.5/user-guide/singularity_and_docker.html#). And also in Pawsey's documentation of [Singularity](https://support.pawsey.org.au/documentation/display/US/Singularity).

Nevertheless, the recommended procedure for OpenFOAM containers will be explained here because we'll use the Singularity definition file to source the OpenFOAM environment definition file "bashrc". This is important, because this avoids the need to source the bashrc for interactive sessions. But more importantly, because this allows for OpenFOAM MPI applications to recognise the environmental variables correctly. Otherwise, the environmental variables would have to be defined one by one (as was indeed the case for other container managers).

The procedure is simple. First, you need to create a definition file that uses the Docker container and that indicates the sourcing of the "bashrc" file. (We assume that your docker repository (username) is mickey and the version (tag) of the "openfoam" container is 7). Then, the definition ("Singularity.openfoam.def") file should contain:

```Singularity
Bootstrap: docker
From: mickey/openfoam:7

%post
/bin/mv /bin/sh /bin/sh.original
/bin/ln -s /bin/bash /bin/sh
echo ". /opt/OpenFOAM/OpenFOAM-7/etc/bashrc" >> $SINGULARITY_ENVIRONMENT
```
The meaning of the commands can be further understood in the [Sylabs](https://sylabs.io/) documentation but, basically is saying that the new Singularity container will use a docker container as a base, the name of the container in the DockerHub repository, and that


And then, the command to perform the build is:

```bash
localHost> sudo singularity build openfoam-7-mickey.sif Singularity.openfoam.def
```


