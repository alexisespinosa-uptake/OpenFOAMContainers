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
ARG OFVERSION="7"
#Using bash from now on
SHELL ["/bin/bash","-c"]



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
#https://openfoam.org/download/source/
#
#Will NOT follow strictly the instructions for openfoam-7 available in the wiki:
#https://openfoamwiki.net/index.php/Installation/Linux/OpenFOAM-7/Ubuntu/18.04
#
#Then, Will follow a combination of both

#...........
#Definition of the installation directory within the container
ARG OFINSTDIR=/opt/OpenFOAM
ARG OFUSERDIR=/home/ofuser/OpenFOAM
WORKDIR $OFINSTDIR

#...........
#Step 1. From openfoamwiki instructions
#Install necessary packages
#
#A warning may appear:
#debconf: delaying package configuration, since apt-utils is not installed
#But seems to be a bug:
#https://github.com/phusion/baseimage-docker/issues/319
#But harmless.

RUN apt-get update -qq\
 &&  apt-get -y --no-install-recommends --no-install-suggests install \
#AEG: build-essential were already installed above for MPICH
#AEG:AlreadyInstalled:   build-essential\
   flex bison git-core cmake zlib1g-dev \
#AEG:(No third party boost is provided (although can be downloaded) but will use the system installation):
   libboost-system-dev libboost-thread-dev \
#AEG:No OpenMPI because installed above MPICH will be used
#AEG:NoOpenMPI:   libopenmpi-dev openmpi-bin \
   gnuplot libreadline-dev libncurses-dev \
   libqt5x11extras5-dev libxt-dev qt5-default qttools5-dev curl \
   freeglut3-dev libqtwebkit-dev \
#AEG:No scotch because it installs openmpi which later messes up with shifter at pawsey
#    Therefore, ThirdParty scotch is the one to be installed and used by openfoam.
#AEG:NoScotch:   libscotch-dev \
#AEG:(No third party CGAL is provided (although can be downloaded) but will use the system installation):
   libcgal-dev \
#AEG:These libraries are needed for CGAL (system and third party) (if needed, change libgmp-dev for libgmp3-dev):
   libgmp-dev libmpfr-dev\
#AEG:Wiki additional qt suggestions:
   qtbase5-dev \
#AEG: Some more suggestions from the wiki instructions:
   python python-dev \
   libglu1-mesa-dev \
#AEG:I found the following was needed to install  FlexLexer.hi (now included in the wiki instructions too):
   libfl-dev \
#AEG:I need wget to download ParaView (because automatic download with curl is failing) (wget already installed above with MPICH)
#AEG:AlreadyInstalled:   wget \
 && apt-get clean all \
 && rm -r /var/lib/apt/lists/*

#...........
#Step 2. Download
#Change to the installation dir, clone OpenFOAM directories
ARG OFVERSIONGIT=$OFVERSION
WORKDIR $OFINSTDIR
#Try git or https protocol:
##RUN git clone https://github.com/OpenFOAM/OpenFOAM-${OFVERSIONGIT}.git \
## && git clone https://github.com/OpenFOAM/ThirdParty-${OFVERSIONGIT}.git

RUN git clone git://github.com/OpenFOAM/OpenFOAM-${OFVERSIONGIT}.git \
 && git clone git://github.com/OpenFOAM/ThirdParty-${OFVERSIONGIT}.git

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
#And in the file .../OpenFOAM-<VERSION>/wmake/rules/General/mplibMPICH
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
 && echo 'export MPI_ARCH_FLAGS="-DMPICH_SKIP_MPICXX"' >> ${OFPREFS} \
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
RUN sed -i '/^export FOAM_INST_DIR=$HOME.*/aexport FOAM_INST_DIR='"${OFINSTDIR}" ${OFBASHRC} \
 && sed -i '0,/^export FOAM_INST_DIR=$HOME/s//# export FOAM_INST_DIR=$HOME/' ${OFBASHRC} \
