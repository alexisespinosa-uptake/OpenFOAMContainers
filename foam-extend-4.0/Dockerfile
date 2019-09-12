#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
# Initial main definition
FROM ubuntu:16.04
LABEL maintainer="Alexis.Espinosa@pawsey.org.au"
#foam-extend version to install
ARG OFVERSION="4.0"

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
#This section is for installing foam-extend
#Will follow instructions from here:
# https://openfoamwiki.net/index.php/Installation/Linux/foam-extend-$OFVERSION
# &&
# https://openfoamwiki.net/index.php/Installation/Linux/foam-extend-$OFVERSION/Ubuntu

#...........
#Definition of the installation directory within the container
ARG OFINSTDIR=/MySoftware/foam
ARG OFUSERDIR=/home/ofuser/foam
WORKDIR $OFINSTDIR

#...........
#Step . From openfoamwiki instructions
#Already as root

#...........
#Step . From openfoamwiki instructions for Ubuntu 16.04 (modified)
#Install necessary packages
#A warning may appear:
#debconf: delaying package configuration, since apt-utils is not installed
#But seems to be a bug:
#https://github.com/phusion/baseimage-docker/issues/319
#But harmless.
RUN apt-get update -qq\
 &&  apt-get -y --no-install-recommends --no-install-suggests install \
   git-core \
   build-essential binutils-dev cmake flex \
   zlib1g-dev qt4-dev-tools libqt4-dev libncurses5-dev libiberty-dev \
   libxt-dev rpm mercurial graphviz \ 
#AEG:NoBoost:   libboost-system-dev libboost-thread-dev \
#AEG:NoOpenMPI:   libopenmpi-dev openmpi-bin \
#AEG:No scotch because it installs openmpi which later messes up with shifter at pawsey
#    Therefore, ThirdParty scotch is the one to be installed and used by foam-extend.
#AEG:NoScotch:   libscotch-dev \
#AEG:Python has been already installed in Step B.(above)  python python-dev \
#AEG:I found the following was needed to install  FlexLexer.h
   libfl-dev \
 && apt-get clean all \
 && rm -r /var/lib/apt/lists/*

#...........
#Step . From openfoamwiki instructions (modified)
#Change to the installation dir, download foam-extend and untar
ARG OFVERSIONGIT=$OFVERSION
WORKDIR $OFINSTDIR
RUN git clone git://git.code.sf.net/p/foam-extend/foam-extend-${OFVERSIONGIT} foam-extend-${OFVERSIONGIT}

#...........
#Step . From openfoamwiki instructions (modified)
#AEG:Not defining the recommended softlinks

#...........
#Step Additional.
#Adapting settings for the use of the case: WM_MPLIB=SYSTEMMPI, which is not present in foam-extend-4.0
ARG MPIRULEFILE1=${OFINSTDIR}/foam-extend-${OFVERSION}/wmake/rules/General/mplibSYSTEMMPI
ARG MPIRULEFILE2=${OFINSTDIR}/foam-extend-${OFVERSION}/wmake/rules/linux64Gcc/mplibSYSTEMMPI
ARG OFSETTINGS=${OFINSTDIR}/foam-extend-${OFVERSION}/etc/settings.sh
RUN echo 'PFLAGS     = $(MPI_ARCH_FLAGS)' > ${MPIRULEFILE1} \
 && echo 'PINC       = $(MPI_ARCH_INC)' >> ${MPIRULEFILE1} \
 && echo 'PLIBS      = $(MPI_ARCH_LIBS)' >> ${MPIRULEFILE1} \
 && cp ${MPIRULEFILE1} ${MPIRULEFILE2} \
 && sed -i $'s@^OPENMPI)@SYSTEMMPI)\\\n    export FOAM_MPI=mpi-system\\\n    ;;\\\nOPENMPI)@' ${OFSETTINGS}

#...........
#Step . Definitions for the prefs and bashrc files.
ARG OFPREFS=${OFINSTDIR}/foam-extend-${OFVERSION}/etc/prefs.sh
ARG OFBASHRC=${OFINSTDIR}/foam-extend-${OFVERSION}/etc/bashrc
RUN head -23 ${OFINSTDIR}/foam-extend-${OFVERSION}/etc/prefs.sh-EXAMPLE > $OFPREFS \
 && echo '#------------------------------------------------------------------------------' >> ${OFPREFS} \
 && echo 'export WM_THIRD_PARTY_USE_BISON_27=1' >> ${OFPREFS}

#...........
#Step Additional.
#Using a combination of the variable definition recommended for the use of system mpich here:
#https://bugs.foam-extend.org/view.php?id=1167
#And in the file .../foam-extend-4.0/wmake/rules/General/mplibMPICH
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
 && echo 'export MPI_ARCH_LIBS="-L$MPI_ROOT/lib -lmpich"' >> ${OFPREFS}
##AEG: and making it similar to the rule in mplibMPICH
## && echo 'export MPI_ARCH_LIBS="-L${MPI_ROOT}/lib${WM_COMPILER_LIB_ARCH} -L${MPI_ROOT}/lib -lmpich -lrt"' >> ${OFPREFS}

#...........
#Step Additional
#Changing the installation directory within the bashrc file (This is not in the openfoamwiki instructions)
RUN sed -i -e '/^foamInstall=.*/afoamInstall='"${OFINSTDIR}" ${OFBASHRC} \
 && sed -i -e '0,/^foamInstall/s//# foamInstall/' ${OFBASHRC} \
