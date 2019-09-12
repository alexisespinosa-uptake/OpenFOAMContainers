#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#Initial main definintion
FROM ubuntu:16.04
LABEL maintainer="Alexis.Espinosa@pawsey.org.au"
#OpenFOAM version to install
ARG OFVERSION="v1606+"

#...........
#Using bash
SHELL ["/bin/bash","-c"]

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
# 0. Installation of mpich to work in Pawsey supercomputers

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
            bc \
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
## I. INSTALLING OPENFOAM.
#This section is for installing OpenFOAM
#Will follow instructions from here:
# https://openfoamwiki.net/index.php/Installation/Linux/OpenFOAM-$OFVERSION/Ubuntu


#...........
#Definition of the installation directory within the container
ARG OFINSTDIR=/MySoftware/OpenFOAM
ARG OFUSERDIR=/home/ofuser/OpenFOAM
WORKDIR $OFINSTDIR

#...........
#Step 1. From openfoamwiki instructions
#Already as root

#...........
#Step 2 & 3. From openfoamwiki instructions (modified)
#Install necessary packages
#A warning may appear:
#debconf: delaying package configuration, since apt-utils is not installed
#But seems to be a bug:
#https://github.com/phusion/baseimage-docker/issues/319
#But harmless.
RUN apt-get update -qq\
 &&  apt-get -y --no-install-recommends install \
            wget \
            build-essential \
            binutils-dev \
            cmake flex bison zlib1g-dev qt4-dev-tools \
            libqt4-dev libqtwebkit-dev gnuplot \
            libreadline-dev libncurses-dev libxt-dev \
#AEG:NoOpenMPI:   libopenmpi-dev openmpi-bin \
            libgmp-dev \
            libmpfr-dev \
#AEG:Python has been already installed in Step B.(above)  python python-dev \
            libglu1-mesa-dev libqt4-opengl-dev \
#AEG:I found the following was needed to install  FlexLexer.h
            libfl-dev \
 && apt-get clean all \
 && rm -r /var/lib/apt/lists/*

#...........
#Step 4 From openfoamwiki instructions (modified)
#No need to exit

#...........
#Step 5. From openfoamwiki instructions (modified)
#Change to the installation dir, download OpenFOAM and untar
ARG OFVERSIONFORGE=v1606%2B
WORKDIR $OFINSTDIR
RUN wget --no-check-certificate -O OpenFOAM-${OFVERSION}.tgz \
    "http://downloads.sourceforge.net/openfoamplus/files/OpenFOAM-v1606%2B.tgz?use_mirror=mesh" \
 && wget --no-check-certificate -O ThirdParty-${OFVERSION}.tgz \
    "http://downloads.sourceforge.net/openfoamplus/files/ThirdParty-v1606%2B.tgz?use_mirror=mesh" \
 && tar -xvzf OpenFOAM-${OFVERSION}.tgz \
 && tar -xvzf ThirdParty-${OFVERSION}.tgz \
 && rm -f OpenFOAM-${OFVERSION}.tgz \
 && rm -f ThirdParty-${OFVERSION}.tgz

#...........
#Step 7. From openfoamwiki instructions (modified)
#AEG:Not defining the recommended softlinks to mpicc.openmpi and mpirun.openmpi in step 6 of the instructions

#...........
#Step X. Definitions for the prefs and bashrc files.
ARG OFPREFS=${OFINSTDIR}/OpenFOAM-${OFVERSION}/etc/prefs.sh
ARG OFBASHRC=${OFINSTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc
RUN head -23 ${OFINSTDIR}/OpenFOAM-${OFVERSION}/etc/config.sh/example/prefs.sh > $OFPREFS \
 && echo '#------------------------------------------------------------------------------' >> ${OFPREFS}

#...........
#Step Additional.
#Using a combination of the variable definition recommended for the use of system mpich here:
#https://bugs.openfoam.org/view.php?id=1167
#And in the file .../OpenFOAM-v1812/wmake/rules/General/mplibMPICH
#(These MPI_* environmental variables are set in the prefs.sh as suggested in the link above,
# and this file is sourced automatically by the bashrc when the bashrc is sourced)
RUN echo 'export WM_MPLIB=SYSTEMMPI' >> ${OFPREFS} \
 && echo 'export MPI_ROOT="/usr"' >> ${OFPREFS} \
 && echo 'export MPI_ARCH_FLAGS="-DMPICH_SKIP_MPICXX"' >> ${OFPREFS} \
##AEG:Gcc7 has problems with the -isystem flag. I'm commenting the original approach
## && echo 'export MPI_ARCH_INC="-isystem $MPI_ROOT/include"' >> ${OFPREFS} \
##AEG: and using next line instead:
 && echo 'export MPI_ARCH_INC="-I ${MPI_ROOT}/include"' >> ${OFPREFS} \
##AEG:The suggestion from the link above is different from the usage in the rule mplibMPICH. I'm commenting it
## && echo 'export MPI_ARCH_LIBS="-L$MPI_ROOT/lib -lmpich"' >> ${OFPREFS}
##AEG: and making it similar to the rule in mplibMPICH
 && echo 'export MPI_ARCH_LIBS="-L${MPI_ROOT}/lib${WM_COMPILER_LIB_ARCH} -L${MPI_ROOT}/lib -lmpich -lrt"' >> ${OFPREFS}

#...........
#Step Additional
#Changing the installation directory within the bashrc file (This is not in the openfoamwiki instructions)
RUN sed -i -e '/^foamInstall=.*/afoamInstall='"${OFINSTDIR}" ${OFBASHRC} \
 && sed -i -e '0,/^foamInstall/s//# foamInstall/' ${OFBASHRC} \
