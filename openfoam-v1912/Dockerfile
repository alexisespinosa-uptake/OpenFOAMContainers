#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
# 0. Initial main definintion
#AEG: Not using the mpi-base in this case in order to show users
##FROM pawsey/mpi-base:latest

#AEG: Defining the operating system to use (instead of the native ubuntu:18.04 withing pawsey/mpi-base)
#FROM ubuntu:16.04
FROM ubuntu:18.04

LABEL maintainer="Alexis.Espinosa@pawsey.org.au"
#OpenFOAM version to install
ARG OFVERSION="v1912"
#Using bash from now on
SHELL ["/bin/bash", "-c"]

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
# I. Installation of mpich to work in Pawsey supercomputers
#    This whole section (I.) should be commented if starting from pawsey/mpi-base above.

# +++
#This section was copy-pasted from the mpi-base docker file in
#https://github.com/PawseySC/pawsey-dockerfiles/blob/master/mpi-base/Dockerfile
#mantained by brian skjerven

#...........
# Install package dependencies
RUN apt-get update -qq \
      && apt-get -y --no-install-recommends install \
         build-essential \
         gdb \
         gfortran \
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

#AEG: Not building the OSU Benchmarks
# +++

#...........
# Test MPICH
RUN mpiexec -n 8 /tmp/mpich-build/mpich-3.1.4/examples/cpi 2>&1 | tee log.cpi



