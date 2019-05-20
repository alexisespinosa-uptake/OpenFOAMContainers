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
   python python-dev \
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
#And in the file ...^/etc/config.sh/settings
#(These MPI_* environmental variables are set in the prefs.sh as suggested in the link above,
# and this file is sourced automatically the bashrc importing its settings)
ARG OFPREFS=${OFINSTDIR}/OpenFOAM-${OFVERSION}/etc/prefs.sh
ARG OFBASHRC=${OFINSTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc
RUN cp ${OFINSTDIR}/OpenFOAM-${OFVERSION}/etc/config.sh/example/prefs.sh $OFPREFS \
## && sed -i $'s@^export WM_MPLIB=SYSTEMOPENMPI@# export WM_MPLIB=SYSTEMOPENMPI\\\nWM_MPLIB=SYSTEMMPI@' ${OFBASHRC} \
 && sed -i $'s@^export WM_COMPILER_TYPE=ThirdParty@# export WM_COMPILER_TYPE=ThirdParty@' ${OFPREFS} \
 && sed -i $'s@^export WM_COMPILER=Clang@# export WM_COMPILER=Clang@' ${OFPREFS} \
 && sed -i $'s@^export WM_MPLIB=SYSTEMOPENMPI@# export WM_MPLIB=SYSTEMOPENMPI@' ${OFPREFS} \
 && echo '#------------------------------------------------------------------------------' >> ${OFPREFS} \
 && echo 'export WM_MPLIB=SYSTEMMPI' >> ${OFPREFS} \
 && echo 'export MPI_ROOT="/usr"' >> ${OFPREFS} \
 && echo 'export MPI_ARCH_FLAGS="-DMPICH_SKIP_MPICXX"' >> ${OFPREFS} \
##ProblemsWithGcc7.Using next line instead: && echo 'export MPI_ARCH_INC="-isystem $MPI_ROOT/include"' >> ${OFPREFS} \
 && echo 'export MPI_ARCH_INC="-I ${MPI_ROOT}/include"' >> ${OFPREFS} \
##MakingItSimilarToRule:mplibMPICH inNextLine: && echo 'export MPI_ARCH_LIBS="-L$MPI_ROOT/lib -lmpich"' >> ${OFPREFS}
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
RUN echo 'export WM_LABEL_SIZE=64' >> ${OFPREFS}

#...........
#Step 9. From openfoamwiki instructions
#Not needed 

#####...........
#####Step 10(.1,.2,.3&.4) From openfoamwiki instructions
######Paraview compilation (for runtime postprocessing purposes)
####RUN . ${OFBASHRC} \
#### && cd $WM_THIRD_PARTY_DIR \
#### && export QT_SELECT=qt5 \
#### && ./makeParaView -python -mpi -python-lib /usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0 2>&1 | tee log.makePV
######No need for wmRefresh as settings will be lost outside this RUN command

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
## Hardcoding the environmental variables to run openfoam.
# We have not found a way of sourcing the files openfoam configuration files at the startup of the container.
# These configuration files set the needed environmental variables for the usage
# of openfoam parallel tools within containers. But without a automatic sourcing at startup, shifter at Pawsey
# is not able to run openfoam in parallel.
#
# Then, the only way we have found for things to work is to define all the environmental variables
# within the Dockerfile using the ENV command. That is, instead of sourcing the configuration files, configure all
# the environmental variables when building the container, then avoiding the need of further sourcing of any configuration
# file.
#
# Furthermore, each version of openfoam may have different set-ups for these environmental variables,
# making it a harder task to define the environmental variables with an ideal "clean" definition.
# Then, we opted to follow this series of steps that have proven to be simple and effective to
# "hardcode" these variables for each specific version of openfoam from the very creation of the image.
#
#  In order to create the full list of environemntal variables to define, follow these steps:
#  0.  Create a container with the installation of openfoam, but without definition of any ENV variable for openfoam.
#      This container should be capable of running openfoam properly in an interactive docker session
#      (in your own desktop) by sourcing the prefs.sh and bashrc files as explained below.
#      (Then, if openfoam is working properly,
#      the environmental variables will be printed into a file, ordered, cleaned, copied and pasted into this Dockerfile,
#      as explained in the final steps. This will setup the container to be able to run openfoam without the need of sourcing the
#      configuration files, allowing shifter to work.)
#      0.1 Build the image, I used:
#          docker build -t alexisespinosa/openfoam:v1812 .
#      0.2 Run an interactive session (mount your current dir "$PWD" as /localDir,
#          and use your local user:group as user in order to have correct file permissions
#          to be visible from inside and outside the container):
#          docker run -it --rm -v $PWD:/localDir --user $(id -u):$(id -g) alexisespinosa/openfoam:v1812
#      (0.3) (Your prompt will say "I have no name", but that is fine as we forced to use your local user
#            in order to avoid messing with file permissions in the mounted directory)
#  1.  Within the interactive session, source the configuration file:
#      1.1 source the file bashrc (the full path is written above to define $OFBASHRC):
#            source /MySoftware/OpenFOAM/OpenFOAM-v1812/etc/bashrc
#  2.  Test that openfoam is working properly for the current user:
#      2.1 mkdir -p /localDir/run/tutorials
#      2.2 cp -rp $FOAM_TUTORIALS/incompressible/icoFoam/cavity/cavity /localDir/run/tutorials/
#      2.3 cd /localDir/run/tutorials/cavity
#      2.4 blockMesh
#      2.5 icoFoam
#  3.  If everything is working properly, then print the environment variables into a file in your local machine
#      (remember that /localDir is a mount of your desktop local working directory):
#      3.0 mkdir /localDir/variables
#      3.1 printenv > /localDir/variables/raw_vars.env
#      3.2 Now exit the container: exit
#  4.  Edit the file containing the variables and finally copy paste the list into this Dockerfile:
#      4.0 cd variables
#      4.1 Order the variables alphabetically (important for an easier check of variables within shifter in Pawsey):
#          sort raw_vars.env -o sorted_vars.env 
#      4.2 Remove unnecesary variables (not related to openfoam) within the sorted_vars.env file.
#          Varibles related to openfoam are: BOOST_*, CGAL_*,FFTW_*, FOAM_*,LD_*,MPI_*,ParaView_*,
#          PATH,PV_*,SCOTCH_*,WM_*:
#          cp sorted_vars.env cleaned_vars.env
#          vi cleaned_vars.env  
#      4.3 Use double quotes for variables with spaces (for example for flags) within cleaned_vars.env
#          For example: WM_CXXFLAGS=-m64 -fPIC -std=c++0x -> WM_CXXFLAGS="-m64 -fPIC -std=c++0x" 
#          (perform a search for blank spaces in the whole file to catch those variables).
#      4.4 Add the Docker command ENV at the beggining of all lines to set the environmental variables
#          For example: ENV WM_CXXFLAGS="-m64 -fPIC -std=c++0x" 
#          (column editing is very useful in this case, rather than typing ENV for each line)
#  5.  Copy paste the list of environmental variables within sorted_vars.env into this Dockerfile below these
#      instructions where indicated.
#      5.1 Find the "Copy&Paste" section below and paste the list there.
#  6.  Generate the openfoam image again as in 0.1 above.
#      6.1 docker build -t alexisespinosa/openfoam:v1812 .
#  7.  Test that openfoam works without the need of sourcing the configuration files:
#      7.1 docker run -it --rm -v $PWD:/localDir --user $(id -u):$(id -g) alexisespinosa/openfoam:v1812
#      7.2 DO NOT SOURCE ANY CONFIGURATION FILE
#      7.3 cd /localDir/run/tutorials/cavity
#      7.4 blockMesh
#      7.5 icoFoam
#      7.6 Check that everything ran correctly
#  8. OR (even better) test the container non interactively:
#      8.1 Outside the container, cd to the tutorial directory that should be in your local computer:
#          cd ./run/tutorials/cavity
#      8.2 remove the existing results:
#          rm -rf 0.*
#          (do not remove the 0 directory which has the initial conditions)
#      8.3 docker run --rm -v $PWD:/cavity -w /cavity --user $(id -u):$(id -g) alexisespinosa/openfoam:v1812 blockMesh
#      8.4 docker run --rm -v $PWD:/cavity -w /cavity --user $(id -u):$(id -g) alexisespinosa/openfoam:v1812 icoFoam
#      8.5 If everything ran fine, then this container is pretty much ready for Pawsey
#  9.  As a double check, print again the environmental variables and compare them with the first print (3. above)
#      and use them for the final check when printing the environmental variables while the container is
#      being ran by shifter in Pawsey.
#      9.1 You can execute the printenv in a command line non-interactive run:
#          docker run --rm -v $PWD:/localDir --user $(id -u):$(id -g) alexisespinosa/openfoam:v1812 bash -c 'printenv > /localDir/variables/raw_docker.env'
#      9.2 Order and clean the file as in instructions 4. above and generate a cleaned_docker.env file
#
#
#----------------------------:
#  5.1 Copy&Paste the list below this line. (Remove every active of commented ENV lines already existing in this file):
#----------------------------:
ENV BOOST_ARCH_PATH=/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64Gcc/boost_1_64_0
ENV CGAL_ARCH_PATH=/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64Gcc/CGAL-4.9.1
ENV FFTW_ARCH_PATH=/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64Gcc/fftw-3.3.7
#WillBeDefinedAtTheEndDueToShifterFailure:ENV FOAM_APPBIN=/MySoftware/OpenFOAM/OpenFOAM-v1812/platforms/linux64GccDPInt64Opt/bin
ENV FOAM_APP=/MySoftware/OpenFOAM/OpenFOAM-v1812/applications
ENV FOAM_ETC=/MySoftware/OpenFOAM/OpenFOAM-v1812/etc
ENV FOAM_EXT_LIBBIN=/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64GccDPInt64/lib
ENV FOAM_LIBBIN=/MySoftware/OpenFOAM/OpenFOAM-v1812/platforms/linux64GccDPInt64Opt/lib
ENV FOAM_MPI=mpi-system
ENV FOAM_RUN=/home/ofuser/OpenFOAM/ofuser-v1812/run
ENV FOAM_SITE_APPBIN=/MySoftware/OpenFOAM/OpenFOAM-v1812/site/v1812/platforms/linux64GccDPInt64Opt/bin
ENV FOAM_SITE_LIBBIN=/MySoftware/OpenFOAM/OpenFOAM-v1812/site/v1812/platforms/linux64GccDPInt64Opt/lib
ENV FOAM_SOLVERS=/MySoftware/OpenFOAM/OpenFOAM-v1812/applications/solvers
ENV FOAM_SRC=/MySoftware/OpenFOAM/OpenFOAM-v1812/src
ENV FOAM_TUTORIALS=/MySoftware/OpenFOAM/OpenFOAM-v1812/tutorials
ENV FOAM_USER_APPBIN=/home/ofuser/OpenFOAM/ofuser-v1812/platforms/linux64GccDPInt64Opt/bin
ENV FOAM_USER_LIBBIN=/home/ofuser/OpenFOAM/ofuser-v1812/platforms/linux64GccDPInt64Opt/lib
ENV FOAM_UTILITIES=/MySoftware/OpenFOAM/OpenFOAM-v1812/applications/utilities
ENV LD_LIBRARY_PATH=/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64Gcc/fftw-3.3.7/lib64:/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64Gcc/CGAL-4.9.1/lib64:/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64Gcc/boost_1_64_0/lib64:/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64Gcc/gperftools-2.5/lib64:/MySoftware/OpenFOAM/OpenFOAM-v1812/platforms/linux64GccDPInt64Opt/lib/mpi-system:/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64GccDPInt64/lib/mpi-system:/home/ofuser/OpenFOAM/ofuser-v1812/platforms/linux64GccDPInt64Opt/lib:/MySoftware/OpenFOAM/OpenFOAM-v1812/site/v1812/platforms/linux64GccDPInt64Opt/lib:/MySoftware/OpenFOAM/OpenFOAM-v1812/platforms/linux64GccDPInt64Opt/lib:/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64GccDPInt64/lib:/MySoftware/OpenFOAM/OpenFOAM-v1812/platforms/linux64GccDPInt64Opt/lib/dummy
ENV MPI_ARCH_FLAGS=-DMPICH_SKIP_MPICXX
ENV MPI_ARCH_INC="-I /usr/include"
ENV MPI_ARCH_LIBS="-L/usr/lib64 -L/usr/lib -lmpich -lrt"
ENV MPI_ARCH_PATH=/usr
ENV MPI_ROOT=/usr
ENV PATH=/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64Gcc/gperftools-2.5/bin:/home/ofuser/OpenFOAM/ofuser-v1812/platforms/linux64GccDPInt64Opt/bin:/MySoftware/OpenFOAM/OpenFOAM-v1812/site/v1812/platforms/linux64GccDPInt64Opt/bin:/MySoftware/OpenFOAM/OpenFOAM-v1812/platforms/linux64GccDPInt64Opt/bin:/MySoftware/OpenFOAM/OpenFOAM-v1812/bin:/MySoftware/OpenFOAM/OpenFOAM-v1812/wmake:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV SCOTCH_ARCH_PATH=/MySoftware/OpenFOAM/ThirdParty-v1812/platforms/linux64GccDPInt64/scotch_6.0.6
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
ENV WM_LABEL_OPTION=Int64
ENV WM_LABEL_SIZE=64
ENV WM_LDFLAGS=-m64
ENV WM_MPLIB=SYSTEMMPI
ENV WM_OPTIONS=linux64GccDPInt64Opt
ENV WM_PRECISION_OPTION=DP
#WillBeDefinedAtTheEndDueToShifterFailure:ENV WM_PROJECT_API=1812
#WillBeDefinedAtTheEndDueToShifterFailure:ENV WM_PROJECT_DIR=/MySoftware/OpenFOAM/OpenFOAM-v1812
ENV WM_PROJECT=OpenFOAM
ENV WM_PROJECT_USER_DIR=/home/ofuser/OpenFOAM/ofuser-v1812
ENV WM_PROJECT_VERSION=v1812
ENV WM_THIRD_PARTY_DIR=/MySoftware/OpenFOAM/ThirdParty-v1812

#---------------------------------------------------------------
#---------------------------------------------------------------
#Defining the lost variables here (at the end) due to shifter failure
#For some wicked reason, shifter is loosing the definition of some variables these variables are redefiened here:
ENV FOAM_APPBIN=/MySoftware/OpenFOAM/OpenFOAM-v1812/platforms/linux64GccDPInt64Opt/bin
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

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#For setting up your container in pawsey:
#0. Push the container to your repository
#   (This example considers my repository is "alexisespinosa", the image name is "openfoam"
#    and the tag is "v1812")
#   0.1: From your desktop where you built your docker image run:
#        docker push alexisespinosa/openfoam:v1812
#1. ssh to zeus or magnus: ssh espinosa@zeus.pawsey.org.au
#2. Run the following commands in zeus or magnus:
#   2.1 module load shifter/18.06.00
#   2.2 sg $PAWSEY_PROJECT -c 'shifter pull alexisespinosa/openfoam:v1812'
#   2.3 Execute a basic test (display the help message of icoFoam):
#       shifter run alexisespinosa/openfoam:v1812 icoFoam -help
#   2.4 Print the environmental variables when using shifter. VERY IMPORTANT:
#       For some weird reason, shifter may some variables when running the image.
#       If that happens, these variables need to be unset (as those marked with
#           "#WillBeDefinedAtTheEndDueToShifterFailure"
#       In the list of several "ENV"s above.
#       And then defined again in the section:
#           "Defining the lost variables here (at the end) due to shifter failure"
#       Order of definition is important to skip this shifter problem.
#       (More info is in the helpdesk ticket: GS-10054)
#       2.4.1 Execute the printenv:
#             shifter run alexisespinosa/openfoam:v1812 printenv > raw_shifter.env
#       2.4.2 Order and clean this list of variables as in instruction 4. above above and generate a cleaned_shifter.env file
#       2.4.3 Compare the two cleaned list of variables (scp the files into a common location first):
#             diff cleaned_docker.env cleaned_shifter.env
#       2.4.4 If diffences are detected, then comment the definition of those variables
#             And add the definition then at the section "Defining the lost variables .."
#             So that they are defined at the end of the list of ENV definitions.
#   2.5 Repeat the creation of the container as explained above above in the instructions: BUILDING THE CONTAINER    
#   2.6 Repeat this instructions (TESTING AT PAWSEY) until there are not lost variables
#3. Run a tutorial test case for openfoam (as explained below) and proceed with your own workflow if succeded
#       
#       

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#Example script for running openfoam:v1812 container:
#1. cd to the working directory (In this case, this working dir has the tutorial "damBreak")
#2. run the script: sbatch runContainer.sh
#   2.1 The script contains: (What is in the script is after the mark ##|):
##|#!/bin/bash -l
##|#SBATCH --export=NONE
##|#SBATCH --time=00:15:00
##|#SBATCH --ntasks=4
##|#SBATCH --partition=debugq
##|
##|module load shifter/18.06.00
##|#----------
##|#Setting some preliminary environmental variables
##|OF_VERSION=v1812
##|
##|echo "1: Creating the mesh:"
##|srun --export=all -n 1 shifter run alexisespinosa/openfoam:$OF_VERSION blockMesh
##|echo "2: Initializing fields:"
##|srun --export=all -n 1 shifter run alexisespinosa/openfoam:$OF_VERSION setFields
##|echo "3: Decomposing the case:"
##|srun --export=all -n 1 shifter run alexisespinosa/openfoam:$OF_VERSION decomposePar
##|echo "4: Executing the case in parallel"
##|srun --export=all -n $SLURM_NTASKS shifter run --mpi alexisespinosa/openfoam:$OF_VERSION interFoam -parallel

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#Example for compiling your own solver to be used with the openfoam:v1812 container:

# For using it in your local host with docker:
# 1.0 Pull the container:
#     1.1 docker pull alexisespinosa/openfoam:v1812
# 2.0 Run the container interactively:
#     2.3 cd to your working directory in scratch:
#         2.3.1  cd <workingDir> 
#     2.5 (At pawsey computer): run interactively mounting your userOpenFOAM directory in the place of $WM_PROJECT_USER_DIR:
#         docker run -it --rm -v /Users/MyMac/OpenFOAM/espinosa-v1812:/home/ofuser/OpenFOAM/ofuser-v1812 alexisespinosa/openfoam:v1812
#         (This should prompt you into the container itself) 
#     2.6 Within the container, cd to the application dir and compile (you can use the environmental variables):
#         2.6.1 cd $WM_PROJECT_USER_DIR/applications/my_icoFoam
#         2.6.2 wclean
#         2.6.3 wmake
#               (Now the executable of my_icoFoam should be visible in the container at):
#               /home/ofuser/OpenFOAM/ofuser-v1812/platforms/linux64GccDPInt32Opt/bin/my_icoFoam
#     1.1 (In the login node): sg $PAWSEY_PROJECT -c 'shifter pull alexisespinosa/openfoam:v1812'
# 2.0 Run the container interactively:
#     2.1 (At pawsey computer):salloc -p debugq
#     2.2 module load shifter
#     2.3 (At pawsey computer): cd to your working directory in scratch:
#         2.3.1  cd $MYSCRATCH/<workingDir> 
#     2.4 scp your developed application into your userOpenFOAM directory in $MYGROUP in Pawsey:
#         2.4.1 (At your local host use scp):
#               scp -r myLocalDir/OpenFOAM/espinosa-v1812/applications/my_icoFoam \
#               espinosa@hpc-data.pawsey.org.au:/group/pawseyXXXX/espinosa/OpenFOAM/espinosa-v1812/applications 
#     2.5 (At pawsey computer): run interactively mounting your userOpenFOAM directory in the place of $WM_PROJECT_USER_DIR:
#         shifter run --mount=type=bind,source=$MYGROUP/OpenFOAM/espinosa-v1812,destination=/home/ofuser/OpenFOAM/ofuser-v1812 alexisespinosa/openfoam:v1812
#         (This should prompt you into the container itself) 
#     2.6 Within the container, cd to the application dir and compile (you can use the environmental variables):
#         2.6.1 cd $WM_PROJECT_USER_DIR/applications/my_icoFoam
#         2.6.2 wclean
#         2.6.3 wmake
#               (Now the executable of my_icoFoam should be visible in the container at):
#               /home/ofuser/OpenFOAM/ofuser-v1812/platforms/linux64GccDPInt32Opt/bin/my_icoFoam
#               (which is the same as):
#               $WM_PROJECT_USER_DIR/platforms/linux64GccDPInt32Opt/bin/my_icoFoam
#               (which is the same as, inside or outside the container):
#               $MYSCRATCH/OpenFOAM/espinosa-v1812/platforms/linux64GccDPInt32Opt/bin/my_icoFoam
#     2.7 Exit the interactive container

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#Example script for running your own solver (created above) with openfoam:v1812 container:
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
##|export OF_VERSION=v1812
##|
##|echo "Creating Mesh with blockMesh ..."
##|srun --export=all -n 1 shifter run alexisespinosa/openfoam:$OF_VERSION blockMesh
##|echo "Running parallel solver ..."
##|srun --export=all -n 1 shifter run --mount=type=bind,source=$MYGROUP/OpenFOAM/espinosa-v1812,destination=/home/ofuser/OpenFOAM/ofuser-v1812 alexisespinosa/openfoam:$OF_VERSION my_icoFoam > logRun 2>&1
