# Build a container with waves2Foam

## 0. Use existing Dockerfiles as example

The waves2Foam containers needs to start with an already tested container with the desired version of OpenFOAM. So, for example, the existing waves2Foam container in the Docker Hub named:

```shell
alexisespinosa/openfoam:v1606_w2f
```
was created with the Dockerfile that is kept in the git repo:

```shell
openfoam-v1606_w2f\Dockerfile
```
whose first line is:

```docker
FROM alexisespinosa/openfoam:v1606
```

In order to build your own container with waves2Foam please follow use the Dockerfiles for the containers with a tag with the string **"w2f"**. That string indicates that that container was been equipped with waves2Foam.

## 1. Comment out the ENV definitions existing in the template Dockerfile
If you are creating a new container using an exisitng Dockerfile as an example, then this Dockerfile may contain a list of environmental variables defined with ENV. Then, in order to create your new container you will need to comment out or delete all the existing ENV definitions, as they may not apply for the new container. Then, all the ENV definitions needed for the new container will be defined following the same approach as indicated in [II. Hardcoding environmental variables](./II.HARDCODING_ENVIRONMENTAL_VARIABLES.md).

The section for the ENV definition should look empty, like this:

```docker
.
.
.
#----------------------------:
# i. Copy&Paste the list of environmental variables below this comment.
#and before the ii. "Fixing" comment.
#IMPORTANT: In the first pass of creation of this container, all the ENV definitions should be removed or commented.
#           Then, after defining the list of ENV variables that will be used here, you should copy and paste them below:
#----------------------------:

#----------------------------:
#ii. Fixing shifter bug with environment variables.
#If loss of variables environment variables occurred to you,
#Comment the problematic variables in the list above and mark them with some tag like #WillBeDefinedAtTheEndDueToShifterFailure
#and define them at the end of the list (immediately below this comment)
#----------------------------:
.
.
.

```

## 2. Build the first version of the new container

Once you have prepared your Dockerfile, you can build it with a similar command sequence to this:

```shell
localShell:$ theRepo=alexisespinosa
localShell:$ theContainer=openfoam
localShell:$ theTag=v1606_w2f
localShell:$ docker build -t $theRepo/$theContainer:$theTag .
```

(This example considers my docker repository is "alexisespinosa", the image name is "openfoam" and the tag is "v1606_w2f") ("localShell:\$" is the prompt, it is not part of the command.)

\$

## 3. Hardcode the waves2Foam environment variables

As explained in [II. Hardcoding environmental variables](./II.HARDCODING_ENVIRONMENTAL_VARIABLES.md) shifter does not allow the container to source the configuration files at startup. Therefore, all the new environmental variables defined by the waves2Foam configuration file need to be hardcoded into the Dockerfile. The process of hardcoding the variables for OpenFOAM containers is already detailed in the link above, so it will not be repeated here.

But a few quick comments will be given below.

### 3.1. Test the installation and then print out a list of the environmental variables

- 3.1.1: Run an interactive session.

```shell
localShell:$ docker run -it --rm -v $PWD:/localDir --user $(id -u):$(id -g) $theRepo/$theContainer:$theTag
I have no name!:$
```

(Your prompt will now change to "I have no name" inside the container, but that is fine as we have forced to use the local user:group in order to have writing permission)

- 3.1.2 Within the interactive session, source the configuration file for waves2Foam in order to define the new environmental variables:

```shell
I have no name!:$ source /MySoftware/waves2Foam/bin/bashrc
```
There is no need to source the OpenFOAM bashrc configuration file as all the environment variables have already been hardcoded for the basic OpenFOAM container.

- 3.1.3 Find a tutorial case to test:

```shell
I have no name!:$ find $WAVES_TUT -type d -name "waveFlume"
```

- 3.1.4 Copy the tutorial case and test that waves2Foam is working properly:

```shell
I have no name!:$ mkdir -p /localDir/run/tutorials
I have no name!:$ cp -rp $WAVES_TUT/waveFoam/waveFlume /localDir/run/tutorials
I have no name!:$ cd /localDir/run/tutorials/waveFlume
I have no name!:$ sed -i -e '/^exec=.*/aexec="$WAVES_DIR/bin/prepareCase.sh"' Allrun
I have no name!:$ sed -i -e '0,/^exec/s//# exec/' Allrun
I have no name!:$ rm log.*
I have no name!:$ ./Allrun &
I have no name!:$ tail -f
```
A few adaptations of the scripts were needed, as the tutorial is not being ran in the original tutorial place.

