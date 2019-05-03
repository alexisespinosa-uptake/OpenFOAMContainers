#!/bin/bash

#===================================================================#
# allrun script for testcase as part of test routine 
# run settlingTest CFD part
# Christoph Goniva - Feb. 2011
#===================================================================#

#- source CFDEM env vars
#AEG:. ~/.bashrc

#- include functions
#AEG:source $CFDEM_SRC_DIR/lagrangian/cfdemParticle/etc/functions.sh
source $SLURM_SUBMIT_DIR/functions.sh

#--------------------------------------------------------------------------------#
#- define variables
casePath="$(dirname "$(readlink -f ${BASH_SOURCE[0]})")"
logpath=$casePath
headerText="run_parallel_cfdemSolverPiso_periodicChannel_CFDDEM"
logfileName="log_$headerText"
solverName="cfdemSolverPiso"
nrProcs="4"
machineFileName="none"   # yourMachinefileName | none
debugMode="off"          # on | off| strict
testHarnessPath="$CFDEM_TEST_HARNESS_PATH"
#AEG:runOctave="true"
runOctave="false"
postproc="false"
cleanCase="true"
#--------------------------------------------------------------------------------#

#- call function to run a parallel CFD-DEM case
parCFDDEMrun $logpath $logfileName $casePath $headerText $solverName $nrProcs $machineFileName $debugMode


if [ $runOctave == "true" ]
    then
        #------------------------------#
        #  octave

        #- change path
        cd octave

        #- rmove old graph
        rm *.png

        #- run octave
        #AEG:octave --no-gui checkVolFlow.m
        shifter run $containerImage octave --no-gui checkVolFlow.m

        #- show plot 
        eog volflow.png

        #- copy log file to test harness
        cp ../../$logfileName $testHarnessPath
        cp *.png $testHarnessPath
fi

if [ $postproc == "true" ]
  then

    #- keep terminal open (if started in new terminal)
    echo "simulation finished? ...press enter to proceed"
    read

    #- get VTK data from liggghts dump file
    cd $casePath/DEM/post
    #AEG:python -i $CFDEM_LPP_DIR/lpp.py dump*.liggghts_restart
    shifter run $containerImage python -i $CFDEM_LPP_DIR/lpp.py dump*.liggghts_restart

    #- get VTK data from CFD sim
    cd $casePath/CFD
    #AEG:foamToVTK                                                   #- serial run of foamToVTK
    shifter run $containerImage foamToVTK                                                   #- serial run of foamToVTK
    #source $CFDEM_SRC_DIR/lagrangian/cfdemParticle/etc/functions.sh                       #- include functions
    #pseudoParallelRun "foamToVTK" $nrPostProcProcessors          #- pseudo parallel run of foamToVTK

    #- start paraview
    #AEG:paraview
    shifter run $containerImage paraview

    #- keep terminal open (if started in new terminal)
    echo "...press enter to clean up case"
    echo "press Ctr+C to keep data"
    read

fi

#- clean up case
if [ $cleanCase == "true" ]
  then
    #- clean up case
    keepDEMrestart="false"
    cleanCFDEMcase $casePath/CFD $keepDEMrestart
fi