#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
# II. Installing additional tools useful for interactive sessions
RUN apt-get update -qq\
 &&  apt-get -y --no-install-recommends install \
            vim time\
            cron gosu \
            bc \
 && apt-get clean all \
 && rm -r /var/lib/apt/lists/*



#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
# III. Setting a user for interactive sessions (with Docker) and passwords
#The passwords will be the $OFVERSION defined above
#Give a password to root.
#Examples from here:
#https://stackoverflow.com/questions/714915/using-the-passwd-command-from-within-a-shell-script
RUN echo "root:${OFVERSION}" | chpasswd


#Create the ofuser with the same password (all the *USER* environmental variables will point towards this user)
#Recent native developers' containers are not using this "ofuser" anymore, although it is still useful to have it
#for pawsey purposes where /group needs to be used as the place for the *USER* variables. Then, /group directory
#will be mounted into the ofuser dir whenever own compiled tools are used
RUN groupadd -g 999 ofuser \
 && useradd -r -m -u 999 -g ofuser ofuser
RUN echo "ofuser:${OFVERSION}" | chpasswd



#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
# IV. INSTALLING OPENFOAM.
#This section is for installing OpenFOAM
#Will NOT follow strictly the official installation instructions:
#https://www.openfoam.com/documentation/system-requirements.php
#and
#https://www.openfoam.com/code/build-guide.php
#and
#https://www.openfoam.com/download/install-source.php
#
#Will NOT follow strictly the instructions for openfoamplus available in the wiki (latest is for v1806):
#https://openfoamwiki.net/index.php/Installation/Linux/OpenFOAM-v1806/Ubuntu
#
#Then, Will follow a combination of both

#...........
#Definition of the installation directory within the container
ARG OFINSTDIR=/opt/OpenFOAM
ARG OFUSERDIR=/home/ofuser/OpenFOAM
WORKDIR $OFINSTDIR

#...........
#Step 1.
#Install necessary packages
#
#A warning may appear:
#debconf: delaying package configuration, since apt-utils is not installed
#But seems to be a bug:
#https://github.com/phusion/baseimage-docker/issues/319
#But harmless.
RUN apt-get update -qq\
 &&  apt-get -y --no-install-recommends --no-install-suggests install \
#AEG: wget and build-essential were already installed above for MPICH
#AEG:AlreadyInstalled:   wget build-essential\
   flex bison cmake zlib1g-dev \
#AEG:No Boost because the third party will be used
#AEG:NoBoost:   libboost-system-dev libboost-thread-dev \
#AEG:No OpenMPI because installed above MPICH will be used
#AEG:NoOpenMPI:   libopenmpi-dev openmpi-bin \
   gnuplot libreadline-dev libncurses-dev libxt-dev \
#AEG:Not installing qt4 (as in the official instructions), but qt5 as in the wiki instructions
#AEG:NoQt4:   qt4-dev-tools libqt4-dev libqt4-opengl-dev \ 
   qt5-default libqt5x11extras5-dev libqt5help5 qtdeclarative5-dev qttools5-dev libqt5opengl5-dev \
   freeglut3-dev libqtwebkit-dev \
#AEG:Wiki additional qt suggestions (from OpenFOAM-7):
   qtbase5-dev \
#AEG:No scotch because it installs openmpi which later messes up with shifter at pawsey
#    Therefore, ThirdParty scotch is the one to be installed and used by openfoam.
#AEG:NoScotch:   libscotch-dev \
#AEG:No CGAL because third party will be used
#AEG:NoCGAL:will be installed as 3rdParty:   libcgal-dev \
#AEG:These libraries are needed for CGAL (system and third party) (if needed, change libgmp-dev for libgmp3-dev):
   libgmp-dev libmpfr-dev\
#AEG: Some more suggestions from the wiki instructions:
   python python-dev \
   libglu1-mesa-dev \
#AEG:I found the following was needed to install  FlexLexer.h
   libfl-dev \
#AEG:Curl is possibly missing for paraview (From instructions for openfoam-7) (will use it next time I try to compile paraview): 
#   curl \
 && apt-get clean all \
 && rm -r /var/lib/apt/lists/*


#...........
#Step 2. Download
#Change to the installation dir, download OpenFOAM and untar
ARG OFVERSIONFORGE=$OFVERSION
WORKDIR $OFINSTDIR
RUN wget --no-check-certificate -O OpenFOAM-${OFVERSION}.tgz \
    "https://sourceforge.net/projects/openfoam/files/OpenFOAM-${OFVERSIONFORGE}.tgz?use_mirror=mesh" \
 && wget --no-check-certificate -O ThirdParty-${OFVERSION}.tgz \
    "https://sourceforge.net/projects/openfoam/files/ThirdParty-${OFVERSIONFORGE}.tgz?use_mirror=mesh" \
 && tar -xvzf OpenFOAM-${OFVERSION}.tgz \
 && tar -xvzf ThirdParty-${OFVERSION}.tgz \
 && rm -f OpenFOAM-${OFVERSION}.tgz \
 && rm -f ThirdParty-${OFVERSION}.tgz

#...........
#Step 3. Definitions for the prefs and bashrc files.
ARG OFPREFS=${OFINSTDIR}/OpenFOAM-${OFVERSION}/etc/prefs.sh
ARG OFBASHRC=${OFINSTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc

#...........
#Defining the prefs.sh:
RUN head -23 ${OFINSTDIR}/OpenFOAM-${OFVERSION}/etc/config.sh/example/prefs.sh > $OFPREFS \
 && echo '#------------------------------------------------------------------------------' >> ${OFPREFS} \
#Using a combination of the variable definition recommended for the use of system mpich here:
#https://bugs.openfoam.org/view.php?id=1167
#And in the file .../OpenFOAM-v1912/wmake/rules/General/mplibMPICH
#(These MPI_* environmental variables are set in the prefs.sh as suggested in the link above,
# and this file is sourced automatically by the bashrc when the bashrc is sourced)
#--As suggested in the link, WM_MPLIB and MPI_ROOT need to be set:
 && echo 'export WM_MPLIB=SYSTEMMPI' >> ${OFPREFS} \
 && echo 'export MPI_ROOT="/usr"' >> ${OFPREFS} \
#--As suggested in the link, MPI_ARCH_FLAGS,MPI_ARCH_INC,MPI_ARCH_LIBS need to be set
#The suggestions from the link are: (only those that work for this installation are left alive)
## && echo 'export MPI_ARCH_FLAGS="-DMPICH_SKIP_MPICXX"' >> ${OFPREFS} \
## && echo 'export MPI_ARCH_INC="-I/usr/include/mpich"' >> ${OFPREFS} \
## && echo 'export MPI_ARCH_LIBS="-L/usr/lib/x86_64-linux-gnu -lmpich"' >> ${OFPREFS} \
#--The suggestions from the file mplibMPICH are: (only those that work are left alive)
 && echo 'export MPI_ARCH_FLAGS="-DMPICH_SKIP_MPICXX -DOMPI_SKIP_MPICXX"' >> ${OFPREFS} \
## && echo 'export MPI_ARCH_INC="-isystem $MPI_ROOT/include"' >> ${OFPREFS} \
## && echo 'export MPI_ARCH_LIBS="-L${MPI_ROOT}/lib${WM_COMPILER_LIB_ARCH} -L${MPI_ROOT}/lib -lmpi -lrt"' >> ${OFPREFS} \
#--Even further modifications needed are: (only those that work are left alive)
##AEG:Gcc7 has problems with the -isystem flag. Using -I instead:
 && echo 'export MPI_ARCH_INC="-I ${MPI_ROOT}/include"' >> ${OFPREFS} \
##AEG:Only one library path and using -lmpich
## && echo 'export MPI_ARCH_LIBS="-L$MPI_ROOT/lib -lmpich"' >> ${OFPREFS} \
##AEG:The two library paths and using -lmpich
 && echo 'export MPI_ARCH_LIBS="-L${MPI_ROOT}/lib${WM_COMPILER_LIB_ARCH} -L${MPI_ROOT}/lib -lmpich -lrt"' >> ${OFPREFS} \
#--Dummy line:
 && echo ''

#...........
#Modifying the bashrc file
#Changing the installation directory within the bashrc file (This is not in the openfoamwiki instructions)
RUN sed -i '/^projectDir="$HOME.*/aprojectDir="'"${OFINSTDIR}"'/OpenFOAM-$WM_PROJECT_VERSION"' ${OFBASHRC} \
 && sed -i '0,/^projectDir="$HOME/s//# projectDir="$HOME/' ${OFBASHRC} \
#" (This comment line is needed to let vi to show the right syntax)
#Changing the WM_PROJECT_USER_DIR directory within the bashrc file 
#IMPORTANT:You have two options:
#   1. You can mount a directory of your local-host into this directory (as explained at the end of the Dockerfile)
#   2. Or you can include and build stuff inside the container and save it as your own image for later use.
 && sed -i '/^export WM_PROJECT_USER_DIR=.*/aexport WM_PROJECT_USER_DIR="'"${OFUSERDIR}/ofuser"'-$WM_PROJECT_VERSION"' ${OFBASHRC} \
 && sed -i '0,/^export WM_PROJECT_USER_DIR/s//# export WM_PROJECT_USER_DIR/' ${OFBASHRC} \
