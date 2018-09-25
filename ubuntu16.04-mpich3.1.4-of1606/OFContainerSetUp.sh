#!/bin/bash

export OFUSERHOME="/home/ofuser"
export OFPLACE="${OFUSERHOME}/OpenFOAM"
export OFVERSION="v1606+"

export WM_MPLIB=SYSTEMMPI
export MPI_ROOT="/usr"
export MPI_ARCH_FLAGS="-DMPICH_SKIP_MPICXX"
export MPI_ARCH_INC="-isystem $MPI_ROOT/include"
export MPI_ARCH_LIBS="-L$MPI_ROOT/lib -lmpich"

#. ${OFPLACE}/OpenFOAM-${OFVERSION}/etc/config.sh/example/prefs.sh
cp ${OFPLACE}/OpenFOAM-${OFVERSION}/etc/bashrc bashrcHere
sed -i 's/foamInstall=$HOME/foamInstall=${OFUSERHOME}/' bashrcHere
sed -i 's/WM_PROJECT_USER_DIR=$HOME/WM_PROJECT_USER_DIR=${OFUSERHOME}/' bashrcHere
. ./bashrcHere

exec "$@"