#Changing the WM_PROJECT_USER_DIR directory within the bashrc file 
#IMPORTANT:You have two options:
#   1. You can mount a directory of your local-host into this directory (as explained at the end of the Dockerfile)
#   2. Or you can include and build stuff inside the container and save it as your own image for later use.
 && sed -i -e '/^export WM_PROJECT_USER_DIR=.*/aexport WM_PROJECT_USER_DIR='"${OFUSERDIR}"'/ofuser-$WM_PROJECT_VERSION' ${OFBASHRC} \
 && sed -i -e '0,/^export WM_PROJECT_USER_DIR/s//# export WM_PROJECT_USER_DIR/' ${OFBASHRC} \
 && sed -i -e '/^export FOAM_JOB_DIR=.*/aexport FOAM_JOB_DIR='"${OFUSERDIR}"'/jobControl' ${OFSETTINGS} \
 && sed -i -e '0,/^export FOAM_JOB_DIR/s//# export FOAM_JOB_DIR/' ${OFSETTINGS}

#...........
#Step . From openfoamwiki instructions
#Not needed 

#...........
#Step . From openfoamwiki instructions
#AEG: Comment one option or the other (Paraview or VTK). Smaller containers are generated without paraview,
#     but catalyst will not be available with it.

#-#UsingVTKInstead#-#:##Paraview compilation (used for runTimePostprocessing and catalyst module)
#-#UsingVTKInstead#-#:RUN . ${OFBASHRC} \
#-#UsingVTKInstead#-#: && cd $WM_THIRD_PARTY_DIR \
#-#UsingVTKInstead#-#: && export QT_SELECT=qt5 \
#-#UsingVTKInstead#-#: && ./makeParaView -python -mpi -python-lib /usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0 2>&1 | tee log.makePV
#-#UsingVTKInstead#-#:##No need for wmRefresh as settings will be lost outside this RUN command

#-#NotInstallingVTK#-#:##VTK compilation (instead of full Paraview for runTimePostprocessing)
#-#NotInstallingVTK#-#:RUN . ${OFBASHRC} \
#-#NotInstallingVTK#-#: && cd $WM_THIRD_PARTY_DIR \
#-#NotInstallingVTK#-#: && export QT_SELECT=qt5 \
#-#NotInstallingVTK#-#: && ln -s ParaView-v5.6.0/VTK VTK-8.2.0 \
#-#NotInstallingVTK#-#: && ./makeVTK 2>&1 | tee log.makeVTK
#-#NotInstallingVTK#-#:##No need for wmRefresh as settings will be lost outside this RUN command

#...........
#Step Additional
#Skipping the installation of Paraview (which is stage 4 of the ThirdParty stages)
ARG TPDIR=${OFINSTDIR}/foam-extend-${OFVERSION}/ThirdParty
RUN sed -i -e 's@^\.\/AllMake.stage4@#\.\/AllMake.stage4@' ${TPDIR}/AllMake \
 && sed -i -e 's@^\.\/AllMake.stage4@#\.\/AllMake.stage4@' ${TPDIR}/AllMake.pre

