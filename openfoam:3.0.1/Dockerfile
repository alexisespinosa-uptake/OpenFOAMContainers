#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#This section was copy-pasted from the mpi-base docker file in
#https://github.com/Pawseyops/pawsey-dockerfiles/blob/master/mpi-base/Dockerfile
#mantained by brian skjerven
#AEG:ChangingOriginal:FROM ubuntu:17.10
FROM ubuntu:16.04
#AEG:ChangingOriginal:LABEL maintainer="brian.skjerven@pawsey.org.au"
LABEL maintainer="Alexis.Espinosa@pawsey.org.au"

# Add aarnet mirror to speed up package update
RUN perl -p -i.orig -e \
      's/archive.ubuntu.com/mirror.aarnet.edu.au\/pub\/ubuntu\/archive/' /etc/apt/sources.list \
      && sed -i '0,/# deb-src/{s/# deb-src/deb-src/}' /etc/apt/sources.list

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
#This section is for installing OpenFOAM-3.0.1
ARG OFVERSION="3.0.1"
ARG OFROOTDIR=/software/OpenFOAM
WORKDIR $OFROOTDIR
#Will follow instructions from here: https://openfoamwiki.net/index.php/Installation/Linux/OpenFOAM-3.0.1/Ubuntu
##Use bash
SHELL ["/bin/bash", "-c"]


#...........
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
#AEG:NoOpenMPI:        libopenmpi-dev openmpi-bin \
            libboost-system-dev libboost-thread-dev \
            libgmp-dev \
            libmpfr-dev python python-dev \
            libcgal-dev \
            libglu1-mesa-dev libqt4-opengl-dev \
