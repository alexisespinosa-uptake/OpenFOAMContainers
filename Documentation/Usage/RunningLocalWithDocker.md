# Running a tutorial (or any case) wi0thin your local host with Docker

## 0. Preparation

Within your local host computer, cd to the case directory, and define some helpful variables. In my case:

```shell
localShell:$ theRepo=alexisespinosa
localShell:$ theContainer=openfoam
localShell:$ theTag=4.0
```
If the container is not in the host computer, then pull it from the repo:

```shell
localShell:$ docker pull $theRepo/$theContainer:$theTag
```

## 1. Define a case. (In this example we'll use a tutorial)
Find the tutorial to use:

```shell
localShell:$ docker run --rm $theRepo/$theContainer:$theTag bash -c 'find $FOAM_TUTORIALS -type d -name "cavity"'
```
* **\-\-rm** is for avoiding Docker to keep the container alive after execution
* **bash -c 'command'** is to execute the command recognising $FOAM_TUTORIALS inside the container
 
Copy the case you found above to the local host file system:

```shell
localShell:$ mkdir -p ./run/tutorials
localShell:$ docker run --rm -v $PWD:/localDir -u $(id -u):$(id -g) $theRepo/$theContainer:$theTag bash -c 'cp -r $FOAM_TUTORIALS/incompressible/icoFoam/cavity /localDir/run/tutorials'
```
* **-v $PWD:/localDir** mounts the local directory into the directory /localDir
* **-u $(id -u):$(id -g)** tells docker to use the host user identity in order to allow access/permissions to the host file system

## 2. Executing openfoam tools and solver
Any openfoam tool can be ran through the container.

### 2.1 Creating the mesh
```shell
localShell:$ cd ./run/tutorials/cavity
localShell:$ docker run --rm -v $PWD:/home/ofuser/case -w /home/ofuser/case -u $(id -u):$(id -g) $theRepo/$theContainer:$theTag blockMesh 2>&1 | tee log.blockMesh
```
* **-v $PWD:/home/ofuser/case** mounts the local directory into the directory /home/ofuser/case
* **-w /home/ofuser/case** defines the working directory where we want to execute the container command

The user can see the result of the command by exploring the file log.blockMesh, which should be in the current directory of the host computer.

### 2.2 Running the solver
Now, the same approach should be followed to run the solver:

```shell
localShell:$ docker run --rm -v $PWD:/home/ofuser/case -w /home/ofuser/case -u $(id -u):$(id -g) $theRepo/$theContainer:$theTag icoFoam 2>&1 | tee log.icoFoam
```
The solver should run properly and create the result directories.

---
Back to the [README](../../README.md)