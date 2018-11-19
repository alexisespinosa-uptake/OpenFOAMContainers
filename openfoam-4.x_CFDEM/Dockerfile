#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#The creation of this image that contains VTK, LIGGGHTS && CFDEM starts
#from the already existing and working image of openfoam:4.x

FROM alexisespinosa/openfoam:4.x
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
#Installing VTK

#...........
#Compiling VTK from OF directory
ARG VTKBASEDIR=/MySoftware/VTK
ARG VTKBUILDDIR=$VTKBASEDIR/VTK-build
ARG VTKSOURCEDIR=${WM_THIRD_PARTY_DIR}/ParaView-${ParaView_VERSION}/VTK
##ARG VTKSOURCEDIR=${VTKBASEDIR}/VTK
ARG VTKINSTDIR=$VTKBASEDIR/VTK-install
ARG VTKMAKEOPTIONS="-j4"
#This version number is not needed here but will be needed for CFDEM & LIGGGHTS settings
ARG VTKVERSION=7.1
WORKDIR $VTKBUILDDIR
RUN cmake ${VTKSOURCEDIR} -DVTK_Group_MPI=on -DBUILD_SHARED_LIBS=on -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${VTKINSTDIR} \
 && make ${VTKMAKEOPTIONS} \
 && make install
#Adding the VTK libraries to the library path
ENV LD_LIBRARY_PATH=${VTKINSTDIR}/lib:$LD_LIBRARY_PATH

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
#Installation of CFDEM & LIGGGHTS
#...........
#Installing prerequisites
RUN apt-get update -qq\
 &&  apt-get -y --no-install-recommends install \
