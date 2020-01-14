#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
# A. Initial main definintion
FROM alexisespinosa/openfoam:v1806
LABEL maintainer="Alexis.Espinosa@pawsey.org.au"
#OpenFOAM version to use
ARG OFVERSION="v1806"
USER root

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
# B. This section is for installing the additional needed dependencies
RUN apt-get update -qq\
 &&  apt-get -y --no-install-recommends --no-install-suggests install \
   subversion \
   git \
   libgsl-dev \
 && apt-get clean all \
 && rm -r /var/lib/apt/lists/*

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
# C. This section is for installing waves2Foam
WORKDIR /MySoftware
RUN svn co http://svn.code.sf.net/p/openfoam-extend/svn/trunk/Breeder_1.6/other/waves2Foam
ARG W2FINSTDIR=/MySoftware/waves2Foam
WORKDIR $W2FINSTDIR
RUN printenv > "raw_${OFVERSION}.env"

#............
#Modifying the bashrc of waves2Foam
RUN cp ./bin/bashrc.org ./bin/bashrc \
 &&  sed -i 's@WAVES_DIR=.*@WAVES_DIR='"${W2FINSTDIR}"'@'  ./bin/bashrc

#............
#Compiling waves2Foam
RUN . ./bin/bashrc \
 &&  ./Allwmake 2>&1 | tee log.make \
 && printenv > "raw_waves2Foam.env"

#............
#Fixing the error of the 1808_PLUS folder
RUN cp -r applications/solvers/solvers1712_PLUS  applications/solvers/solvers1806_PLUS \
 && . ./bin/bashrc \
 && cd applications/solvers/solvers1806_PLUS \
 && cd waveFoam \
 && wmake 2>&1 | tee log.make \
 && cd ../porousWaveFoam \
 && wmake 2>&1 | tee log.make
 
#........
#Fixing ownerships and permissions
RUN chown -R ofuser:ofuser $WM_PROJECT_USER_DIR \
 && chmod -R 777 $WM_PROJECT_USER_DIR

#...........
#Allowing normal users to read,write and execute on the waves2FOAM installation directory
RUN chmod -R 777 $W2FINSTDIR

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
## I. HARDCODING THE ENVIRONMENTAL VARIABLES TO RUN WAVES2FOAM
#
# Full instructions about this hardcoding are in the Dockerfile for building the pure openfoam:v1812 container.
#
# The procedure that has been executed for OpenFOAM needs to be repeated.
# But, in this case, the image to be used is alexisespinosa/openfoam:v1812_w2f
# and the configuration file to be sourced is /MySoftware/waves2Foam/bin/bashrc
#
# To identify the variables to be added, a diff with the original variables list can be made
#
# The additional variables related to waves2FOAM that need to be added here are:
# EXTBRANCH,FOAMEXTENDEDPROJECT,OFPLUSBRANCH,WAVES_*,WM_PROJECT_VERSION_NUMBER
# (Be careful and do not miss the FOAMEXTENDEDPROJECT variable becase this is an additional FOAM* var)
# (Be careful and do not miss the WM_PROJECT_VERSION_NUMBER variable becase this is an additional WM_* var)
#----------------------------:
#I. 4.3 Copy&Paste the list of environmental variables below this comment.
#and before the II. 4.2 comment.
#(Substitute any existing ENV settings already in this file):
#----------------------------:
ENV EXTBRANCH=0
ENV FOAMEXTENDPROJECT=0
ENV OFPLUSBRANCH=1
ENV WAVES_APPBIN=/home/ofuser/OpenFOAM/ofuser-v1806/platforms/linux64GccDPInt64Opt/bin
ENV WAVES_DIR=/MySoftware/waves2Foam
ENV WAVES_GSL_INCLUDE=/usr/include
ENV WAVES_GSL_LIB=/usr/lib64
ENV WAVES_LIBBIN=/home/ofuser/OpenFOAM/ofuser-v1806/platforms/linux64GccDPInt64Opt/lib
ENV WAVES_POST=/MySoftware/waves2Foam/applications/utilities/postProcessing
ENV WAVES_PRE=/MySoftware/waves2Foam/applications/utilities/preProcessing
ENV WAVES_SOL=/MySoftware/waves2Foam/applications/solvers/solvers1806_PLUS
ENV WAVES_SRC=/MySoftware/waves2Foam/src
ENV WAVES_TUT=/MySoftware/waves2Foam/tutorials
ENV WAVES_UTIL=/MySoftware/waves2Foam/applications/utilities
ENV WAVES_XVERSION=0
ENV WM_PROJECT_VERSION_NUMBER=1806

#----------------------------:
#II. 4.2 Fixing shifter failure.
#If loss of variables happened,
#Comment the problematic variables above and mark them with the tag #WillBeDefinedAtTheEndDueToShifterFailure
#and define them at the end of the list (immediately below this comment)
#----------------------------:

#...........
#Writing the environment variables for the installation so far:
RUN cd $WM_PROJECT_DIR \
 && printenv > afterENV_waves2Foam.env


#---------------------------------------------------------------
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
## II. TESTING AT PAWSEY
#
# Full instructions about this hardcoding are in the Dockerfile for building the pure openfoam:v1812 container.
#
# The procedure that has been executed for OpenFOAM needs to be repeated taking into account the
# new environmental variables defined for waves2Foam
