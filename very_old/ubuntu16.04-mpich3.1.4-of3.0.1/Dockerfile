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
RUN sed -i $'s@foamInstall=$HOME/$WM_PROJECT@# foamInstall=$HOME/$WM_PROJECT\\\nfoamInstall='"${OFROOTDIR}"'@' ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc

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
RUN echo "root:ofuser2016" | chpasswd


#Create the ofuser with the same password
RUN groupadd -g 999 ofuser \
 && useradd -r -m -u 999 -g ofuser ofuser
RUN echo "ofuser:ofuser2016" | chpasswd

# Automating the sourcing of the openfoam bashrc file for ofuser
RUN echo "source ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/config/example/prefs.sh" >> ${HOME}/.bashrc \
 && echo "source ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc" >> ${HOME}/.bashrc




#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
## If happy with the installation and want to remove temporary files, directories and logFiles
# (Comment lines during testing of installation)
###RUN rm -rf /tmp
###RUN . ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/config/example/prefs.sh \
### && . ${OFROOTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc \
### && rm $WM_THIRD_PARTY_DIR/log.make \
### && rm $WM_THIRD_PARTY_DIR/log.makePV \
### && rm $WM_PROJECT_DIR/log.make \
### && rm $WM_PROJECT_DIR/log.makeSummary \
### && rm $WM_PROJECT_DIR/log.icoFoam




#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
## Starting as ofuser by default
USER ofuser



