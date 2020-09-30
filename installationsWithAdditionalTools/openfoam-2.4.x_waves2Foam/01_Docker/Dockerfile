#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
##IMPORTANT: This recipe is still failing!
#The creation of this image that contains waves2Foam 
#from the already existing and working image of openfoam:2.4.x
FROM pawsey/openfoam:2.4.x
LABEL maintainer="Alexis.Espinosa@pawsey.org.au"
#OpenFOAM version to install
ARG OFVERSION="2.4.x"
#Using bash from now on
SHELL ["/bin/bash","-c"]

USER root

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#Trick for making apt-get work again. This is very weird.
#Following the solution proposed here:
#https://sillycodes.com/quick-tip-couldnt-create-temporary-file/
#But modified a little bit in order to  let apt-get install -y to work fine
RUN apt-get clean \
 && mv /var/lib/apt/lists/partial /tmp \
 && mkdir -p /var/lib/apt/lists/partial \
 && apt-get clean \
 && apt-get update

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
# Repeating settings from the basic installation
ARG OFINSTDIR=/opt/OpenFOAM
ARG OFUSERDIR=/home/ofuser/OpenFOAM
ARG OFTHIRDPARTYDIR=${OFINSTDIR}/ThirdParty-${OFVERSION}
ARG OFPREFS=${OFINSTDIR}/OpenFOAM-${OFVERSION}/etc/prefs.sh
ARG OFBASHRC=${OFINSTDIR}/OpenFOAM-${OFVERSION}/etc/bashrc
ARG ParaView_VERSION=4.1.0
ARG ParaView_ShortVERSION=4.1

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
# I. Installing additional tools needed for waves2Foam
RUN apt-get update -qq\
 &&  apt-get -y --no-install-recommends install \
     libgsl0-dev subversion gfortran git \
 && apt-get clean all \
 && rm -r /var/lib/apt/lists/*

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
# II. Installation of waves2Foam
#...........
# A. First cloning the repo
#AA@ARG WAVES2INSTALLDIR=/opt
ARG WAVES2INSTALLDIR=$OFUSERDIR/ofuser-${OFVERSION}/applications/utilities
RUN . ${OFBASHRC} \
 && if [ ! -d $WAVES2INSTALLDIR ]; then mkdir -p $WAVES2INSTALLDIR; fi \
 && cd $WAVES2INSTALLDIR \
 && svn co http://svn.code.sf.net/p/openfoam-extend/svn/trunk/\Breeder_1.6/other/waves2Foam 

#...........
# B. Second updating the bashrc environmental variables for the waves2Foam installation
ARG WAVESBASHRC=$WAVES2INSTALLDIR/waves2Foam/bin/bashrc
WORKDIR $WAVES2INSTALLDIR/waves2Foam
#AA@RUN cp $WAVESBASHRC.org $WAVESBASHRC \
#AA@# Installation files reside in the $WAVES2FOAMDIR
#AA@ && sed -i '/^export WAVES_DIR=.*/aexport WAVES_DIR='"$WAVES2FOAMDIR" ${WAVESBASHRC} \
#AA@ && sed -i '0,/^export WAVES_DIR/s//# export WAVES_DIR/' ${WAVESBASHRC} \
#AA@# Compiled binaries will be added to the OpenFOAM $FOAM_APPBIN
#AA@ && sed -i '/^export WAVES_APPBIN=.*/aexport WAVES_APPBIN=$FOAM_APPBIN' ${WAVESBASHRC} \
#AA@ && sed -i '0,/^export WAVES_APPBIN/s//# export WAVES_APPBIN/' ${WAVESBASHRC} \
#AA@# Compiled libraries will be added to the OpenFOAM $FOAM_LIBBIN
#AA@ && sed -i '/^export WAVES_LIBBIN=.*/aexport WAVES_LIBBIN=$FOAM_LIBBIN' ${WAVESBASHRC} \
#AA@ && sed -i '0,/^export WAVES_LIBBIN/s//# export WAVES_LIBBIN/' ${WAVESBASHRC} \
#AA@#--Dummy line:
#AA@ && echo ''

#...........
# C. The installation command
RUN . ${OFBASHRC} \
 && ./Allwmake 2>&1 | tee log.Allwmake

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
# III. Final settings
#...........
#Allowing normal users to read,write the waves2Foam directory
RUN chmod -R 777 $WAVES2FOAMDIR

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
