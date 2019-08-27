#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#Initial main definintion
FROM ubuntu:18.04
LABEL maintainer="Alexis.Espinosa@pawsey.org.au"
#OpenFOAM version to install
ARG OFVERSION="v1812"

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
#This section is for installing OpenFOAM
#Will follow instructions from here:
# https://openfoamwiki.net/index.php/Installation/Linux/OpenFOAM-$OFVERSION/Ubuntu
#But in this case there are no instructions for v1812 yet, so using those of v1806:
#https://openfoamwiki.net/index.php/Installation/Linux/OpenFOAM-v1806/Ubuntu


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
 &&  apt-get -y --no-install-recommends --no-install-suggests install \
   wget \
   build-essential flex bison cmake zlib1g-dev \
#AEG:NoBoost:   libboost-system-dev libboost-thread-dev \
#AEG:NoOpenMPI:   libopenmpi-dev openmpi-bin \
   gnuplot libreadline-dev libncurses-dev libxt-dev \
   qt5-default libqt5x11extras5-dev libqt5help5 qtdeclarative5-dev qttools5-dev \
   libqtwebkit-dev freeglut3-dev libqt5opengl5-dev texinfo \
#AEG:No scotch because it installs openmpi which later messes up with shifter at pawsey
#    Therefore, ThirdParty scotch is the one to be installed and used by openfoam.
#AEG:NoScotch:   libscotch-dev \
#AEG:Do not really want CGAL, as the ThirdParty version is the one to be used by openfoam,
#    but it is left alive because it installs some other libraries that are indeed used by
#    the ThirdParty installation. Other cleaner way would have been to install those libraries
#    by themselves.
   libcgal-dev \
#AEG:Python has been already installed in Step B.(above)  python python-dev \
   libglu1-mesa-dev \