#   build-essential flex bison cmake zlib1g-dev libboost-system-dev \
#   libboost-thread-dev \
#AEG:No openmpi:   libopenmpi-dev openmpi-bin \
#   gnuplot \
#   libreadline-dev libncurses-dev libxt-dev \
#   libscotch-dev libptscotch-dev \ 
#AEG:No VTK:   libvtk6.2 libvtk6-dev \
   python-numpy \
 && apt-get clean all \
 && rm -r /var/lib/apt/lists/*


#...........
#Downloading the tools
ARG CFDEMINSTDIR=/MySoftware/CFDEM
ARG CFDEMUSERDIR=/home/ofuser/CFDEM
WORKDIR $CFDEMINSTDIR
RUN git clone git://github.com/CFDEMproject/CFDEMcoupling-PUBLIC.git \ 
 && mv CFDEMcoupling-PUBLIC CFDEMcoupling-PUBLIC-$WM_PROJECT_VERSION 

WORKDIR /MySoftware/LIGGGHTS
ARG LIGGGHTSINSTDIR=/MySoftware/LIGGGHTS
WORKDIR $LIGGGHTSINSTDIR
RUN git clone git://github.com/CFDEMproject/LIGGGHTS-PUBLIC.git \ 
 && git clone git://github.com/CFDEMproject/LPP.git lpp


#...........
#Standard Settings of environment variables
ENV CFDEM_VERSION=PUBLIC
ENV CFDEM_PROJECT_DIR=$CFDEMINSTDIR/CFDEMcoupling-$CFDEM_VERSION-$WM_PROJECT_VERSION
ENV CFDEM_PROJECT_USER_DIR=$CFDEMUSERDIR/ofuser-$CFDEM_VERSION-$WM_PROJECT_VERSION
ENV CFDEM_bashrc=$CFDEM_PROJECT_DIR/src/lagrangian/cfdemParticle/etc/bashrc
ENV CFDEM_LIGGGHTS_SRC_DIR=$LIGGGHTSINSTDIR/LIGGGHTS-PUBLIC/src
ENV CFDEM_LIGGGHTS_MAKEFILE_NAME=auto
ENV CFDEM_LPP_DIR=$LIGGGHTSINSTDIR/lpp/src
#...........
#Extended Settings of environment variables
ENV CFDEM_SRC_DIR=$CFDEM_PROJECT_DIR/src
ENV CFDEM_SOLVER_DIR=$CFDEM_PROJECT_DIR/applications/solvers
ENV CFDEM_DOC_DIR=$CFDEM_PROJECT_DIR/doc
ENV CFDEM_UT_DIR=$CFDEM_PROJECT_DIR/applications/utilities
ENV CFDEM_TUT_DIR=$CFDEM_PROJECT_DIR/tutorials
ENV CFDEM_LIGGGHTS_MAKEFILE_POSTIFX=
ENV CFDEM_VERBOSE=false
#...........
#Defining additional libraries for CFDEM
#(Basically telling CFDEM where is VTK)
ENV CFDEM_ADD_LIB_PATHS="-Wl,-rpath,${VTKINSTDIR}/lib -L${VTKINSTDIR}/lib"
ENV CFDEM_ADD_LIBS="-lvtkCommonCore-${VTKVERSION} -lvtkIOCore-${VTKVERSION} -lvtkIOXML-${VTKVERSION} -lvtkIOLegacy-${VTKVERSION} -lvtkIOImage-${VTKVERSION} -lvtkCommonDataModel-${VTKVERSION} -lvtkIOParallelXML-${VTKVERSION} -lvtkParallelCore-${VTKVERSION} -lvtkParallelMPI-${VTKVERSION} -lvtkCommonExecutionModel-${VTKVERSION} -lvtkFiltersCore-${VTKVERSION} -lvtksys-${VTKVERSION} -lvtkCommonMisc-${VTKVERSION} -lvtkCommonTransforms-${VTKVERSION} -lvtkCommonMath-${VTKVERSION} -lvtkIOXMLParser-${VTKVERSION} -lvtkCommonSystem-${VTKVERSION} -lvtkDICOMParser-${VTKVERSION} -lvtkmetaio-${VTKVERSION}"


#...........
#Create the cfdem user directory
USER ofuser
RUN mkdir -p ${CFDEM_PROJECT_USER_DIR} \
 && chmod -R 777 ${CFDEMUSERDIR}
USER root

#...........
#Modifying the LIGGGHTS makefile
WORKDIR $LIGGGHTSINSTDIR/LIGGGHTS-PUBLIC/src
RUN make auto; exit 0
RUN sed -i $'s@^#VTK_INC_USR=-I/path/to/vtk/include@#VTK_INC_USR=-I/path/to/vtk/include\\\nVTK_INC_USR=-I'"${VTKINSTDIR}"'/include/vtk-'"${VTKVERSION}"'@' ./MAKE/Makefile.user \
 && sed -i $'s@^#VTK_LIB_USR=-L/path/to/vtk/lib@#VTK_LIB_USR=-L/path/to/vtk/lib\\\nVTK_LIB_USR=-L'"${VTKINSTDIR}"'/lib@' ./MAKE/Makefile.user \
 && make clean-auto

#...........
#Installing LIGGGTHS
RUN make auto


#...........
#Test that CFDEM settings are correct (the alias cfdemSysTest defined in the bashrc file does not work)
WORKDIR $CFDEMINSTDIR
RUN . ${CFDEM_bashrc} \
#### && cfdemSysTest 2>&1 | tee log.cfdemSysTest
 && $CFDEM_SRC_DIR/lagrangian/cfdemParticle/etc/cfdemSystemTest.sh 2>&1 | tee log.cfdemSysTest

#...........
#Installing CFDEM
RUN . ${CFDEM_bashrc} \
#### && cfdemCompLIG | tee log.cfdemCompLIG
 && $CFDEM_SRC_DIR/lagrangian/cfdemParticle/etc/compileLIGGGHTS.sh 2>&1 | tee log.cfdemCompLIG

RUN . ${CFDEM_bashrc} \
#### && cfdemCompCFDEMsrc | tee log.cfdemCompCFDEMsrc
 && $CFDEM_SRC_DIR/lagrangian/cfdemParticle/etc/compileCFDEMcoupling_src.sh 2>&1 | tee log.cfdemCompCFDEMsrc

RUN . ${CFDEM_bashrc} \
#### && cfdemCompCFDEMsol | tee log.cfdemCompCFDEMsol
 && $CFDEM_SRC_DIR/lagrangian/cfdemParticle/etc/compileCFDEMcoupling_sol.sh 2>&1 | tee log.cfdemCompCFDEMsol

RUN . ${CFDEM_bashrc} \
#### && cfdemCompCFDEMuti | tee log.cfdemCompCFDEMuti
 && $CFDEM_SRC_DIR/lagrangian/cfdemParticle/etc/compileCFDEMcoupling_uti.sh 2>&1 | tee log.cfdemCompCFDEMuti

#...........
#Deleting the log files
#(Activate this until the installations if fully tested and there is no more reason to check logs)
####RUN rm log.cfdem*

#...........
#Allowing normal users to read,write and execute on the VTK and CFDEM installation
RUN chmod -R 777 $VTKBASEDIR \
 && chmod -R 777 $CFDEMINSTDIR

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
# Adding all the CFDEM environmental variables defined by the $CFDEM_bashrc file
#   (except the definition of bash functions)
# This is done following the same procedure that was used to define all the environmental variables of OpenFOAM
#   in the original Dockerfile for creating the openfoam image FROM which this image is trying to be built.
#   (See FROM line above)
# All this variables are hardcoded as they are copied and pasted here from the list extracted from an interactive
#   container after a "source $CFDEM_bashrc". The procedure is exactly the same as described for the Dockerfile
#   of the basic openfoam container.

ENV CFDEM_ADD_LIBS="-lvtkCommonCore-7.1 -lvtkIOCore-7.1 -lvtkIOXML-7.1 -lvtkIOLegacy-7.1 -lvtkIOImage-7.1 -lvtkCommonDataModel-7.1 -lvtkIOParallelXML-7.1 -lvtkParallelCore-7.1 -lvtkParallelMPI-7.1 -lvtkCommonExecutionModel-7.1 -lvtkFiltersCore-7.1 -lvtksys-7.1 -lvtkCommonMisc-7.1 -lvtkCommonTransforms-7.1 -lvtkCommonMath-7.1 -lvtkIOXMLParser-7.1 -lvtkCommonSystem-7.1 -lvtkDICOMParser-7.1 -lvtkmetaio-7.1"
ENV CFDEM_ADD_LIBS_DIR=/MySoftware/CFDEM/CFDEMcoupling-PUBLIC-4.x/src/lagrangian/cfdemParticle/etc/addLibs_universal
ENV CFDEM_ADD_LIBS_NAME=additionalLibs_4.x
ENV CFDEM_ADD_LIB_PATHS="-Wl,-rpath,/MySoftware/VTK/VTK-install/lib -L/MySoftware/VTK/VTK-install/lib"
ENV CFDEM_APP_DIR=/MySoftware/CFDEM/CFDEMcoupling-PUBLIC-4.x/platforms/linux64GccDPInt32Opt/bin
ENV CFDEM_DOC_DIR=/MySoftware/CFDEM/CFDEMcoupling-PUBLIC-4.x/doc
ENV CFDEM_LAMMPS_LIB_DIR=/MySoftware/LIGGGHTS/LIGGGHTS-PUBLIC/src/../lib
ENV CFDEM_LIB_COMP_NAME=lagrangianCFDEMcomp-PUBLIC-4.x
ENV CFDEM_LIB_DIR=/MySoftware/CFDEM/CFDEMcoupling-PUBLIC-4.x/platforms/linux64GccDPInt32Opt/lib
ENV CFDEM_LIB_NAME=lagrangianCFDEM-PUBLIC-4.x
ENV CFDEM_LIGGGHTS_EXEC=/MySoftware/LIGGGHTS/LIGGGHTS-PUBLIC/src/lmp_auto
ENV CFDEM_LIGGGHTS_LIB_NAME=lmp_auto
ENV CFDEM_LIGGGHTS_LIB_PATH=/MySoftware/LIGGGHTS/LIGGGHTS-PUBLIC/src
ENV CFDEM_LIGGGHTS_MAKEFILE_NAME=auto
ENV CFDEM_LIGGGHTS_MAKEFILE_POSTIFX=
ENV CFDEM_LIGGGHTS_SRC_DIR=/MySoftware/LIGGGHTS/LIGGGHTS-PUBLIC/src
ENV CFDEM_LPP_CHUNKSIZE=1
ENV CFDEM_LPP_DIR=/MySoftware/LIGGGHTS/lpp/src
ENV CFDEM_LPP_NPROCS=1
ENV CFDEM_M2MLIB_MAKEFILENAME=auto
ENV CFDEM_M2MLIB_PATH=/MySoftware/CFDEM/CFDEMcoupling-PUBLIC-4.x/src/lagrangian/cfdemParticle/subModels/dataExchangeModel/M2M/library
ENV CFDEM_M2MMSLIB_MAKEFILENAME=auto
ENV CFDEM_M2MMSLIB_PATH=/MySoftware/CFDEM/CFDEMcoupling-PUBLIC-4.x/src/lagrangian/cfdemParticle/subModels/dataExchangeModel/M2M/library
ENV CFDEM_Many2ManyLIB_MAKEFILENAME=auto
ENV CFDEM_Many2ManyLIB_PATH=/MySoftware/CFDEM/CFDEMcoupling-PUBLIC-4.x/src/lagrangian/cfdemParticle/subModels/dataExchangeModel/twoWayMany2Many/library
ENV CFDEM_OFVERSION_DIR=/MySoftware/CFDEM/CFDEMcoupling-PUBLIC-4.x/src/lagrangian/cfdemParticle/etc/OFversion
ENV CFDEM_POEMSLIB_PATH=/MySoftware/LIGGGHTS/LIGGGHTS-PUBLIC/src/../lib/poems
ENV CFDEM_PROJECT_DIR=/MySoftware/CFDEM/CFDEMcoupling-PUBLIC-4.x
ENV CFDEM_PROJECT_USER_DIR=/home/ofuser/CFDEM/ofuser-PUBLIC-4.x
ENV CFDEM_SOLVER_DIR=/MySoftware/CFDEM/CFDEMcoupling-PUBLIC-4.x/applications/solvers
ENV CFDEM_SRC_DIR=/MySoftware/CFDEM/CFDEMcoupling-PUBLIC-4.x/src
ENV CFDEM_TEST_HARNESS_PATH=/home/ofuser/CFDEM/ofuser-PUBLIC-4.x/log/logFilesCFDEM-PUBLIC-4.x
ENV CFDEM_TUT_DIR=/MySoftware/CFDEM/CFDEMcoupling-PUBLIC-4.x/tutorials
ENV CFDEM_USER_APP_DIR=/home/ofuser/CFDEM/ofuser-PUBLIC-4.x/platforms/linux64GccDPInt32Opt/bin
ENV CFDEM_USER_LIB_DIR=/home/ofuser/CFDEM/ofuser-PUBLIC-4.x/platforms/linux64GccDPInt32Opt/lib
ENV CFDEM_UT_DIR=/MySoftware/CFDEM/CFDEMcoupling-PUBLIC-4.x/applications/utilities
ENV CFDEM_VERBOSE=false
ENV CFDEM_VERSION=PUBLIC
ENV CFDEM_WM_PROJECT_VERSION=40
ENV CFDEM_bashrc=/MySoftware/CFDEM/CFDEMcoupling-PUBLIC-4.x/src/lagrangian/cfdemParticle/etc/bashrc
ENV LD_LIBRARY_PATH=/home/ofuser/CFDEM/ofuser-PUBLIC-4.x/platforms/linux64GccDPInt32Opt/lib:/MySoftware/CFDEM/CFDEMcoupling-PUBLIC-4.x/platforms/linux64GccDPInt32Opt/lib:/MySoftware/VTK/VTK-install/lib:/MySoftware/OpenFOAM/ThirdParty-4.x/platforms/linux64Gcc/gperftools-svn/lib:/MySoftware/OpenFOAM/ThirdParty-4.x/platforms/linux64Gcc/ParaView-5.0.1/lib/paraview-5.0:/MySoftware/OpenFOAM/OpenFOAM-4.x/platforms/linux64GccDPInt32Opt/lib/mpi-system:/MySoftware/OpenFOAM/ThirdParty-4.x/platforms/linux64GccDPInt32/lib/mpi-system:/home/ofuser/OpenFOAM/ofuser-4.x/platforms/linux64GccDPInt32Opt/lib:/MySoftware/OpenFOAM/site/4.x/platforms/linux64GccDPInt32Opt/lib:/MySoftware/OpenFOAM/OpenFOAM-4.x/platforms/linux64GccDPInt32Opt/lib:/MySoftware/OpenFOAM/ThirdParty-4.x/platforms/linux64GccDPInt32/lib:/MySoftware/OpenFOAM/OpenFOAM-4.x/platforms/linux64GccDPInt32Opt/lib/dummy
ENV PATH=/home/ofuser/CFDEM/ofuser-PUBLIC-4.x/platforms/linux64GccDPInt32Opt/bin:/MySoftware/CFDEM/CFDEMcoupling-PUBLIC-4.x/platforms/linux64GccDPInt32Opt/bin:/MySoftware/OpenFOAM/ThirdParty-4.x/platforms/linux64Gcc/gperftools-svn/bin:/MySoftware/OpenFOAM/ThirdParty-4.x/platforms/linux64Gcc/ParaView-5.0.1/bin:/home/ofuser/OpenFOAM/ofuser-4.x/platforms/linux64GccDPInt32Opt/bin:/MySoftware/OpenFOAM/site/4.x/platforms/linux64GccDPInt32Opt/bin:/MySoftware/OpenFOAM/OpenFOAM-4.x/platforms/linux64GccDPInt32Opt/bin:/MySoftware/OpenFOAM/OpenFOAM-4.x/bin:/MySoftware/OpenFOAM/OpenFOAM-4.x/wmake:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
## Starting as ofuser by default
USER ofuser
WORKDIR /home/ofuser

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
## If running this container interactively, user may still want to source the $CFDEM_bashrc file
##  in order to make the aliases and functions available (which were not set
##  or not able to be set with the ENV command inside this Dockerfile).
##  Do: source $CFDEM_bashrc