#Changing the WM_PROJECT_USER_DIR directory within the bashrc file 
#IMPORTANT:You have two options:
#   1. You can mount a directory of your local-host into this directory (as explained at the end of the Dockerfile)
#   2. Or you can include and build stuff inside the container and save it as your own image for later use.
 && sed -i -e '/^export WM_PROJECT_USER_DIR=.*/aexport WM_PROJECT_USER_DIR='"${OFUSERDIR}/ofuser"'-$WM_PROJECT_VERSION' ${OFBASHRC} \
 && sed -i -e '0,/^export WM_PROJECT_USER_DIR/s//# export WM_PROJECT_USER_DIR/' ${OFBASHRC}

#...........
#Step 8. From openfoamwiki instructions

#...........
#Step 9. From openfoamwiki instructions
#Not needed 

#...........
#Step 10(.1,.2,.3&.4) From openfoamwiki instructions
#AEG: Comment one option or the other (Paraview or VTK). Smaller containers are generated without paraview,
#     but catalyst will not be available with it.

##Paraview compilation (used for runTimePostprocessing and catalyst module)
#-#UsingVTKInstead#-#:RUN . ${OFBASHRC} \
#-#UsingVTKInstead#-#: && cd $WM_THIRD_PARTY_DIR \
#-#UsingVTKInstead#-#: && export QT_SELECT=qt5 \
#-#UsingVTKInstead#-#: && ./makeParaView -python -mpi -python-lib /usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0 2>&1 | tee log.makePV
#-#UsingVTKInstead#-#:##No need for wmRefresh as settings will be lost outside this RUN command

##VTK compilation (instead of full Paraview for runTimePostprocessing)
#-#ThereIsNo_makeVTK_Script#-#:RUN . ${OFBASHRC} \
#-#ThereIsNo_makeVTK_Script#-#: && cd $WM_THIRD_PARTY_DIR \
#-#ThereIsNo_makeVTK_Script#-#: && export QT_SELECT=qt5 \
#-#ThereIsNo_makeVTK_Script#-#: && ln -s ParaView-v5.1.0/VTK VTK-8.1.0 \
#-#ThereIsNo_makeVTK_Script#-#: && ./makeVTK 2>&1 | tee log.makeVTK
#-#ThereIsNo_makeVTK_Script#-#:##No need for wmRefresh as settings will be lost outside this RUN command