#" (This comment line is needed to let vi to show the right syntax)
#--Dummy line:
 && echo ''

#...........
#Step 4.
#Install one or the other: paraview or VTK
#Install paraview or VTK for runTimePostprocessing of OpenFOAM to properly compile
#Install paraview for catalyst module to properly compile (wont work with just VTK)
#Install paraview for graphical postprocessing to be available in the container 

##@@-@@#:#AEG: So far, I have only succeeded installing VTK
##@@-@@#:##VTK compilation (Adapted alternative instructions)
##@@-@@#:ARG exaFile=makeVTK.example
##@@-@@#:ARG conFile=makeVTK.container
##@@-@@#:RUN . ${OFBASHRC} \
##@@-@@#:#AEG: recomendation in the ThirdParty-xx/README.md:
##@@-@@#: && $WM_PROJECT_DIR/wmake/src/Allmake \
##@@-@@#: && cd $WM_THIRD_PARTY_DIR \
##@@-@@#:#AEG: wiki instructions recommend to set this variable for paraview, but I'm skipping the setting
##@@-@@#:# && export QT_SELECT=qt5 \
##@@-@@#:#AEG: trick to create a VTK "folder", which is indeed a link to the VTK provided in the ThirdParty paraview
##@@-@@#: && ln -s ParaView-v5.6.3/VTK VTK-8.2.0 \
##@@-@@#:#AEG: will use the conFile to run the installation
##@@-@@#: && cp $exaFile $conFile \
##@@-@@#:#AEG: scritps are failing in /bin/sh
##@@-@@#: && sed -i '\,^#!/bin/sh.*,i#!/bin/bash' $conFile \
##@@-@@#: && sed -i 's,^#!/bin/sh,###!/bin/sh,' $conFile \
##@@-@@#:#AEG: system mesa is 19.2.1, but setting is really for ThirdParty mesa, so it is not needed
##@@-@@#:# && sed -i '/^mesa=.*/amesa=mesa-19.2.1' $conFile \
##@@-@@#: && sed -i '0,/^mesa/s//# mesa/' $conFile \ 
##@@-@@#:#AEG: removing the mesa set up and the weird vtk line
##@@-@@#: && sed -i -e '/-osmesa/d' -e '/-mesa-prefix/d' -e '/$vtk/d' $conFile \
##@@-@@#:#AEG: makeVTK is still called by $conFile, but  scritps are failing in /bin/sh
##@@-@@#: && sed -i '\,^#!/bin/sh.*,i#!/bin/bash' makeVTK \
##@@-@@#: && sed -i 's,^#!/bin/sh,###!/bin/sh,' makeVTK \
##@@-@@#: && ./$conFile 2>&1 | tee log.makeVTK

