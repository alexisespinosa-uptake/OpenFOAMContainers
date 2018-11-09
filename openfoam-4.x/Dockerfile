#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#Initial main definintion
FROM ubuntu:16.04
LABEL maintainer="Alexis.Espinosa@pawsey.org.au"
#OpenFOAM version to install
ARG OFVERSION="4.x"

#...........
#Using bash
SHELL ["/bin/bash","-c"]

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#Installation of mpich to work in Pawsey supercomputers

#This section was copy-pasted from the mpi-base docker file in
#https://github.com/Pawseyops/pawsey-dockerfiles/blob/master/mpi-base/Dockerfile
#mantained by brian skjerven
#...........
# Add aarnet mirror to speed up package update
RUN perl -p -i.orig -e \
      's/archive.ubuntu.com/mirror.aarnet.edu.au\/pub\/ubuntu\/archive/' /etc/apt/sources.list \
      && sed -i '0,/# deb-src/{s/# deb-src/deb-src/}' /etc/apt/sources.list

#...........
# Install package dependencies
RUN apt-get update \
      && apt-get install -y \
         build-essential \
         gdb \
         gfortran \
         python-minimal \
         python-dev \
         wget \
      && apt-get clean all \
      && rm -r /var/lib/apt/lists/*


#...........
### Build MPICH ###
ARG MPICH_VERSION="3.1.4"
ARG MPICH_CONFIGURE_OPTIONS="--enable-fast=all,O3 --prefix=/usr"
ARG MPICH_MAKE_OPTIONS="-j4"

WORKDIR /tmp/mpich-build

RUN wget http://www.mpich.org/static/downloads/${MPICH_VERSION}/mpich-${MPICH_VERSION}.tar.gz \
      && tar xvzf mpich-${MPICH_VERSION}.tar.gz \
      && cd mpich-${MPICH_VERSION}  \
      && ./configure ${MPICH_CONFIGURE_OPTIONS} \
      && make ${MPICH_MAKE_OPTIONS} \
      && make install \
      && ldconfig

#...........
# Test MPICH
#AEG:DidNotWork:WORKDIR /tmp/mpich-test
#AEG:DidNotWork:COPY mpich-test .
#AEG:DidNotWork:RUN sh test.sh
RUN mpiexec -n 8 /tmp/mpich-build/mpich-3.1.4/examples/cpi 2>&1 | tee log.cpi



#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#Installing additional tools useful for interactive sessions
RUN apt-get update -qq\
 &&  apt-get -y --no-install-recommends install \
            vim time\
            cron gosu \
 && apt-get clean all \
 && rm -r /var/lib/apt/lists/*



#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
##Setting a user for interactive sessions (with Docker) and passwords
#The passwords will be the $OFVERSION defined above
#Give a password to root.
#Examples from here:
#https://stackoverflow.com/questions/714915/using-the-passwd-command-from-within-a-shell-script
RUN echo "root:${OFVERSION}" | chpasswd


#Create the ofuser with the same password
RUN groupadd -g 999 ofuser \
 && useradd -r -m -u 999 -g ofuser ofuser
RUN echo "ofuser:${OFVERSION}" | chpasswd


#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#This section is for installing OpenFOAM
#Will follow instructions from here:
# https://openfoamwiki.net/index.php/Installation/Linux/OpenFOAM-$OFVERSION/Ubuntu


#...........
#Definition of the installation directory within the container
ARG OFINSTDIR=/MySoftware/OpenFOAM
ARG OFUSERDIR=/home/ofuser/OpenFOAM
WORKDIR $OFINSTDIR


#...........
#Install necessary packages
#A warning may appear:
#debconf: delaying package configuration, since apt-utils is not installed
#But seems to be a bug:
#https://github.com/phusion/baseimage-docker/issues/319
#But harmless.
RUN apt-get update -qq\
 &&  apt-get -y --no-install-recommends install \
   git-core \
   build-essential binutils-dev cmake flex \
   bison zlib1g-dev qt4-dev-tools libqt4-dev \
   libqtwebkit-dev gnuplot \
   libreadline-dev libncurses-dev libxt-dev \
#AEG:NoOpenMPI:   libopenmpi-dev openmpi-bin \
   libboost-system-dev libboost-thread-dev libgmp-dev \
   libmpfr-dev python python-dev libcgal-dev \
   libglu1-mesa-dev libqt4-opengl-dev \
#AEG:I found the following was needed to install  FlexLexer.h
   libfl-dev \
 && apt-get clean all \
 && rm -r /var/lib/apt/lists/*

#...........
#Change to the installation dir, download OpenFOAM and untar
ARG OFVERSIONGIT=$OFVERSION
WORKDIR $OFINSTDIR
RUN git clone https://github.com/OpenFOAM/OpenFOAM-${OFVERSIONGIT}.git \
 && git clone https://github.com/OpenFOAM/ThirdParty-${OFVERSIONGIT}.git
#...........
#AEG:Not defining the recommended softlinks to mpicc.openmpi and mpirun.openmpi in step 6 of the instructions

#...........
#Using a combination of the variable definition recommended for the use of system mpich here:
#https://bugs.openfoam.org/view.php?id=1167
#And in the file ...^/etc/config.sh/mpi
#(These MPI_* environmental variables are set in the prefs.sh as suggested in the link above,
# and this file is sourced before the bashrc)
#(Also the WM_MPLIB variable is modified in the bashrc file)
ARG OFPREFS=${OFINSTDIR}/OpenFOAM-${OFVERSION}/etc/config.sh/example/prefs.sh
ARG OFBASHRC=${OFINSTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc
RUN echo 'export WM_MPLIB=SYSTEMMPI' >> ${OFPREFS} \
 && echo 'export MPI_ROOT="/usr"' >> ${OFPREFS} \
 && echo 'export MPI_ARCH_FLAGS="-DMPICH_SKIP_MPICXX"' >> ${OFPREFS} \
 && echo 'export MPI_ARCH_INC="-isystem $MPI_ROOT/include"' >> ${OFPREFS} \
 && echo 'export MPI_ARCH_LIBS="-L$MPI_ROOT/lib -lmpich"' >> ${OFPREFS} \
 && sed -i $'s@^export WM_MPLIB=SYSTEMOPENMPI@# export WM_MPLIB=SYSTEMOPENMPI\\\nWM_MPLIB=SYSTEMMPI@' ${OFBASHRC}

#...........
#Changing the installation directory within the bashrc file (This is not in the openfoamwiki instructions)
RUN sed -i $'s@^export FOAM_INST_DIR=$HOME/$WM_PROJECT@# export FOAM_INST_DIR=$HOME/$WM_PROJECT\\\nFOAM_INST_DIR='"${OFINSTDIR}"'@' ${OFBASHRC} \
#Changing the WM_PROJECT_USER_DIR directory within the bashrc file 
#IMPORTANT:You have two options:
#   1. You can mount a directory of your local-host into this directory (as explained at the end of the Dockerfile)
#   2. Or you can include and build stuff inside the container and save it as your own image for later use.
 && sed -i $'s@^export WM_PROJECT_USER_DIR=$HOME/$WM_PROJECT/$USER-$WM_PROJECT_VERSION@#export WM_PROJECT_USER_DIR=$HOME/$WM_PROJECT/$USER-$WM_PROJECT_VERSION\\\nexport WM_PROJECT_USER_DIR='"${OFUSERDIR}/ofuser"'-$WM_PROJECT_VERSION@' ${OFBASHRC}

#...........
#Settings for X86_64 with 64 bit integer support
RUN sed -i $'s@^export WM_LABEL_SIZE=32@# export WM_LABEL_SIZE=32\\\nexport WM_LABEL_SIZE=64@' ${OFBASHRC} \
 && echo 'export FOAMY_HEX_MESH="yes"' >> ${OFPREFS}

#...........
##Paraview compilation (for runtime postprocessing purposes)
RUN . ${OFPREFS} \
 && . ${OFBASHRC} \
 && cd $WM_THIRD_PARTY_DIR \
 && export QT_SELECT=qt4 \
 && ./makeParaView4 -python -mpi -python-lib /usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0 2>&1 | tee log.makePV
#AEG:DidNotWork: && wmSET $FOAM_SETTINGS
#(adding next line instead)
#AEG:NotReallyNeeded: && . $WM_PROJECT_DIR/etc/bashrc $FOAM_SETTINGS

#...........
##Third party compilation (not indicated in the openfoamwiki but preferred to do it separately) 
RUN . ${OFPREFS} \
 && . ${OFBASHRC} \
 && cd $WM_THIRD_PARTY_DIR \
 && export QT_SELECT=qt4 \
 && ./Allwmake -j 4 2>&1 | tee log.make
#AEG:DidNotWork: && wmSET $FOAM_SETTINGS
#(adding next line instead)
#AEG:NotReallyNeeded: && . $WM_PROJECT_DIR/etc/bashrc $FOAM_SETTINGS

#...........
##A few fixes indicated in steps 11 and 12 of the openfoamwiki instructions
#(Commenting as there are No additional instructions for 4.x)
####RUN . ${OFPREFS} \
#### && . ${OFBASHRC} \
#### && cd $WM_PROJECT_DIR \
#### && find src applications -name "*.L" -type f | xargs sed -i -e 's=\(YY\_FLEX\_SUBMINOR\_VERSION\)=YY_FLEX_MINOR_VERSION < 6 \&\& \1=' \
#### && mkdir -p $CGAL_ARCH_PATH \
#### && mkdir -p $BOOST_ARCH_PATH

#...........
##OpenFOAM compilation
RUN . ${OFPREFS} \
 && . ${OFBASHRC} \
 && cd $WM_PROJECT_DIR \
 && export QT_SELECT=qt4 \
 && ./Allwmake -j 4 2>&1 | tee log.make
#AEG:DidNotWork: && wmSET $FOAM_SETTINGS
#(adding next line instead)
#AEG:NotReallyNeeded: && . $WM_PROJECT_DIR/etc/bashrc $FOAM_SETTINGS

#...........
##Obtaining the summary of the OpenFOAM compilation as suggested in the openfoamwiki instructions
RUN . ${OFPREFS} \
 && . ${OFBASHRC} \
 && cd $WM_PROJECT_DIR \
 && export QT_SELECT=qt4 \
 && ./Allwmake -j 4 2>&1 | tee log.makeSummary
#AEG:DidNotWork: && wmSET $FOAM_SETTINGS
#(adding next line instead)
#AEG:NotReallyNeeded: && . $WM_PROJECT_DIR/etc/bashrc $FOAM_SETTINGS

#...........
##Checking if openfoam is working
RUN . ${OFPREFS} \
 && . ${OFBASHRC} \
 && cd $WM_PROJECT_DIR \
 && icoFoam -help 2>&1 | tee log.icoFoam


#...........
#Create the openfoam user directory
USER ofuser
RUN mkdir -p ${OFUSERDIR}/ofuser-${OFVERSION} \
 && chmod -R 777 ${OFUSERDIR}
USER root


#...........
#Allowing normal users to read,write and execute on the OF installation
RUN chmod -R 777 $OFINSTDIR

#...........
# Automating the sourcing of the openfoam prefs.sh and bashrc files for root and ofuser
#(Commented because, for the current version of shifter the environmental variables will need to be set
# manually with ENV commands. And, in order to check that the set up of all necessary variables is done
# properly, I will avoid the setting through the use of prefs.sh and bashrc files, and will use only the ENV
# declarations that will appear in a section below) 
####RUN echo "" >> $HOME/.bashrc \
#### && echo "#Sourcing openfoam setting files" >> $HOME/.bashrc \
#### && echo "source ${OFPREFS}" >> ${HOME}/.bashrc \
#### && echo "source ${OFBASHRC}" >> ${HOME}/.bashrc \
#### && echo "" >> /home/ofuser/.bashrc \
#### && echo "#Sourcing openfoam setting files" >> /home/ofuser/.bashrc \
#### && echo "source ${OFPREFS}" >> /home/ofuser/.bashrc \
#### && echo "source ${OFBASHRC}" >> /home/ofuser/.bashrc

#...........
## If happy with the installation and want to remove temporary files, directories and logFiles
# (Comment these lines during testing of creation in order to be able to take a look into the files)
RUN rm -rf /tmp \
 && source ${OFPREFS} \
 && source ${OFBASHRC} \
 && rm $WM_THIRD_PARTY_DIR/log.make \
 && rm $WM_THIRD_PARTY_DIR/log.makePV \
 && rm $WM_PROJECT_DIR/log.make \
 && rm $WM_PROJECT_DIR/log.makeSummary \
 && rm $WM_PROJECT_DIR/log.icoFoam


#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
## Hardcoding the environmental variables to run openfoam.
# We have not found a way of sourcing the files that set the environmental variables for the usage
# of openfoam parallel tools within containers using shifter at Pawsey.
# Then, the only way we have found for things to work is to define all the environmental variables
# within the Dockerfile using the ENV command. But finding all the intrincate ways these variables
# are defined is not an easy task.
# Furthermore, each version of openfoam may have different set-ups for these environmental variables,
# making it a harder task to define the environmental variables with an ideal "clean" definition.
# Then, we opted to follow this series of steps that have proven to be simple and effective to
# "hardcode" these variables for each specific version of openfoam.
#  In order to create the full list of environemntal variables to define, follow these steps:
#  0.  Create a container with the installation of openfoam, but without definition of any ENV variable.
#      This container should be capable of running openfoam properly in an interactive docker session
#      by sourcing the prefs.sh and bashrc files as explained below. Then, if openfoam is working properly,
#      the environmental variables will be printed, ordered, cleaned, copied and pasted into this Dockerfile,
#      as explained below. 
#      0.1 To build the imagei for version 4.x, I (alexisespinosa) used:
#          0.1.1 docker build -t alexisespinosa/openfoam:4.x
#          (0.1.2) (or pulled from dockerhub): docker pull alexisespinosa/openfoam:4.x
#      0.2 To run the interactive session use:
#          0.2.1 docker run -it --rm -v $PWD:/localDir alexisespinosa/openfoam:4.x
#  1.  In an interactive session:
#      1.1  su ofuser (see password for this installation above, it is the OFVERSION, in this example:4.x)
#      1.2  Initialize openfoam environment by:
#           1.2.1 source the file prefs.sh (the full path is written above to define $OFPREFS)
#           1.2.2 source the file bashrc (the full path is written above to define $OFBASHRC)
#  2.  Test that openfoam is working properly for ofuser (still within the su session)
#  3.  Then print the environment variables:
#      3.1 printenv > /localDir/raw_vars.env
#      3.2 (exit the su): exit
#      3.3 (exit the container): exit
#  4.  Order the variables alphabetically (important for an easier check of variables within shifter in Pawsey)
#      4.1 sort raw_vars.env -o sorted_vars.env 
#  5.  Remove unnecesary variables (not related to openfoam) within sorted_vars.env
#  6.  Use double quotes for variables with spaces (for example for flags) within sorted_vars.env
#  7.  Copy paste the list of environmental variables within sorted_vars.env into this Dockerfile.
#  8.  Add ENV at the beggining of all lines to set the environmental variables
ENV FOAM_APP=/MySoftware/OpenFOAM/OpenFOAM-4.x/applications
ENV FOAM_APPBIN=/MySoftware/OpenFOAM/OpenFOAM-4.x/platforms/linux64GccDPInt32Opt/bin
ENV FOAM_ETC=/MySoftware/OpenFOAM/OpenFOAM-4.x/etc
ENV FOAM_EXT_LIBBIN=/MySoftware/OpenFOAM/ThirdParty-4.x/platforms/linux64GccDPInt32/lib
ENV FOAM_INST_DIR=/MySoftware/OpenFOAM
ENV FOAM_JOB_DIR=/MySoftware/OpenFOAM/jobControl
ENV FOAM_LIBBIN=/MySoftware/OpenFOAM/OpenFOAM-4.x/platforms/linux64GccDPInt32Opt/lib
ENV FOAM_MPI=mpi-system
ENV FOAM_RUN=/home/ofuser/OpenFOAM/ofuser-4.x/run
ENV FOAM_SETTINGS=
ENV FOAM_SIGFPE=
ENV FOAM_SITE_APPBIN=/MySoftware/OpenFOAM/site/4.x/platforms/linux64GccDPInt32Opt/bin
ENV FOAM_SITE_LIBBIN=/MySoftware/OpenFOAM/site/4.x/platforms/linux64GccDPInt32Opt/lib
ENV FOAM_SOLVERS=/MySoftware/OpenFOAM/OpenFOAM-4.x/applications/solvers
ENV FOAM_SRC=/MySoftware/OpenFOAM/OpenFOAM-4.x/src
ENV FOAM_TUTORIALS=/MySoftware/OpenFOAM/OpenFOAM-4.x/tutorials
ENV FOAM_USER_APPBIN=/home/ofuser/OpenFOAM/ofuser-4.x/platforms/linux64GccDPInt32Opt/bin
ENV FOAM_USER_LIBBIN=/home/ofuser/OpenFOAM/ofuser-4.x/platforms/linux64GccDPInt32Opt/lib
ENV FOAM_UTILITIES=/MySoftware/OpenFOAM/OpenFOAM-4.x/applications/utilities
ENV LD_LIBRARY_PATH=/MySoftware/OpenFOAM/ThirdParty-4.x/platforms/linux64Gcc/gperftools-svn/lib:/MySoftware/OpenFOAM/ThirdParty-4.x/platforms/linux64Gcc/ParaView-5.0.1/lib/paraview-5.0:/MySoftware/OpenFOAM/OpenFOAM-4.x/platforms/linux64GccDPInt32Opt/lib/mpi-system:/MySoftware/OpenFOAM/ThirdParty-4.x/platforms/linux64GccDPInt32/lib/mpi-system:/home/ofuser/OpenFOAM/ofuser-4.x/platforms/linux64GccDPInt32Opt/lib:/MySoftware/OpenFOAM/site/4.x/platforms/linux64GccDPInt32Opt/lib:/MySoftware/OpenFOAM/OpenFOAM-4.x/platforms/linux64GccDPInt32Opt/lib:/MySoftware/OpenFOAM/ThirdParty-4.x/platforms/linux64GccDPInt32/lib:/MySoftware/OpenFOAM/OpenFOAM-4.x/platforms/linux64GccDPInt32Opt/lib/dummy
ENV MPI_ARCH_FLAGS=-DMPICH_SKIP_MPICXX
ENV MPI_ARCH_INC="-isystem /usr/include"
ENV MPI_ARCH_LIBS="-L/usr/lib -lmpich"
ENV MPI_ARCH_PATH=/usr
ENV MPI_BUFFER_SIZE=20000000
ENV MPI_ROOT=/usr
ENV PATH=/MySoftware/OpenFOAM/ThirdParty-4.x/platforms/linux64Gcc/gperftools-svn/bin:/MySoftware/OpenFOAM/ThirdParty-4.x/platforms/linux64Gcc/ParaView-5.0.1/bin:/home/ofuser/OpenFOAM/ofuser-4.x/platforms/linux64GccDPInt32Opt/bin:/MySoftware/OpenFOAM/site/4.x/platforms/linux64GccDPInt32Opt/bin:/MySoftware/OpenFOAM/OpenFOAM-4.x/platforms/linux64GccDPInt32Opt/bin:/MySoftware/OpenFOAM/OpenFOAM-4.x/bin:/MySoftware/OpenFOAM/OpenFOAM-4.x/wmake:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games
ENV PV_PLUGIN_PATH=/MySoftware/OpenFOAM/OpenFOAM-4.x/platforms/linux64GccDPInt32Opt/lib/paraview-5.0
ENV ParaView_DIR=/MySoftware/OpenFOAM/ThirdParty-4.x/platforms/linux64Gcc/ParaView-5.0.1
ENV ParaView_INCLUDE_DIR=/MySoftware/OpenFOAM/ThirdParty-4.x/platforms/linux64Gcc/ParaView-5.0.1/include/paraview-5.0
ENV ParaView_MAJOR=5.0
ENV ParaView_VERSION=5.0.1
ENV WM_ARCH=linux64
ENV WM_ARCH_OPTION=64
ENV WM_CC=gcc
ENV WM_CFLAGS="-m64 -fPIC"
ENV WM_COMPILER=Gcc
ENV WM_COMPILER_LIB_ARCH=64
ENV WM_COMPILER_TYPE=system
ENV WM_COMPILE_OPTION=Opt
ENV WM_CXX=g++
ENV WM_CXXFLAGS="-m64 -fPIC -std=c++0x"
ENV WM_DIR=/MySoftware/OpenFOAM/OpenFOAM-4.x/wmake
ENV WM_LABEL_OPTION=Int32
ENV WM_LABEL_SIZE=32
ENV WM_LDFLAGS=-m64
ENV WM_LINK_LANGUAGE=c++
ENV WM_MPLIB=SYSTEMMPI
ENV WM_OPTIONS=linux64GccDPInt32Opt
ENV WM_OSTYPE=POSIX
ENV WM_PRECISION_OPTION=DP
ENV WM_PROJECT=OpenFOAM
ENV WM_PROJECT_DIR=/MySoftware/OpenFOAM/OpenFOAM-4.x
ENV WM_PROJECT_INST_DIR=/MySoftware/OpenFOAM
ENV WM_PROJECT_USER_DIR=/home/ofuser/OpenFOAM/ofuser-4.x
ENV WM_PROJECT_VERSION=4.x
ENV WM_THIRD_PARTY_DIR=/MySoftware/OpenFOAM/ThirdParty-4.x



#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
## Starting as ofuser by default
USER ofuser
WORKDIR /home/ofuser


#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#Example for compiling your own solver to be used with the openfoam:4.x container:

# For using it in your local host with docker:
# 1.0 Pull the container:
#     1.1 docker pull alexisespinosa/openfoam:4.x
# 2.0 Run the container interactively:
#     2.3 cd to your working directory in scratch:
#         2.3.1  cd <workingDir> 
#     2.5 (At pawsey computer): run interactively mounting your userOpenFOAM directory in the place of $WM_PROJECT_USER_DIR:
#         docker run -it --rm -v /Users/MyMac/OpenFOAM/espinosa-4.x:/home/ofuser/OpenFOAM/ofuser-4.x alexisespinosa/openfoam:4.x
#         (This should prompt you into the container itself) 
#     2.6 Within the container, cd to the application dir and compile (you can use the environmental variables):
#         2.6.1 cd $WM_PROJECT_USER_DIR/applications/my_icoFoam
#         2.6.2 wclean
#         2.6.3 wmake
#               (Now the executable of my_icoFoam should be visible in the container at):
#               /home/ofuser/OpenFOAM/ofuser-4.x/platforms/linux64GccDPInt32Opt/bin/my_icoFoam
#               (which is the same as):
#               $WM_PROJECT_USER_DIR/platforms/linux64GccDPInt32Opt/bin/my_icoFoam
#               (which is the same as, outside the container):
#               /Users/MyMac/OpenFOAM/espinosa-4.x/platforms/linux64GccDPInt32Opt/bin/my_icoFoam


#
# For using it in magnus at Pawsey I used:
# 1.0 Pull the container:
#     1.1 (In the login node): sg $PAWSEY_PROJECT -c 'shifter pull alexisespinosa/openfoam:4.x'
# 2.0 Run the container interactively:
#     2.1 (At pawsey computer):salloc -p debugq
#     2.2 module load shifter
#     2.3 (At pawsey computer): cd to your working directory in scratch:
#         2.3.1  cd $MYSCRATCH/<workingDir> 
#     2.4 scp your developed application into your userOpenFOAM directory in $MYGROUP in Pawsey:
#         2.4.1 (At your local host use scp):
#               scp -r myLocalDir/OpenFOAM/espinosa-4.x/applications/my_icoFoam \
#               espinosa@hpc-data.pawsey.org.au:/group/pawseyXXXX/espinosa/OpenFOAM/espinosa-4.x/applications 
#     2.5 (At pawsey computer): run interactively mounting your userOpenFOAM directory in the place of $WM_PROJECT_USER_DIR:
#         shifter run --mount=type=bind,source=$MYGROUP/OpenFOAM/espinosa-4.x,destination=/home/ofuser/OpenFOAM/ofuser-4.x alexisespinosa/openfoam:4.x
#         (This should prompt you into the container itself) 
#     2.6 Within the container, cd to the application dir and compile (you can use the environmental variables):
#         2.6.1 cd $WM_PROJECT_USER_DIR/applications/my_icoFoam
#         2.6.2 wclean
#         2.6.3 wmake
#               (Now the executable of my_icoFoam should be visible in the container at):
#               /home/ofuser/OpenFOAM/ofuser-4.x/platforms/linux64GccDPInt32Opt/bin/my_icoFoam
#               (which is the same as):
#               $WM_PROJECT_USER_DIR/platforms/linux64GccDPInt32Opt/bin/my_icoFoam
#               (which is the same as, inside or outside the container):
#               $MYSCRATCH/OpenFOAM/espinosa-4.x/platforms/linux64GccDPInt32Opt/bin/my_icoFoam
#     2.7 Exit the interactive container

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#Example script for running your own solver (created above) with openfoam:4.x container:
#1. cd to the working dir (In this case, this working dir has the tutorial "cavity")
#2. run the script: sbatch runContainer.slm
#   2.1 The script contains: (What is in the script is after the mark ##|):
##|#!/bin/bash -l
##|#SBATCH --export=NONE
##|#SBATCH --time=00:05:00
##|#SBATCH --ntasks=1
##|#SBATCH --ntasks-per-node=24
##|#SBATCH --partition=debugq
##|
##|module load shifter
##|#----------
##|#Setting some preliminary environmental variables
##|export OF_VERSION=4.x
##|
##|echo "Trying 1:"
##|srun --export=all -n 1 shifter run alexisespinosa/openfoam:$OF_VERSION blockMesh
##|echo "Trying 2:"
##|srun --export=all -n 1 shifter run --mount=type=bind,source=$MYGROUP/OpenFOAM/espinosa-4.x,destination=/home/ofuser/OpenFOAM/ofuser-4.x alexisespinosa/openfoam:$OF_VERSION my_icoFoam > logRun 2>&1



#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#Example script for running your  with openfoam:4.x container:
#1. cd to the working dir (In this case, this working dir has the tutorial "damBreak")
#2. run the script: sbatch runContainer.slm
#   2.1 The script contains: (What is in the script is after the mark ##|):
##|#!/bin/bash -l
##|#SBATCH --export=NONE
##|#SBATCH --time=00:15:00
##|#SBATCH --ntasks=4
##|#SBATCH --ntasks-per-node=24
##|#SBATCH --partition=debugq
##|
#|module load shifter
##|#----------
##|#Setting some preliminary environmental variables
##|export OF_VERSION=4.x
##|
##|echo "Trying 1:"
##|srun --export=all -n 1 shifter run alexisespinosa/openfoam:$OF_VERSION blockMesh
##|echo "Trying 2:"
##|srun --export=all -n 1 shifter run alexisespinosa/openfoam:$OF_VERSION setFields
##|echo "Trying 3:"
##|srun --export=all -n 1 shifter run alexisespinosa/openfoam:$OF_VERSION decomposePar
##|echo "Trying 4:"
##|srun --export=all -n $SLURM_NTASKS shifter run --mpi alexisespinosa/openfoam:$OF_VERSION interFoam -parallel >logRun 2>&1