#AEG:I found the following was needed to install  FlexLexer.h
            libfl-dev \
 && apt-get clean all \
 && rm -r /var/lib/apt/lists/*

#...........
#Change to the installation dir, download OpenFOAM and untar
ARG OFVERSIONFORGE=$OFVERSION
WORKDIR $OFROOTDIR
RUN wget --no-check-certificate -O OpenFOAM-${OFVERSION}.tgz \
    "http://downloads.sourceforge.net/foam/OpenFOAM-${OFVERSIONFORGE}.tgz?use_mirror=mesh" \
 && wget --no-check-certificate -O ThirdParty-${OFVERSION}.tgz \
    "http://downloads.sourceforge.net/foam/ThirdParty-${OFVERSIONFORGE}.tgz?use_mirror=mesh" \
 && tar -xvzf OpenFOAM-${OFVERSION}.tgz \
 && tar -xvzf ThirdParty-${OFVERSION}.tgz \
 && rm -f OpenFOAM-${OFVERSION}.tgz \
 && rm -f ThirdParty-${OFVERSION}.tgz

#...........
#AEG:Not defining the recommended softlinks to mpicc.openmpi and mpirun.openmpi in step 6 of the instructions

#...........
#Using a combination of the variable definition recommended here for system mpich
#https://bugs.openfoam.org/view.php?id=1167
#And in the file .../etc/config/mpi
RUN echo 'export WM_MPLIB=SYSTEMMPI' >> ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/config/example/prefs.sh \
 && echo 'export MPI_ROOT="/usr"' >> ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/config/example/prefs.sh \
 && echo 'export MPI_ARCH_FLAGS="-DMPICH_SKIP_MPICXX"' >> ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/config/example/prefs.sh \
 && echo 'export MPI_ARCH_INC="-isystem $MPI_ROOT/include"' >> ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/config/example/prefs.sh \
 && echo 'export MPI_ARCH_LIBS="-L$MPI_ROOT/lib -lmpich"' >> ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/config/example/prefs.sh \
 && sed -i 's/WM_MPLIB=SYSTEMOPENMPI/WM_MPLIB=SYSTEMMPI/' ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc

#...........
#Changing the installation directory within the bashrc file (This is not in the instructions)
RUN sed -i $'s@foamInstall=$HOME/$WM_PROJECT@# foamInstall=$HOME/$WM_PROJECT\\\nfoamInstall='"${OFROOTDIR}"'@' ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc \
#Changing the WM_PROJECT_USER_DIR directory within the bashrc file (because it is not clear who the user will be)
 && sed -i $'s@WM_PROJECT_USER_DIR=$HOME/$WM_PROJECT/$USER-$WM_PROJECT_VERSION@# WM_PROJECT_USER_DIR=$HOME/$WM_PROJECT/$USER-$WM_PROJECT_VERSION\\\nWM_PROJECT_USER_DIR='"${OFROOTDIR}/ofuser"'-$WM_PROJECT_VERSION@' ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc \
#Creating the $FOAM_USER_APPBIN & $FOAM_USER_LIBBIN directories for further use
 && . ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/config/example/prefs.sh \
 && . ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc \
 && mkdir -p $FOAM_USER_APPBIN \
 && mkdir -p $FOAM_USER_LIBBIN

#...........
##Third party compilation (not indicated in the instructions by mistake, but following the ThirdParty instructions from above the page for other ubuntu version)
RUN . ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/config/example/prefs.sh \
 && . ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc \
 && cd $WM_THIRD_PARTY_DIR \
 && export QT_SELECT=qt4 \
#AEG:ToBeRemoved: && sed -i -e 's=unset _foamAddPath=unset -f _foamAddPath=' makeFFTW \
 && ./Allwmake 2>&1 | tee log.make
#AEG:DidNotWork: && wmSET $FOAM_SETTINGS
#(adding next line instead)
#AEG:ToBeRemoved: && . $WM_PROJECT_DIR/etc/bashrc $FOAM_SETTINGS

#...........
##Paraview compilation (for runtime postprocessing purposes)
RUN . ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/config/example/prefs.sh \
 && . ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc \
 && cd $WM_THIRD_PARTY_DIR \
 && export QT_SELECT=qt4 \
 && ./makeParaView4 -python -mpi -python-lib /usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0 2>&1 | tee log.makePV
#AEG:DidNotWork: && wmSET $FOAM_SETTINGS
#(adding next line instead)
#AEG:ToBeRemoved: && . $WM_PROJECT_DIR/etc/bashrc $FOAM_SETTINGS

#...........
##A few fixes indicated in steps 11 and 12 of the instructions
RUN . ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/config/example/prefs.sh \
 && . ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc \
 && cd $WM_PROJECT_DIR \
 && find src applications -name "*.L" -type f | xargs sed -i -e 's=\(YY\_FLEX\_SUBMINOR\_VERSION\)=YY_FLEX_MINOR_VERSION < 6 \&\& \1=' \
 && mkdir -p $CGAL_ARCH_PATH \
 && mkdir -p $BOOST_ARCH_PATH

#...........
##OpenFOAM compilation
RUN . ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/config/example/prefs.sh \
 && . ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc \
 && cd $WM_PROJECT_DIR \
 && export QT_SELECT=qt4 \
 && ./Allwmake 2>&1 | tee log.make
#AEG:DidNotWork: && wmSET $FOAM_SETTINGS
#(adding next line instead)
#AEG:ToBeRemoved: && . $WM_PROJECT_DIR/etc/bashrc $FOAM_SETTINGS

#...........
##Obtaining the summary of the OpenFOAM compilation as suggested in the instructions
RUN . ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/config/example/prefs.sh \
 && . ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc \
 && cd $WM_PROJECT_DIR \
 && export QT_SELECT=qt4 \
 && ./Allwmake 2>&1 | tee log.makeSummary
#AEG:DidNotWork: && wmSET $FOAM_SETTINGS
#(adding next line instead)
#AEG:ToBeRemoved: && . $WM_PROJECT_DIR/etc/bashrc $FOAM_SETTINGS

#...........
##Checking if openfoam is working
RUN . ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/config/example/prefs.sh \
 && . ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc \
 && cd $WM_PROJECT_DIR \
 && icoFoam -help 2>&1 | tee log.icoFoam




#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
##Setting a user for interactive sessions and passwords
#Give a password to root.
#Examples from here:
#https://stackoverflow.com/questions/714915/using-the-passwd-command-from-within-a-shell-script
RUN echo "root:${OFVERSION}" | chpasswd


#Create the ofuser with the same password
RUN groupadd -g 999 ofuser \
 && useradd -r -m -u 999 -g ofuser ofuser
RUN echo "ofuser:${OFVERSION}" | chpasswd

# Automating the sourcing of the openfoam bashrc file for root and ofuser
#(Commented because, for the current version of shifter the environmental variables will need to be set
# manually with ENV commands. And, in order to check that the set up of all necessary variables is done
# properly, I will avoid the setting through the prefs.sh and bashrc files, and will use only the ENV
# declarations) 
####RUN echo "" >> $HOME/.bashrc \
#### && echo "#Sourcing openfoam setting files" >> $HOME/.bashrc \
#### && echo "source ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/config/example/prefs.sh" >> ${HOME}/.bashrc \
#### && echo "source ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc" >> ${HOME}/.bashrc \
#### && echo "" >> /home/ofuser/.bashrc \
#### && echo "#Sourcing openfoam setting files" >> /home/ofuser/.bashrc \
#### && echo "source ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/config/example/prefs.sh" >> /home/ofuser/.bashrc \
#### && echo "source ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc" >> /home/ofuser/.bashrc





#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
## If happy with the installation and want to remove temporary files, directories and logFiles
# (Comment lines during testing of creation in order to be able to take a look into the files)
RUN rm -rf /tmp \
 && source ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/config/example/prefs.sh \
 && source ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc \
 && rm $WM_THIRD_PARTY_DIR/log.make \
 && rm $WM_THIRD_PARTY_DIR/log.makePV \
 && rm $WM_PROJECT_DIR/log.make \
 && rm $WM_PROJECT_DIR/log.makeSummary \
 && rm $WM_PROJECT_DIR/log.icoFoam


#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#New Stuff added here during development but that needs to be added above for the final version of the Dockerfile
#...........
#WORKDIR /software
#RUN chmod -R 6777 OpenFOAM


#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#...........
#Changing the installation directory within the bashrc file (This is not in the instructions)
RUN sed -i $'s@foamInstall=$HOME/$WM_PROJECT@# foamInstall=$HOME/$WM_PROJECT\\\nfoamInstall='"${OFROOTDIR}"'@' ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc \
#Changing the WM_PROJECT_USER_DIR directory within the bashrc file (because it is not clear who the user will be)
#This directory needs to be mounted when running the container in order for it to exist
#AEG.OJO:Remove the # in the first part of the following sed
 && sed -i $'s@export # WM_PROJECT_USER_DIR=$HOME/$WM_PROJECT/$USER-$WM_PROJECT_VERSION@#export WM_PROJECT_USER_DIR=$HOME/$WM_PROJECT/$USER-$WM_PROJECT_VERSION\\\nexport WM_PROJECT_USER_DIR='"${OFROOTDIR}/ofuser"'-$WM_PROJECT_VERSION@' ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc
#AEG.OJO:Remove the following line too when this is in the right place
RUN sed -i $'s@^WM_PROJECT_USER_DIR@# WM_PROJECT_USER_DIR@' ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc


#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
## Hardcoding the environmental variables to run openfoam:
#  1.  In an interactive session, su ofuser, source ^/etc/config/example/prefs.sh and ^/etc/bashrc 
#  2.  Test that openfoam is workin properly
#  3.  Then printenv > myFile
#  4.  Order the variables alphabetically (important for checking that all the variables survive in shifter)
#  5.  Copy paste the environmental variables shown in the sorted myFile into this Dockerfile.
#  6.  Add ENV at the beggining of all lines
#  7.  Remove unnecesary variables (not related to openfoam)
#  8.  Use double quotes for variablse with spaces (for example for flags)
ENV BOOST_ARCH_PATH=/software/OpenFOAM/ThirdParty-3.0.1/platforms/linux64Gcc/boost-system
ENV CGAL_ARCH_PATH=/software/OpenFOAM/ThirdParty-3.0.1/platforms/linux64Gcc/CGAL-4.7
ENV FOAM_APP=/software/OpenFOAM/OpenFOAM-3.0.1/applications
ENV FOAM_APPBIN=/software/OpenFOAM/OpenFOAM-3.0.1/platforms/linux64GccDPInt32Opt/bin
ENV FOAM_ETC=/software/OpenFOAM/OpenFOAM-3.0.1/etc
ENV FOAM_EXT_LIBBIN=/software/OpenFOAM/ThirdParty-3.0.1/platforms/linux64GccDPInt32Opt/lib
ENV FOAM_INST_DIR=/software/OpenFOAM
ENV FOAM_JOB_DIR=/software/OpenFOAM/jobControl
ENV FOAM_LIBBIN=/software/OpenFOAM/OpenFOAM-3.0.1/platforms/linux64GccDPInt32Opt/lib
ENV FOAM_MPI=mpi-system
ENV FOAM_RUN=/software/OpenFOAM/ofuser-3.0.1/run
ENV FOAM_SETTINGS=
ENV FOAM_SIGFPE=
ENV FOAM_SITE_APPBIN=/software/OpenFOAM/site/3.0.1/platforms/linux64GccDPInt32Opt/bin
ENV FOAM_SITE_LIBBIN=/software/OpenFOAM/site/3.0.1/platforms/linux64GccDPInt32Opt/lib
ENV FOAM_SOLVERS=/software/OpenFOAM/OpenFOAM-3.0.1/applications/solvers
ENV FOAM_SRC=/software/OpenFOAM/OpenFOAM-3.0.1/src
ENV FOAM_TUTORIALS=/software/OpenFOAM/OpenFOAM-3.0.1/tutorials
ENV FOAM_USER_APPBIN=/software/OpenFOAM/ofuser-3.0.1/platforms/linux64GccDPInt32Opt/bin
ENV FOAM_USER_LIBBIN=/software/OpenFOAM/ofuser-3.0.1/platforms/linux64GccDPInt32Opt/lib
ENV FOAM_UTILITIES=/software/OpenFOAM/OpenFOAM-3.0.1/applications/utilities
ENV LD_LIBRARY_PATH=/software/OpenFOAM/ThirdParty-3.0.1/platforms/linux64Gcc/boost-system/lib:/software/OpenFOAM/ThirdParty-3.0.1/platforms/linux64Gcc/CGAL-4.7/lib:/software/OpenFOAM/ThirdParty-3.0.1/platforms/linux64Gcc/gperftools-svn/lib:/software/OpenFOAM/ThirdParty-3.0.1/platforms/linux64Gcc/ParaView-4.4.0/lib/paraview-4.4:/software/OpenFOAM/OpenFOAM-3.0.1/platforms/linux64GccDPInt32Opt/lib/mpi-system:/software/OpenFOAM/ThirdParty-3.0.1/platforms/linux64GccDPInt32Opt/lib/mpi-system:/software/OpenFOAM/ofuser-3.0.1/platforms/linux64GccDPInt32Opt/lib:/software/OpenFOAM/site/3.0.1/platforms/linux64GccDPInt32Opt/lib:/software/OpenFOAM/OpenFOAM-3.0.1/platforms/linux64GccDPInt32Opt/lib:/software/OpenFOAM/ThirdParty-3.0.1/platforms/linux64GccDPInt32Opt/lib:/software/OpenFOAM/OpenFOAM-3.0.1/platforms/linux64GccDPInt32Opt/lib/dummy
ENV MPI_ARCH_FLAGS=-DMPICH_SKIP_MPICXX
ENV MPI_ARCH_INC="-isystem /usr/include"
ENV MPI_ARCH_LIBS="-L/usr/lib -lmpich"
ENV MPI_ARCH_PATH=/usr
ENV MPI_BUFFER_SIZE=20000000
ENV MPI_ROOT=/usr
ENV PATH=/software/OpenFOAM/ThirdParty-3.0.1/platforms/linux64Gcc/gperftools-svn/bin:/software/OpenFOAM/ThirdParty-3.0.1/platforms/linux64Gcc/ParaView-4.4.0/bin:/software/OpenFOAM/ofuser-3.0.1/platforms/linux64GccDPInt32Opt/bin:/software/OpenFOAM/site/3.0.1/platforms/linux64GccDPInt32Opt/bin:/software/OpenFOAM/OpenFOAM-3.0.1/platforms/linux64GccDPInt32Opt/bin:/software/OpenFOAM/OpenFOAM-3.0.1/bin:/software/OpenFOAM/OpenFOAM-3.0.1/wmake:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV PV_PLUGIN_PATH=/software/OpenFOAM/OpenFOAM-3.0.1/platforms/linux64GccDPInt32Opt/lib/paraview-4.4
ENV ParaView_DIR=/software/OpenFOAM/ThirdParty-3.0.1/platforms/linux64Gcc/ParaView-4.4.0
ENV ParaView_INCLUDE_DIR=/software/OpenFOAM/ThirdParty-3.0.1/platforms/linux64Gcc/ParaView-4.4.0/include/paraview-4.4
ENV ParaView_MAJOR=4.4
ENV ParaView_VERSION=4.4.0
ENV WM_ARCH=linux64
ENV WM_ARCH_OPTION=64
ENV WM_CC=gcc
ENV WM_CFLAGS="-m64 -fPIC"
ENV WM_COMPILER=Gcc
ENV WM_COMPILER_LIB_ARCH=64
ENV WM_COMPILE_OPTION=Opt
ENV WM_CXX=g++
ENV WM_CXXFLAGS="-m64 -fPIC"
ENV WM_DIR=/software/OpenFOAM/OpenFOAM-3.0.1/wmake
ENV WM_LABEL_OPTION=Int32
ENV WM_LABEL_SIZE=32
ENV WM_LDFLAGS=-m64
ENV WM_LINK_LANGUAGE=c++
ENV WM_MPLIB=SYSTEMMPI
ENV WM_OPTIONS=linux64GccDPInt32Opt
ENV WM_OSTYPE=POSIX
ENV WM_PRECISION_OPTION=DP
ENV WM_PROJECT=OpenFOAM
ENV WM_PROJECT_DIR=/software/OpenFOAM/OpenFOAM-3.0.1
ENV WM_PROJECT_INST_DIR=/software/OpenFOAM
ENV WM_PROJECT_USER_DIR=/software/OpenFOAM/ofuser-3.0.1
ENV WM_PROJECT_VERSION=3.0.1
ENV WM_THIRD_PARTY_DIR=/software/OpenFOAM/ThirdParty-3.0.1



#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
## Starting as ofuser by default
USER ofuser
WORKDIR /home/ofuser



#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#Example for compiling your own solver to be used with the container:
#1.When running the container, mount the host directory ...^/<user-3.0.1> into /software/OpenFOAM/ofuser-3.0.1
# (which is the WM_PROJECT_USER_DIR inside the container)
# Obviously, inside the directory ...^/<user>-3.0.1 within the local host, all the files and directories
#  should be as desired for your own development.
# The variables $FOAM_RUN $FOAM_USER_APPBIN and $FOAM_USER_LIBBIN are already pointing 
#  inside /software/OpenFOAM/ofuser-3.0.1 subdirectories.
# In my case, in order to mount my directory in docker for an interactive session for development I used:
# docker run -it -v 

