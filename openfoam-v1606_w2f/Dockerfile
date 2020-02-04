#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
# A. Initial main definintion
FROM alexisespinosa/openfoam:v1606
LABEL maintainer="Alexis.Espinosa@pawsey.org.au"
#OpenFOAM version to use
ARG OFVERSION="v1606+"
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
ARG W2FBASHRC=${W2FINSTDIR}/bin/bashrc
RUN cp ${W2FBASHRC}.org ${W2FBASHRC} \
 &&  sed -i -e '/^export WAVES_DIR=.*/aexport WAVES_DIR='"${W2FINSTDIR}" ${W2FBASHRC} \
 &&  sed -i -e '0,/^export WAVES_DIR/s//# export WAVES_DIR/' ${W2FBASHRC}

#............
#Modifying the prepareCase.sh script for the tutorials to work from outisde the tutorial directory (if replicated)
RUN . ${W2FBASHRC} \
 && cp $WAVES_DIR/bin/prepareCase.sh $WAVES_DIR/bin/prepareCase.sh.org \
 && sed -i -e 's,../../commonFiles,$WAVES_TUT/commonFiles,g' $WAVES_DIR/bin/prepareCase.sh \
 && sed -i -e 's,$PWD/../../..,$WAVES_DIR,g' $WAVES_DIR/bin/prepareCase.sh

#............
#-#NotNeededFor1606#-#:#Fixing the error of the 1808_PLUS folder (by copying the 1712 version into a 1806 version without modification)
#-#NotNeededFor1606#-#:RUN cp -r applications/solvers/solvers1712_PLUS  applications/solvers/solvers1806_PLUS
 
#............
#Compiling  all waves2Foam
RUN . ${W2FBASHRC} \
 && cd ${W2FINSTDIR} \
 && ./Allwmake 2>&1 | tee log.make 

#............
#Printing the environment variables defined
RUN . ${W2FBASHRC} \
 && cd ${W2FINSTDIR} \
 && printenv > "raw_waves2Foam.env"

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
## II. HARDCODING THE ENVIRONMENTAL VARIABLES TO RUN OPENFOAM.
#
# Please follow the relevant document inside ../Documentation/ContainerCreation
#
# The procedure that has been executed for the plain OpenFOAM container needs to be repeated.
# But, in this case, the image to be used is the one with waves2foam:
# alexisespinosa/openfoam:v1806_w2f
# and the configuration file to be sourced to add the waves2foam variables is:
# /MySoftware/waves2Foam/bin/bashrc
#
# To identify the variables to be added, a diff with the original variables list can be made
#
# The additional variables related to waves2FOAM that need to be added here are:
# EXTBRANCH,FOAMEXTENDEDPROJECT,OFPLUSBRANCH,WAVES_*,WM_PROJECT_VERSION_NUMBER
# (Be careful and do not miss the FOAMEXTENDEDPROJECT variable becase this is an additional FOAM* var)
# (Be careful and do not miss the WM_PROJECT_VERSION_NUMBER variable becase this is an additional WM_* var)
#----------------------------:
# i. Copy&Paste the list of environmental variables below this comment.
#and before the ii. "Fixing" comment.
#IMPORTANT: In the first pass of creation of this container, all the ENV definitions should be removed or commented.
#           Then, after defining the list of ENV variables that will be used here, you should copy and paste them below:
#----------------------------:
ENV EXTBRANCH=0
ENV FOAMEXTENDPROJECT=0
ENV OFPLUSBRANCH=1
ENV WAVES_APPBIN=/home/ofuser/OpenFOAM/ofuser-v1606+/platforms/linux64GccDPInt32Opt/bin
ENV WAVES_DIR=/MySoftware/waves2Foam
ENV WAVES_GSL_INCLUDE=/usr/include
ENV WAVES_GSL_LIB=/usr/lib64
ENV WAVES_LIBBIN=/home/ofuser/OpenFOAM/ofuser-v1606+/platforms/linux64GccDPInt32Opt/lib
ENV WAVES_POST=/MySoftware/waves2Foam/applications/utilities/postProcessing
ENV WAVES_PRE=/MySoftware/waves2Foam/applications/utilities/preProcessing
ENV WAVES_SOL=/MySoftware/waves2Foam/applications/solvers/solvers1606_PLUS
ENV WAVES_SRC=/MySoftware/waves2Foam/src
ENV WAVES_TUT=/MySoftware/waves2Foam/tutorials
ENV WAVES_UTIL=/MySoftware/waves2Foam/applications/utilities
ENV WAVES_XVERSION=0
ENV WM_PROJECT_VERSION_NUMBER=1606

#----------------------------:
#ii. Fixing shifter bug with environment variables.
#If loss of variables environment variables occurred to you,
#Comment the problematic variables in the list above and mark them with some tag like #WillBeDefinedAtTheEndDueToShifterFailure
#and define them at the end of the list (immediately below this comment)
#----------------------------:

#...........
#Writing the environment variables for the installation so far:
RUN cd $WM_PROJECT_DIR \
 && printenv > afterENV_waves2Foam.env


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
