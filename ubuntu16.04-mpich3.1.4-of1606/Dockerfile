#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#All these come from the mpi-base docker file in
#https://github.com/Pawseyops/pawsey-dockerfiles/blob/master/mpi-base/Dockerfile
#mantained by brian skjerven
#AEG:original:FROM ubuntu:17.10
FROM ubuntu:16.04

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
RUN mpiexec -n 8 /tmp/mpich-build/mpich-3.1.4/examples/cpi


#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------


#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#All this was added for our openfoam container
##Use bash
SHELL ["/bin/bash", "-c"]

#Give a password to root.
#Examples from here:
#https://stackoverflow.com/questions/714915/using-the-passwd-command-from-within-a-shell-script
RUN echo "root:ofuser2016" | chpasswd

#Create the ofuser
RUN groupadd -g 999 ofuser \
 && useradd -r -m -u 999 -g ofuser ofuser
 
#Install necessary packages
#A warning will appear:
#debconf: delaying package configuration, since apt-utils is not installed
#But seems to be a bug:
#https://github.com/phusion/baseimage-docker/issues/319
#But harmless.
RUN apt-get update -qq\
 &&  apt-get -y --no-install-recommends install \
            wget \
            build-essential \
            binutils-dev \
##            mpich libmpich-dev \
            cmake flex bison zlib1g-dev qt4-dev-tools \
            libqt4-dev libqtwebkit-dev gnuplot \
            libreadline-dev libncurses-dev libxt-dev \
            libgmp-dev \
            libmpfr-dev python python-dev \
            libglu1-mesa-dev libqt4-opengl-dev \
## The following was needed to install  FlexLexer.h
            libfl-dev \
            vim time\
 && apt-get clean all \
 && rm -r /var/lib/apt/lists/*

#Change to the installation dir, change ot ofuser, download OpenFOAM and untar
WORKDIR /home/ofuser
ARG OFVERSION="v1606+"
USER ofuser
RUN mkdir -p /home/ofuser/OpenFOAM \
 && cd /home/ofuser/OpenFOAM \
 && wget --no-check-certificate -O OpenFOAM-${OFVERSION}.tgz \
    "http://downloads.sourceforge.net/openfoamplus/files/OpenFOAM-v1606%2B.tgz?use_mirror=mesh" \
 && wget --no-check-certificate -O ThirdParty-${OFVERSION}.tgz \
    "http://downloads.sourceforge.net/openfoamplus/files/ThirdParty-v1606%2B.tgz?use_mirror=mesh" \
 && tar -xvzf OpenFOAM-${OFVERSION}.tgz \
 && tar -xvzf ThirdParty-${OFVERSION}.tgz \
 && rm -f OpenFOAM-${OFVERSION}.tgz \
 && rm -f ThirdParty-${OFVERSION}.tgz

#Using a combination of the variable definition recommended here for system mpich
#https://bugs.openfoam.org/view.php?id=1167
#And in the file .../etc/config.sh/mpi
WORKDIR /home/ofuser/OpenFOAM
RUN echo 'export WM_MPLIB=SYSTEMMPI' >> ./OpenFOAM-${OFVERSION}/etc/config.sh/example/prefs.sh \
 && echo 'export MPI_ROOT="/usr"' >> ./OpenFOAM-${OFVERSION}/etc/config.sh/example/prefs.sh \
 && echo 'export MPI_ARCH_FLAGS="-DMPICH_SKIP_MPICXX"' >> ./OpenFOAM-${OFVERSION}/etc/config.sh/example/prefs.sh \
 && echo 'export MPI_ARCH_INC="-isystem $MPI_ROOT/include"' >> ./OpenFOAM-${OFVERSION}/etc/config.sh/example/prefs.sh \
 && echo 'export MPI_ARCH_LIBS="-L$MPI_ROOT/lib -lmpich"' >> ./OpenFOAM-${OFVERSION}/etc/config.sh/example/prefs.sh \
 && sed -i 's/WM_MPLIB=SYSTEMOPENMPI/WM_MPLIB=SYSTEMMPI/' ./OpenFOAM-${OFVERSION}/etc/bashrc

##Now following instructions from here: https://openfoamwiki.net/index.php/Installation/Linux/OpenFOAM%2B-v1606%2B/Ubuntu
##Third party compilation
WORKDIR /home/ofuser/OpenFOAM
RUN source ./OpenFOAM-${OFVERSION}/etc/config.sh/example/prefs.sh \
 && source ./OpenFOAM-${OFVERSION}/etc/bashrc \
 && cd $WM_THIRD_PARTY_DIR \
 && export QT_SELECT=qt4 \
 && sed -i -e 's=unset _foamAddPath=unset -f _foamAddPath=' makeFFTW \
 && ./Allwmake 2>&1 | tee log.make \
#AEG:DidNotWork: && wmREFRESH
#(adding next line instead)
 && . $WM_PROJECT_DIR/etc/bashrc $FOAM_SETTINGS

##Paraview compilation (for runtime postprocessing purposes)
WORKDIR /home/ofuser/OpenFOAM
RUN source ./OpenFOAM-${OFVERSION}/etc/config.sh/example/prefs.sh \
 && source ./OpenFOAM-${OFVERSION}/etc/bashrc \
 && cd $WM_THIRD_PARTY_DIR \
 && export QT_SELECT=qt4 \
 && ./makeParaView -python -mpi -python-lib /usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0 2>&1 | tee log.makePV \
#AEG:DidNotWork: && wmREFRESH
#(adding next line instead)
 && . $WM_PROJECT_DIR/etc/bashrc $FOAM_SETTINGS

##OpenFOAM compilation
WORKDIR /home/ofuser/OpenFOAM
RUN source ./OpenFOAM-${OFVERSION}/etc/config.sh/example/prefs.sh \
 && source ./OpenFOAM-${OFVERSION}/etc/bashrc \
 && cd $WM_PROJECT_DIR \
 && export QT_SELECT=qt4 \
 && ./Allwmake 2>&1 | tee log.make \
#AEG:DidNotWork: && wmREFRESH
#(adding next line instead)
 && . $WM_PROJECT_DIR/etc/bashrc $FOAM_SETTINGS

##Checking if openfoam is working
RUN source ./OpenFOAM-${OFVERSION}/etc/config.sh/example/prefs.sh \
 && source ./OpenFOAM-${OFVERSION}/etc/bashrc \
 && cd $WM_PROJECT_DIR \
 && icoFoam -help 2>&1 | tee log.icoFoam
#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------



#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
##Final step
# Delete the temporary files and directories
USER root
WORKDIR /
RUN rm -rf /tmp/*

USER ofuser
WORKDIR /home/ofuser/OpenFOAM