#...........
#Step 11.
#Note: will be done by parts
#Note2: No system libraries are defined for the ThirdParty tools, even if some of them have been installed
#       like libcgal-dev. Then CGAL will be compiled from the ThirdParty packages.

#...........
#Step 11.A (Additional) From openfoamwiki instructions (modified to only compile third party)
##Third party compilation (not indicated in the openfoamwiki but preferred to do it separately) 
ARG OFNUMPROCOPTION="-j 4"
RUN . ${OFBASHRC} \
 && cd $WM_THIRD_PARTY_DIR \
 && export QT_SELECT=qt5 \
 && ./Allwmake $OFNUMPROCOPTION 2>&1 | tee log.make
##No need for wmRefresh as settings will be lost outside this RUN command

#...........
#Step 11.B From openfoamwiki instructions
#OpenFOAM compilation
RUN . ${OFBASHRC} \
 && cd $WM_PROJECT_DIR \
 && export QT_SELECT=qt5 \
 && ./Allwmake $OFNUMPROCOPTION 2>&1 | tee log.make

#...........
#Step 11.C From openfoamwiki instructions
##Obtaining the summary of the OpenFOAM compilation as suggested in the openfoamwiki instructions
RUN . ${OFBASHRC} \
 && cd $WM_PROJECT_DIR \
 && export QT_SELECT=qt5 \
 && ./Allwmake $OFNUMPROCOPTION 2>&1 | tee log.make

#...........
#Step 12 From openfoamwiki instructions
##Checking if openfoam is working
RUN . ${OFBASHRC} \
 && cd $WM_PROJECT_DIR \
 && icoFoam -help 2>&1 | tee log.icoFoam

#...........
#Writing the environment variables for the installation so far:
RUN . ${OFBASHRC} \
 && cd $WM_PROJECT_DIR \
 && printenv > environment_vars_raw.env

#...........
#Create the openfoam user directory
USER ofuser
RUN mkdir -p ${OFUSERDIR}/ofuser-${OFVERSION} \
 && chmod -R 777 ${OFUSERDIR}
USER root