#AEG:I found the following was needed to install  FlexLexer.h
   libfl-dev \
 && apt-get clean all \
 && rm -r /var/lib/apt/lists/*

#...........
#Step 4&5 From openfoamwiki instructions (modified)
#No virtual machine installation
#No need to exit

#...........
#Step 6. From openfoamwiki instructions (modified)
#Change to the installation dir, download OpenFOAM and untar
ARG OFVERSIONFORGE=$OFVERSION
WORKDIR $OFINSTDIR
RUN wget --no-check-certificate -O OpenFOAM-${OFVERSION}.tgz \
    "http://downloads.sourceforge.net/openfoamplus/files/OpenFOAM-${OFVERSIONFORGE}.tgz?use_mirror=mesh" \
 && wget --no-check-certificate -O ThirdParty-${OFVERSION}.tgz \
    "http://downloads.sourceforge.net/openfoamplus/files/ThirdParty-${OFVERSIONFORGE}.tgz?use_mirror=mesh" \
 && tar -xvzf OpenFOAM-${OFVERSION}.tgz \
 && tar -xvzf ThirdParty-${OFVERSION}.tgz \
 && rm -f OpenFOAM-${OFVERSION}.tgz \
 && rm -f ThirdParty-${OFVERSION}.tgz

#...........
#Step 7. From openfoamwiki instructions (modified)
#AEG:Not defining the recommended softlinks to mpicc.openmpi and mpirun.openmpi in step 6 of the instructions

#...........
#Step Additional.
#Using a combination of the variable definition recommended for the use of system mpich here:
#https://bugs.openfoam.org/view.php?id=1167
#And in the file .../OpenFOAM-v1812/wmake/rules/General/mplibMPICH
#(These MPI_* environmental variables are set in the prefs.sh as suggested in the link above,
# and this file is sourced automatically by the bashrc when the bashrc is sourced)
ARG OFPREFS=${OFINSTDIR}/OpenFOAM-${OFVERSION}/etc/prefs.sh
ARG OFBASHRC=${OFINSTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc
RUN cp ${OFINSTDIR}/OpenFOAM-${OFVERSION}/etc/config.sh/example/prefs.sh $OFPREFS \
 && sed -i $'s@^export WM_COMPILER_TYPE=ThirdParty@# export WM_COMPILER_TYPE=ThirdParty@' ${OFPREFS} \
 && sed -i $'s@^export WM_COMPILER=Clang@# export WM_COMPILER=Clang@' ${OFPREFS} \
 && sed -i $'s@^export WM_MPLIB=SYSTEMOPENMPI@# export WM_MPLIB=SYSTEMOPENMPI@' ${OFPREFS} \
 && echo '#------------------------------------------------------------------------------' >> ${OFPREFS} \
 && echo 'export WM_MPLIB=SYSTEMMPI' >> ${OFPREFS} \
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
RUN sed -i $'s@^projectDir="$HOME/OpenFOAM/OpenFOAM-$WM_PROJECT_VERSION"@# projectDir="$HOME/OpenFOAM/OpenFOAM-$WM_PROJECT_VERSION"\\\nprojectDir='"${OFINSTDIR}"'@' ${OFBASHRC} \
#Changing the WM_PROJECT_USER_DIR directory within the bashrc file 
#IMPORTANT:You have two options:
#   1. You can mount a directory of your local-host into this directory (as explained at the end of the Dockerfile)
#   2. Or you can include and build stuff inside the container and save it as your own image for later use.
 && sed -i $'s@^export WM_PROJECT_USER_DIR="$HOME/$WM_PROJECT/$USER-$WM_PROJECT_VERSION"@#export WM_PROJECT_USER_DIR="$HOME/$WM_PROJECT/$USER-$WM_PROJECT_VERSION"\\\nexport WM_PROJECT_USER_DIR="'"${OFUSERDIR}/ofuser"'-$WM_PROJECT_VERSION"@' ${OFBASHRC}

#...........
#Step 8. From openfoamwiki instructions (modified: adding the WM_LABEL_SIZE into the prefs.sh file)
#AEG. Commenting for using the default WM_LABEL_SIZE=32:RUN echo 'export WM_LABEL_SIZE=64' >> ${OFPREFS}

#...........
#Step 9. From openfoamwiki instructions
#Not needed 

#...........
#Step 10(.1,.2,.3&.4) From openfoamwiki instructions
#AEG: Comment one option or the other (Paraview or VTK). Smaller containers are generated without paraview,
#     but catalyst will not be available with it.

#-#UsingVTKInstead#-#:##Paraview compilation (used for runTimePostprocessing and catalyst module)
#-#UsingVTKInstead#-#:RUN . ${OFBASHRC} \
#-#UsingVTKInstead#-#: && cd $WM_THIRD_PARTY_DIR \
#-#UsingVTKInstead#-#: && export QT_SELECT=qt5 \
#-#UsingVTKInstead#-#: && ./makeParaView -python -mpi -python-lib /usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0 2>&1 | tee log.makePV
#-#UsingVTKInstead#-#:##No need for wmRefresh as settings will be lost outside this RUN command

##VTK compilation (instead of full Paraview for runTimePostprocessing)
RUN . ${OFBASHRC} \
 && cd $WM_THIRD_PARTY_DIR \
 && export QT_SELECT=qt5 \
 && ln -s ParaView-v5.6.0/VTK VTK-8.2.0 \
 && ./makeVTK 2>&1 | tee log.makeVTK
##No need for wmRefresh as settings will be lost outside this RUN command

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

#...........
# Automating the sourcing of the openfoam prefs.sh and bashrc files for root and ofuser
#(Now Commented because, for the current version of shifter the environmental variables will need to be set
# manually with ENV commands. And, in order to check that the set up of all necessary variables is done
# properly, I will avoid the setting through the use of prefs.sh and bashrc files, and will use only the ENV
# declarations that will appear in the final section below) 
####RUN echo "" >> $HOME/.bashrc \
#### && echo "#Sourcing openfoam setting files" >> $HOME/.bashrc \
#### && echo "source ${OFBASHRC}" >> ${HOME}/.bashrc \
#### && echo "" >> /home/ofuser/.bashrc \
#### && echo "#Sourcing openfoam setting files" >> /home/ofuser/.bashrc \
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
#(Replace all the existing ENV settings already in this file):
#----------------------------:
ENV BOOST_ARCH_PATH=/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64Gcc/boost_1_64_0
ENV CGAL_ARCH_PATH=/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64Gcc/CGAL-4.9.1
ENV FFTW_ARCH_PATH=/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64Gcc/fftw-3.3.7
#WillBeDefinedAtTheEndDueToShifterFailure:ENV FOAM_APPBIN=/MySoftware/OpenFOAM/OpenFOAM-v1812/platforms/linux64GccDPInt32Opt/bin
ENV FOAM_APP=/MySoftware/OpenFOAM/OpenFOAM-v1812/applications
ENV FOAM_ETC=/MySoftware/OpenFOAM/OpenFOAM-v1812/etc
ENV FOAM_EXT_LIBBIN=/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64GccDPInt32/lib
ENV FOAM_LIBBIN=/MySoftware/OpenFOAM/OpenFOAM-v1812/platforms/linux64GccDPInt32Opt/lib
ENV FOAM_MPI=mpi-system
ENV FOAM_RUN=/home/ofuser/OpenFOAM/ofuser-v1812/run
ENV FOAM_SITE_APPBIN=/MySoftware/OpenFOAM/OpenFOAM-v1812/site/v1812/platforms/linux64GccDPInt32Opt/bin
ENV FOAM_SITE_LIBBIN=/MySoftware/OpenFOAM/OpenFOAM-v1812/site/v1812/platforms/linux64GccDPInt32Opt/lib
ENV FOAM_SOLVERS=/MySoftware/OpenFOAM/OpenFOAM-v1812/applications/solvers
ENV FOAM_SRC=/MySoftware/OpenFOAM/OpenFOAM-v1812/src
ENV FOAM_TUTORIALS=/MySoftware/OpenFOAM/OpenFOAM-v1812/tutorials
ENV FOAM_USER_APPBIN=/home/ofuser/OpenFOAM/ofuser-v1812/platforms/linux64GccDPInt32Opt/bin
ENV FOAM_USER_LIBBIN=/home/ofuser/OpenFOAM/ofuser-v1812/platforms/linux64GccDPInt32Opt/lib
ENV FOAM_UTILITIES=/MySoftware/OpenFOAM/OpenFOAM-v1812/applications/utilities
ENV LD_LIBRARY_PATH=/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64Gcc/fftw-3.3.7/lib64:/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64Gcc/CGAL-4.9.1/lib64:/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64Gcc/boost_1_64_0/lib64:/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64Gcc/gperftools-2.5/lib64:/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64Gcc/VTK-8.2.0/lib:/MySoftware/OpenFOAM/OpenFOAM-v1812/platforms/linux64GccDPInt32Opt/lib/mpi-system:/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64GccDPInt32/lib/mpi-system:/home/ofuser/OpenFOAM/ofuser-v1812/platforms/linux64GccDPInt32Opt/lib:/MySoftware/OpenFOAM/OpenFOAM-v1812/site/v1812/platforms/linux64GccDPInt32Opt/lib:/MySoftware/OpenFOAM/OpenFOAM-v1812/platforms/linux64GccDPInt32Opt/lib:/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64GccDPInt32/lib:/MySoftware/OpenFOAM/OpenFOAM-v1812/platforms/linux64GccDPInt32Opt/lib/dummy
ENV MPI_ARCH_FLAGS=-DMPICH_SKIP_MPICXX
ENV MPI_ARCH_INC="-I /usr/include"
ENV MPI_ARCH_LIBS="-L/usr/lib64 -L/usr/lib -lmpich -lrt"
ENV MPI_ARCH_PATH=/usr
ENV MPI_ROOT=/usr
ENV PATH=/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64Gcc/gperftools-2.5/bin:/home/ofuser/OpenFOAM/ofuser-v1812/platforms/linux64GccDPInt32Opt/bin:/MySoftware/OpenFOAM/OpenFOAM-v1812/site/v1812/platforms/linux64GccDPInt32Opt/bin:/MySoftware/OpenFOAM/OpenFOAM-v1812/platforms/linux64GccDPInt32Opt/bin:/MySoftware/OpenFOAM/OpenFOAM-v1812/bin:/MySoftware/OpenFOAM/OpenFOAM-v1812/wmake:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV SCOTCH_ARCH_PATH=/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64GccDPInt32/scotch_6.0.6
ENV VTK_DIR=/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64Gcc/VTK-8.2.0
ENV WM_ARCH=linux64
ENV WM_ARCH_OPTION=64
ENV WM_CC=gcc
ENV WM_CFLAGS="-fPIC -m64"
ENV WM_COMPILE_OPTION=Opt
ENV WM_COMPILER=Gcc
ENV WM_COMPILER_LIB_ARCH=64
ENV WM_COMPILER_TYPE=system
#WillBeDefinedAtTheEndDueToShifterFailure:ENV WM_CXXFLAGS="-fPIC -std=c++11 -m64"
ENV WM_CXX=g++
ENV WM_DIR=/MySoftware/OpenFOAM/OpenFOAM-v1812/wmake
ENV WM_LABEL_OPTION=Int32
ENV WM_LABEL_SIZE=32
ENV WM_LDFLAGS=-m64
ENV WM_MPLIB=SYSTEMMPI
ENV WM_OPTIONS=linux64GccDPInt32Opt
ENV WM_PRECISION_OPTION=DP
#WillBeDefinedAtTheEndDueToShifterFailure:ENV WM_PROJECT_API=1812
#WillBeDefinedAtTheEndDueToShifterFailure:ENV WM_PROJECT_DIR=/MySoftware/OpenFOAM/OpenFOAM-v1812
ENV WM_PROJECT=OpenFOAM
ENV WM_PROJECT_USER_DIR=/home/ofuser/OpenFOAM/ofuser-v1812
ENV WM_PROJECT_VERSION=v1812
ENV WM_THIRD_PARTY_DIR=/MySoftware/OpenFOAM/ThirdParty-v1812

#----------------------------:
#ii. Fixing shifter bug with environment variables.
#If loss of variables environment variables occurred to you,
#Comment the problematic variables in the list above and mark them with some tag like #WillBeDefinedAtTheEndDueToShifterFailure
#and define them at the end of the list (immediately below this comment)
#----------------------------:
ENV FOAM_APPBIN=/MySoftware/OpenFOAM/OpenFOAM-v1812/platforms/linux64GccDPInt32Opt/bin
ENV WM_CXXFLAGS="-fPIC -std=c++11 -m64"
ENV WM_PROJECT_DIR=/MySoftware/OpenFOAM/OpenFOAM-v1812
ENV WM_PROJECT_API=1812

#...........
#Writing the environment variables for the installation so far:
RUN cd $WM_PROJECT_DIR \
 && printenv > environment_vars_defined.env
#---------------------------------------------------------------
#---------------------------------------------------------------
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

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
## Starting as ofuser by default
USER ofuser
WORKDIR /home/ofuser