##Paraview compilation (Official instructions for v1912)(not working for me yet, may need many adaptations as for VTK above)
##-##:RUN . ${OFBASHRC} \
##-##:#AEG: recomendation in the ThirdParty-xx/README.md:
##-##: && $WM_PROJECT_DIR/wmake/src/Allmake \
##-##: && cd $WM_THIRD_PARTY_DIR \
##-##: && ./makeParaView | tee log.makePV

##Paraview compilation (Adapted alternative instructions from OpenFoamWiki)(not working for me yet, may need many adaptations as for VTK above)
RUN . ${OFBASHRC} \
#AEG: recomendation in the ThirdParty-xx/README.md:
 && $WM_PROJECT_DIR/wmake/src/Allmake \
 && cd $WM_THIRD_PARTY_DIR \
 && export QT_SELECT=qt5 \
#AEG: makeParaView failing in /bin/sh
 && sed -i '\,^#!/bin/sh.*,i#!/bin/bash' makeParaView \
 && sed -i 's,^#!/bin/sh,###!/bin/sh,' makeParaView \
 && ./makeParaView -python -mpi -python-lib /usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0 2>&1 | tee log.makePV
RUN StopHere


#...........
#Step 5.
#Install Third Party tools (preferred to do it as a separate step and not together with the full openfoam compilation) 
#Updating the BOOST version to be used:
ARG OFCGAL=${OFINSTDIR}/OpenFOAM-${OFVERSION}/etc/config.sh/CGAL
RUN sed -i '/^boost_version=.*/aboost_version=boost_1_64_0' ${OFCGAL} \
 && sed -i '0,/^boost_version/s//# boost_version/' ${OFCGAL} \
#" (This comment line is needed to let vi to show the right syntax)
#--Dummy line:
 && echo ''

#Third party compilation
RUN . ${OFBASHRC} \
#AEG: recomendation in the ThirdParty-xx/README.md:
 && $WM_PROJECT_DIR/wmake/src/Allmake \
 && cd $WM_THIRD_PARTY_DIR \
 && ./Allwmake 2>&1 | tee log.Allwmake

#...........
#Step 6.
#OpenFOAM compilation
ENV WM_NCOMPPROCS=4
RUN . ${OFBASHRC} \
 && cd $WM_PROJECT_DIR \
 && ./Allwmake 2>&1 | tee log.Allwmake

#Obtaining a summary
RUN . ${OFBASHRC} \
 && cd $WM_PROJECT_DIR \
 && ./Allwmake 2>&1 | tee log.AllwmakeSummary

##OpenFOAM compilation (Adapted alternative instructions from OpenFoamWiki)
##-##:ARG OFNUMPROCOPTION="-j 4"
##-##:RUN . ${OFBASHRC} \
##-##: && cd $WM_PROJECT_DIR \
##-##: && export QT_SELECT=qt5 \
##-##: && ./Allwmake $OFNUMPROCOPTION 2>&1 | tee log.Allwmake
#
##Obtaining the summary of the OpenFOAM compilation
##-##:RUN . ${OFBASHRC} \
##-##: && cd $WM_PROJECT_DIR \
##-##: && export QT_SELECT=qt5 \
##-##: && ./Allwmake $OFNUMPROCOPTION 2>&1 | tee log.AllwmakeSummary

#...........
#Step 7.
#Defining defaults of the controlDict
ARG OFCONTROL=${OFINSTDIR}/OpenFOAM-${OFVERSION}/etc/controlDict
#...........
#Modifying the default controlDict file
#Setting collated as default for fileHandler
RUN sed -i '\@fileHandler uncollated;@a    fileHandler collated;' ${OFCONTROL} \
 && sed -i '0,\@fileHandler uncollated;@s@@// fileHandler uncollated;@' ${OFCONTROL} \
#--Dummy line:
 && echo ''

#...........
#Step 8.
##Checking if openfoam is working
RUN . ${OFBASHRC} \
 && cd $WM_PROJECT_DIR \
 && icoFoam -help 2>&1 | tee log.icoFoam

#Writing the environment variables for the installation so far:
RUN . ${OFBASHRC} \
 && cd $WM_PROJECT_DIR \
 && printenv > environment_vars_raw.env

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
# V. Final settings
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
#Trick for making apt-get work again. This is very weird.
#Following the solution proposed here:
#https://sillycodes.com/quick-tip-couldnt-create-temporary-file/
#But modified a little bit in order to  let apt-get install -y to work fine
# for further installations on top of this image
RUN apt-get clean \
 && rm -rf /var/lib/apt/lists/partial \
 && mkdir -p /var/lib/apt/lists/partial \
 && apt-get clean \
 && apt-get update

#...........
## Starting as ofuser by default
USER ofuser
WORKDIR /home/ofuser