#...........
#Step .
#Note: will be done by parts

#...........
#Step 11.A (Additional) From openfoamwiki instructions (modified to only compile third party)
##Third party compilation (not indicated in the openfoamwiki but preferred to do it separately) 
ARG OFNUMPROCOPTION="-j 4"
RUN . ${OFBASHRC} \
 && cd $WM_THIRD_PARTY_DIR \
 && ./AllMake.pre 2>&1 | tee log.make.pre

#...........
#Step 11.B From openfoamwiki instructions
#foam-extend compilation
RUN . ${OFBASHRC} \
 && cd $WM_PROJECT_DIR \
 && ./Allwmake.firstInstall 2>&1 | tee log.make.firstInstall

#...........
#Step 11.C From openfoamwiki instructions
##Obtaining the summary of the foam-extend compilation as suggested in the openfoamwiki instructions
RUN . ${OFBASHRC} \
 && cd $WM_PROJECT_DIR \
 && ./Allwmake 2>&1 | tee log.make.second

#...........
#Step 12 From openfoamwiki instructions
##Checking if foam-extend is working
RUN . ${OFBASHRC} \
 && cd $WM_PROJECT_DIR \
 && icoFoam -help 2>&1 | tee log.icoFoam

#...........
#Writing the environment variables for the installation so far:
RUN . ${OFBASHRC} \
 && cd $WM_PROJECT_DIR \
 && printenv > environment_vars_raw.env

#...........
#Create the foam-extend user directory
USER ofuser
RUN mkdir -p ${OFUSERDIR}/ofuser-${OFVERSION} \
 && chmod -R 777 ${OFUSERDIR}
USER root

#...........
#Allowing normal users to read,write and execute on the OF installation
RUN chmod -R 777 $OFINSTDIR