#" (This comment line is needed to let vi to show the right syntax)
#Changing the WM_PROJECT_USER_DIR directory within the bashrc file 
#IMPORTANT: When compiling your own tools, you have two options:
#   1. You can mount a directory of your local-host into this directory
#   2. Or you can build a new container based on this one, and then include and build stuff
#      inside the new container for later use.
 && sed -i '/^export WM_PROJECT_USER_DIR=.*/aexport WM_PROJECT_USER_DIR="'"${OFUSERDIR}/ofuser"'-$WM_PROJECT_VERSION"' ${OFBASHRC} \
 && sed -i '0,/^export WM_PROJECT_USER_DIR/s//# export WM_PROJECT_USER_DIR/' ${OFBASHRC} \
#" (This comment line is needed to let vi to show the right syntax)
#--Dummy line:
 && echo ''

#...........
#Bashrc options to be used
ARG BASHRC_OPTIONS="FOAMY_HEX_MESH=yes"

#...........
#Step 4.
#Install one or the other: paraview or VTK
#Install paraview or VTK for runTimePostprocessing of OpenFOAM to properly compile
#Install paraview for graphical postprocessing to be available in the container
#Catalyst tools are not available for the foundation version

#AEG: foundation source files do not count with makeVTK script

##Paraview compilation (Using instructions from the wiki)
RUN . ${OFBASHRC} ${BASHRC_OPTIONS} \
 && cd $WM_THIRD_PARTY_DIR \
 && export QT_SELECT=qt5 \
#downloading ParaView with wget because the supposedly automatic download with curl is failing
#(Paraview download address pasted from ThirdParty-<Version>/README.org)
 && wget --no-check-certificate http://www.paraview.org/files/v5.6/ParaView-v5.6.0.tar.gz \
 && tar xvf ParaView-v5.6.0.tar.gz \
 && rm ParaView-v5.6.0.tar.gz \
 && mv ParaView-v5.6.0 ParaView-5.6.0 \
 && ./makeParaView -python -mpi -python-lib /usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0 2>&1 | tee log.makePV

#...........
#Step 5.
#Install Third Party tools (preferred to do it as a separate step and not together with the full openfoam compilation) 
#CGAL and boost first need to be downloaded from the sites given in ThirdParty/README.org
#@@-@@#:#Updating the BOOST version to be used:
#@@-@@#:ARG OFCGAL=${OFINSTDIR}/OpenFOAM-${OFVERSION}/etc/config.sh/CGAL
#@@-@@#:RUN sed -i '/^boost_version=.*/aboost_version=boost_1_64_0' ${OFCGAL} \
#@@-@@#: && sed -i '0,/^boost_version/s//# boost_version/' ${OFCGAL} \
#@@-@@#:#" (This comment line is needed to let vi to show the right syntax)
#@@-@@#:#--Dummy line:
#@@-@@#: && echo ''

#Third party compilation
RUN . ${OFBASHRC} ${BASHRC_OPTIONS} \
 && cd $WM_THIRD_PARTY_DIR \
 && ./Allwmake 2>&1 | tee log.Allwmake

#...........
#Step 6.
#OpenFOAM compilation
ARG OFNUMPROCOPTION="-j 4"
RUN . ${OFBASHRC} ${BASHRC_OPTIONS} \
 && cd $WM_PROJECT_DIR \
 && export QT_SELECT=qt5 \
 && ./Allwmake $OFNUMPROCOPTION 2>&1 | tee log.Allwmake

#Obtaining the summary of the OpenFOAM compilation as suggested in the openfoamwiki instructions
RUN . ${OFBASHRC} ${BASHRC_OPTIONS} \
 && cd $WM_PROJECT_DIR \
 && export QT_SELECT=qt5 \
 && ./Allwmake $OFNUMPROCOPTION 2>&1 | tee log.SummaryAllwmake

#...........
#Step 7.
#Defining Best Practices as defaults of the controlDict
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
RUN . ${OFBASHRC} ${BASHRC_OPTIONS} \
 && cd $WM_PROJECT_DIR \
 && icoFoam -help 2>&1 | tee log.icoFoam

#...........
#Writing the environment variables for the installation so far:
RUN . ${OFBASHRC} ${BASHRC_OPTIONS} \
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