#...........
#Allowing normal users to read,write and execute on the OF installation
RUN chmod -R 777 $OFINSTDIR

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
## II. HARDCODING THE ENVIRONMENTAL VARIABLES TO RUN OPENFOAM.
#
# Please follow the relevant document inside ../Documentation/ContainerCreation
#----------------------------:
# i. Copy&Paste the list of environmental variables below this comment.
#and before the ii. "Fixing" comment.
#IMPORTANT: In the first pass of creation of this container, all the ENV definitions should be removed or commented.
#           Then, after defining the list of ENV variables that will be used here, you should copy and paste them below:
#----------------------------:
ENV BOOST_ARCH_PATH=/MySoftware/OpenFOAM/ThirdParty-v1606+/platforms/linux64Gcc/boost_1_61_0
ENV CGAL_ARCH_PATH=/MySoftware/OpenFOAM/ThirdParty-v1606+/platforms/linux64Gcc/CGAL-4.8
ENV FFTW_ARCH_PATH=/MySoftware/OpenFOAM/ThirdParty-v1606+/platforms/linux64Gcc/fftw-3.3.4
#WillBeDefinedAtTheEndDueToShifterFailure:ENV FOAM_APPBIN=/MySoftware/OpenFOAM/OpenFOAM-v1606+/platforms/linux64GccDPInt32Opt/bin
ENV FOAM_APP=/MySoftware/OpenFOAM/OpenFOAM-v1606+/applications
ENV FOAM_ETC=/MySoftware/OpenFOAM/OpenFOAM-v1606+/etc
ENV FOAM_EXT_LIBBIN=/MySoftware/OpenFOAM/ThirdParty-v1606+/platforms/linux64GccDPInt32Opt/lib
ENV FOAM_INST_DIR=/MySoftware/OpenFOAM
ENV FOAM_JOB_DIR=/MySoftware/OpenFOAM/jobControl
ENV FOAM_LIBBIN=/MySoftware/OpenFOAM/OpenFOAM-v1606+/platforms/linux64GccDPInt32Opt/lib
ENV FOAM_MPI=mpi-system
ENV FOAM_RUN=/home/ofuser/OpenFOAM/ofuser-v1606+/run
ENV FOAM_SETTINGS=
ENV FOAM_SIGFPE=
ENV FOAM_SITE_APPBIN=/MySoftware/OpenFOAM/site/v1606+/platforms/linux64GccDPInt32Opt/bin
ENV FOAM_SITE_LIBBIN=/MySoftware/OpenFOAM/site/v1606+/platforms/linux64GccDPInt32Opt/lib
ENV FOAM_SOLVERS=/MySoftware/OpenFOAM/OpenFOAM-v1606+/applications/solvers
ENV FOAM_SRC=/MySoftware/OpenFOAM/OpenFOAM-v1606+/src
ENV FOAM_TUTORIALS=/MySoftware/OpenFOAM/OpenFOAM-v1606+/tutorials
ENV FOAM_USER_APPBIN=/home/ofuser/OpenFOAM/ofuser-v1606+/platforms/linux64GccDPInt32Opt/bin
ENV FOAM_USER_LIBBIN=/home/ofuser/OpenFOAM/ofuser-v1606+/platforms/linux64GccDPInt32Opt/lib
ENV FOAM_UTILITIES=/MySoftware/OpenFOAM/OpenFOAM-v1606+/applications/utilities
ENV LD_LIBRARY_PATH=/MySoftware/OpenFOAM/ThirdParty-v1606+/platforms/linux64Gcc/fftw-3.3.4/lib64:/MySoftware/OpenFOAM/ThirdParty-v1606+/platforms/linux64Gcc/CGAL-4.8/lib:/MySoftware/OpenFOAM/ThirdParty-v1606+/platforms/linux64Gcc/boost_1_61_0/lib:/MySoftware/OpenFOAM/ThirdParty-v1606+/platforms/linux64Gcc/gperftools-svn/lib:/MySoftware/OpenFOAM/ThirdParty-v1606+/platforms/linux64Gcc/ParaView-5.0.1/lib/paraview-5.0:/MySoftware/OpenFOAM/OpenFOAM-v1606+/platforms/linux64GccDPInt32Opt/lib/mpi-system:/MySoftware/OpenFOAM/ThirdParty-v1606+/platforms/linux64GccDPInt32Opt/lib/mpi-system:/home/ofuser/OpenFOAM/ofuser-v1606+/platforms/linux64GccDPInt32Opt/lib:/MySoftware/OpenFOAM/site/v1606+/platforms/linux64GccDPInt32Opt/lib:/MySoftware/OpenFOAM/OpenFOAM-v1606+/platforms/linux64GccDPInt32Opt/lib:/MySoftware/OpenFOAM/ThirdParty-v1606+/platforms/linux64GccDPInt32Opt/lib:/MySoftware/OpenFOAM/OpenFOAM-v1606+/platforms/linux64GccDPInt32Opt/lib/dummy
ENV MPI_ARCH_FLAGS=-DMPICH_SKIP_MPICXX
ENV MPI_ARCH_INC="-I /usr/include"
ENV MPI_ARCH_LIBS="-L/usr/lib -L/usr/lib -lmpich -lrt"
ENV MPI_ARCH_PATH=/usr
ENV MPI_BUFFER_SIZE=20000000
ENV MPI_ROOT=/usr
ENV ParaView_DIR=/MySoftware/OpenFOAM/ThirdParty-v1606+/platforms/linux64Gcc/ParaView-5.0.1
ENV ParaView_INCLUDE_DIR=/MySoftware/OpenFOAM/ThirdParty-v1606+/platforms/linux64Gcc/ParaView-5.0.1/include/paraview-5.0
ENV ParaView_MAJOR=5.0
ENV ParaView_VERSION=5.0.1
ENV PATH=/MySoftware/OpenFOAM/ThirdParty-v1606+/platforms/linux64Gcc/gperftools-svn/bin:/MySoftware/OpenFOAM/ThirdParty-v1606+/platforms/linux64Gcc/ParaView-5.0.1/bin:/home/ofuser/OpenFOAM/ofuser-v1606+/platforms/linux64GccDPInt32Opt/bin:/MySoftware/OpenFOAM/site/v1606+/platforms/linux64GccDPInt32Opt/bin:/MySoftware/OpenFOAM/OpenFOAM-v1606+/platforms/linux64GccDPInt32Opt/bin:/MySoftware/OpenFOAM/OpenFOAM-v1606+/bin:/MySoftware/OpenFOAM/OpenFOAM-v1606+/wmake:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV PV_PLUGIN_PATH=/MySoftware/OpenFOAM/OpenFOAM-v1606+/platforms/linux64GccDPInt32Opt/lib/paraview-5.0
ENV SCOTCH_ARCH_PATH=/MySoftware/OpenFOAM/ThirdParty-v1606+/platforms/linux64GccInt32/scotch_6.0.3
ENV SCOTCH_VERSION=scotch_6.0.3
ENV WM_ARCH=linux64
ENV WM_ARCH_OPTION=64
ENV WM_CC=gcc
ENV WM_CFLAGS="-m64 -fPIC"
ENV WM_COMPILE_OPTION=Opt
ENV WM_COMPILER=Gcc
ENV WM_COMPILER_LIB_ARCH=64
ENV WM_COMPILER_TYPE=system
#WillBeDefinedAtTheEndDueToShifterFailure:ENV WM_CXXFLAGS="-m64 -fPIC -std=c++0x"
ENV WM_CXX=g++
ENV WM_DIR=/MySoftware/OpenFOAM/OpenFOAM-v1606+/wmake
ENV WM_LABEL_OPTION=Int32
ENV WM_LABEL_SIZE=32
ENV WM_LDFLAGS=-m64
ENV WM_LINK_LANGUAGE=c++
ENV WM_MPLIB=SYSTEMMPI
ENV WM_OPTIONS=linux64GccDPInt32Opt
ENV WM_OSTYPE=POSIX
ENV WM_PRECISION_OPTION=DP
#WillBeDefinedAtTheEndDueToShifterFailure:ENV WM_PROJECT_DIR=/MySoftware/OpenFOAM/OpenFOAM-v1606+
#WillBeDefinedAtTheEndDueToShifterFailure:ENV WM_PROJECT_INST_DIR=/MySoftware/OpenFOAM
ENV WM_PROJECT=OpenFOAM
ENV WM_PROJECT_USER_DIR=/home/ofuser/OpenFOAM/ofuser-v1606+
ENV WM_PROJECT_VERSION=v1606+
ENV WM_THIRD_PARTY_DIR=/MySoftware/OpenFOAM/ThirdParty-v1606+

#----------------------------:
#ii. Fixing shifter bug with environment variables.
#If loss of variables environment variables occurred to you,
#Comment the problematic variables in the list above and mark them with some tag like #WillBeDefinedAtTheEndDueToShifterFailure
#and define them at the end of the list (immediately below this comment)
#----------------------------:
ENV FOAM_APPBIN=/MySoftware/OpenFOAM/OpenFOAM-v1606+/platforms/linux64GccDPInt32Opt/bin
ENV WM_CXXFLAGS="-m64 -fPIC -std=c++0x"
ENV WM_PROJECT_INST_DIR=/MySoftware/OpenFOAM
#----------------------------:
ENV WM_PROJECT_DIR=/MySoftware/OpenFOAM/OpenFOAM-v1606+

#...........
#Writing the environment variables for the installation so far:
RUN cd $WM_PROJECT_DIR \
 && printenv > environment_vars_defined.env

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
# Final configurations
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