#...........
# Automating the sourcing of the foam-extend prefs.sh and bashrc files for root and ofuser
#(Now Commented because, for the current version of shifter the environmental variables will need to be set
# manually with ENV commands. And, in order to check that the set up of all necessary variables is done
# properly, I will avoid the setting through the use of prefs.sh and bashrc files, and will use only the ENV
# declarations that will appear in the final section below) 
####RUN echo "" >> $HOME/.bashrc \
#### && echo "#Sourcing foam-extend setting files" >> $HOME/.bashrc \
#### && echo "source ${OFBASHRC}" >> ${HOME}/.bashrc \
#### && echo "" >> /home/ofuser/.bashrc \
#### && echo "#Sourcing foam-extend setting files" >> /home/ofuser/.bashrc \
#### && echo "source ${OFBASHRC}" >> /home/ofuser/.bashrc


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
ENV BISON_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/bison-2.7/platforms/linux64GccDPOpt
#WillBeDefinedAtTheEndDueToShifterFailure:ENV FOAM_APPBIN=/MySoftware/foam/foam-extend-4.0/applications/bin/linux64GccDPOpt
ENV FOAM_APP=/MySoftware/foam/foam-extend-4.0/applications
ENV FOAM_DEV=1
ENV FOAM_INST_DIR=/MySoftware/foam
ENV FOAM_JOB_DIR=/home/ofuser/foam/jobControl
#WillBeDefinedAtTheEndDueToShifterFailure:ENV FOAM_LIBBIN=/MySoftware/foam/foam-extend-4.0/lib/linux64GccDPOpt
ENV FOAM_LIB=/MySoftware/foam/foam-extend-4.0/lib
ENV FOAM_MPI=mpi-system
ENV FOAM_RUN=/home/ofuser/foam/ofuser-4.0/run
ENV FOAM_SIGFPE=
ENV FOAM_SITE_APPBIN=/MySoftware/foam/site/4.0/bin/linux64GccDPOpt
ENV FOAM_SITE_DIR=/MySoftware/foam/site/4.0
ENV FOAM_SITE_LIBBIN=/MySoftware/foam/site/4.0/lib/linux64GccDPOpt
ENV FOAM_SOLVERS=/MySoftware/foam/foam-extend-4.0/applications/solvers
ENV FOAM_SRC=/MySoftware/foam/foam-extend-4.0/src
ENV FOAM_TEST_HARNESS_DIR=/MySoftware/foam/foam-extend-4.0/testHarness/foam-extend/4.0
ENV FOAM_TUTORIALS=/MySoftware/foam/foam-extend-4.0/tutorials
ENV FOAM_USER_APPBIN=/home/ofuser/foam/ofuser-4.0/applications/bin/linux64GccDPOpt
ENV FOAM_USER_LIBBIN=/home/ofuser/foam/ofuser-4.0/lib/linux64GccDPOpt
ENV FOAM_UTILITIES=/MySoftware/foam/foam-extend-4.0/applications/utilities
ENV HWLOC_BIN_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/hwloc-1.10.1/platforms/linux64GccDPOpt/bin
ENV HWLOC_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/hwloc-1.10.1/platforms/linux64GccDPOpt
ENV LD_LIBRARY_PATH=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/bison-2.7/platforms/linux64GccDPOpt/lib:/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/scotch-6.0.4/platforms/linux64GccDPOpt/lib:/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/ParMGridGen-1.0/platforms/linux64GccDPOpt/lib:/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/parmetis-4.0.3/platforms/linux64GccDPOpt/lib:/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/metis-5.1.0/platforms/linux64GccDPOpt/lib:/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/mesquite-2.1.2/platforms/linux64GccDPOpt/lib:/home/ofuser/foam/ofuser-4.0/lib/linux64GccDPOpt:/MySoftware/foam/site/4.0/lib/linux64GccDPOpt:/MySoftware/foam/foam-extend-4.0/lib/linux64GccDPOpt
ENV MESQUITE_BIN_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/mesquite-2.1.2/platforms/linux64GccDPOpt/bin
ENV MESQUITE_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/mesquite-2.1.2/platforms/linux64GccDPOpt
ENV MESQUITE_INCLUDE_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/mesquite-2.1.2/platforms/linux64GccDPOpt/include
ENV MESQUITE_LIB_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/mesquite-2.1.2/platforms/linux64GccDPOpt/lib
ENV METIS_BIN_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/metis-5.1.0/platforms/linux64GccDPOpt/bin
ENV METIS_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/metis-5.1.0/platforms/linux64GccDPOpt
ENV METIS_INCLUDE_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/metis-5.1.0/platforms/linux64GccDPOpt/include
ENV METIS_LIB_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/metis-5.1.0/platforms/linux64GccDPOpt/lib
ENV MPI_ARCH_FLAGS=-DMPICH_SKIP_MPICXX
ENV MPI_ARCH_INC="-I /usr/include"
ENV MPI_ARCH_LIBS="-L/usr/lib -lmpich"
ENV MPI_BUFFER_SIZE=20000000
ENV MPI_ROOT=/usr
ENV PARMETIS_BIN_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/parmetis-4.0.3/platforms/linux64GccDPOpt/bin
ENV PARMETIS_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/parmetis-4.0.3/platforms/linux64GccDPOpt
ENV PARMETIS_INCLUDE_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/parmetis-4.0.3/platforms/linux64GccDPOpt/include
ENV PARMETIS_LIB_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/parmetis-4.0.3/platforms/linux64GccDPOpt/lib
ENV PARMGRIDGEN_BIN_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/ParMGridGen-1.0/platforms/linux64GccDPOpt/bin
ENV PARMGRIDGEN_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/ParMGridGen-1.0/platforms/linux64GccDPOpt
ENV PARMGRIDGEN_INCLUDE_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/ParMGridGen-1.0/platforms/linux64GccDPOpt/include
ENV PARMGRIDGEN_LIB_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/ParMGridGen-1.0/platforms/linux64GccDPOpt/lib
ENV PATH=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/hwloc-1.10.1/platforms/linux64GccDPOpt/bin:/MySoftware/foam/foam-extend-4.0/ThirdParty/PyFoamSiteScripts/bin:/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/PyFoam-0.6.4/platforms/noarch/bin:/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/bison-2.7/platforms/linux64GccDPOpt/bin:/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/scotch-6.0.4/platforms/linux64GccDPOpt/bin:/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/mesquite-2.1.2/platforms/linux64GccDPOpt/bin:/home/ofuser/foam/ofuser-4.0/applications/bin/linux64GccDPOpt:/MySoftware/foam/site/4.0/bin/linux64GccDPOpt:/MySoftware/foam/foam-extend-4.0/applications/bin/linux64GccDPOpt:/MySoftware/foam/foam-extend-4.0/wmake:/MySoftware/foam/foam-extend-4.0/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV PYFOAM_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/PyFoam-0.6.4/platforms/noarch
ENV PYFOAM_SITE_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/PyFoamSiteScripts
ENV PYTHONPATH=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/PyFoam-0.6.4/platforms/noarch/lib/python2.7/site-packages:
ENV SCOTCH_BIN_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/scotch-6.0.4/platforms/linux64GccDPOpt/bin
ENV SCOTCH_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/scotch-6.0.4/platforms/linux64GccDPOpt
ENV SCOTCH_INCLUDE_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/scotch-6.0.4/platforms/linux64GccDPOpt/include
ENV SCOTCH_LIB_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty/packages/scotch-6.0.4/platforms/linux64GccDPOpt/lib
ENV WM_ARCH=linux64
ENV WM_ARCH_OPTION=64
ENV WM_CC=gcc
ENV WM_CFLAGS="-m64 -fPIC"
ENV WM_COMPILE_OPTION=Opt
#WillBeDefinedAtTheEndDueToShifterFailure:ENV WM_COMPILER_ARCH=
ENV WM_COMPILER=Gcc
ENV WM_COMPILER_LIB_ARCH=64
#WillBeDefinedAtTheEndDueToShifterFailure:ENV WM_CXXFLAGS="-m64 -fPIC"
ENV WM_CXX=g++
ENV WM_DIR=/MySoftware/foam/foam-extend-4.0/wmake
ENV WM_FORK=extend
ENV WM_LDFLAGS=-m64
ENV WM_LINK_LANGUAGE=c++
ENV WM_MPLIB=SYSTEMMPI
ENV WM_NCOMPPROCS=4
ENV WM_OPTIONS=linux64GccDPOpt
ENV WM_OSTYPE=POSIX
ENV WM_PRECISION_OPTION=DP
#WillBeDefinedAtTheEndDueToShifterFailure:ENV WM_PROJECT_DIR=/MySoftware/foam/foam-extend-4.0
ENV WM_PROJECT=foam
ENV WM_PROJECT_INST_DIR=/MySoftware/foam
ENV WM_PROJECT_USER_DIR=/home/ofuser/foam/ofuser-4.0
ENV WM_PROJECT_VERSION=4.0
ENV WM_THIRD_PARTY_DIR=/MySoftware/foam/foam-extend-4.0/ThirdParty
ENV WM_THIRD_PARTY_USE_BISON_27=1
ENV WM_THIRD_PARTY_USE_HWLOC_1101=1
ENV WM_THIRD_PARTY_USE_LIBCCMIO_261=1
ENV WM_THIRD_PARTY_USE_MESQUITE_212=1
ENV WM_THIRD_PARTY_USE_METIS_510=1
ENV WM_THIRD_PARTY_USE_OPENMPI_188=1
ENV WM_THIRD_PARTY_USE_PARAVIEW_440=1
ENV WM_THIRD_PARTY_USE_PARMETIS_403=1
ENV WM_THIRD_PARTY_USE_PARMGRIDGEN_10=1
ENV WM_THIRD_PARTY_USE_PYFOAM_064=1
ENV WM_THIRD_PARTY_USE_SCOTCH_604=1

#----------------------------:
#ii. Fixing shifter bug with environment variables.
#If loss of variables environment variables occurred to you,
#Comment the problematic variables in the list above and mark them with some tag like #WillBeDefinedAtTheEndDueToShifterFailure
#and define them at the end of the list (immediately below this comment)
#----------------------------:
ENV FOAM_APPBIN=/MySoftware/foam/foam-extend-4.0/applications/bin/linux64GccDPOpt
ENV FOAM_LIBBIN=/MySoftware/foam/foam-extend-4.0/lib/linux64GccDPOpt
ENV WM_COMPILER_ARCH=
ENV WM_CXXFLAGS="-m64 -fPIC"
ENV WM_PROJECT_DIR=/MySoftware/foam/foam-extend-4.0

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