- 3.1.5 If everything is working properly, then print the new environment variables created by the waves2Foam congifuration file into an output file in your local machine (remember that /localDir is a mount local working directory). The process is simplified by the fact that when sourcing the configuration file, those variables are printed out automatically:

```shell
I have no name!:$ mkdir /localDir/variables
I have no name!:$ source $WAVES_BIN_BASHRC > /localDir/variables/raw_vars_w2f.env
I have no name!:$ exit
```

### 3.2 Clean and edit the list
The final list in a file named "ready_vars_w2f.env" should like similar to this (but with the pertinent variables for your installation):

```shell
ENV EXTBRANCH=0
ENV FOAMEXTENDPROJECT=0
ENV OFPLUSBRANCH=1
ENV WAVES_APPBIN=/home/ofuser/OpenFOAM/ofuser-v1606+/platforms/linux64GccDPInt32Opt/bin
ENV WAVES_DIR=/MySoftware/waves2Foam
ENV WAVES_GSL_INCLUDE=/usr/include
ENV WAVES_GSL_LIB=/usr/lib64
ENV WAVES_LIBBIN=/home/ofuser/OpenFOAM/ofuser-v1606+/platforms/linux64GccDPInt32Opt/lib
ENV WAVES_POST=/MySoftware/waves2Foam/applications/utilities/postProcessing
ENV WAVES_PRE=/MySoftware/waves2Foam/applications/utilities/preProcessing
ENV WAVES_SOL=/MySoftware/waves2Foam/applications/solvers/solvers1606_PLUS
ENV WAVES_SRC=/MySoftware/waves2Foam/src
ENV WAVES_TUT=/MySoftware/waves2Foam/tutorials
ENV WAVES_UTIL=/MySoftware/waves2Foam/applications/utilities
ENV WAVES_XVERSION=0
ENV WM_PROJECT_VERSION_NUMBER=1606
```
## 3. Copy/paste the list into the Dockerfile
Copy the list into the right section of the Dockerfile, just below the " i. Copy&Paste" indication:

```shell
.
.
.
#----------------------------:
# i. Copy&Paste the list of environmental variables below this comment.
#and before the ii. "Fixing" comment.
#IMPORTANT: In the first pass of creation of this container, all the ENV definitions should be removed or commented.
#           Then, after defining the list of ENV variables that will be used here, you should copy and paste them below:
#----------------------------:
ENV EXTBRANCH=0
ENV FOAMEXTENDPROJECT=0
ENV OFPLUSBRANCH=1
ENV WAVES_APPBIN=/home/ofuser/OpenFOAM/ofuser-v1606+/platforms/linux64GccDPInt32Opt/bin
ENV WAVES_DIR=/MySoftware/waves2Foam
ENV WAVES_GSL_INCLUDE=/usr/include
ENV WAVES_GSL_LIB=/usr/lib64
ENV WAVES_LIBBIN=/home/ofuser/OpenFOAM/ofuser-v1606+/platforms/linux64GccDPInt32Opt/lib
ENV WAVES_POST=/MySoftware/waves2Foam/applications/utilities/postProcessing
ENV WAVES_PRE=/MySoftware/waves2Foam/applications/utilities/preProcessing
ENV WAVES_SOL=/MySoftware/waves2Foam/applications/solvers/solvers1606_PLUS
ENV WAVES_SRC=/MySoftware/waves2Foam/src
ENV WAVES_TUT=/MySoftware/waves2Foam/tutorials
ENV WAVES_UTIL=/MySoftware/waves2Foam/applications/utilities
ENV WAVES_XVERSION=0
ENV WM_PROJECT_VERSION_NUMBER=1606

#----------------------------:
#ii. Fixing shifter bug with environment variables.
#If loss of variables environment variables occurred to you,
#Comment the problematic variables in the list above and mark them with some tag like #WillBeDefinedAtTheEndDueToShifterFailure
#and define them at the end of the list (immediately below this comment)
#----------------------------:
.
.
.
```

---
Back to the [README](../../README.md)

