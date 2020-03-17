#!/bin/bash
source /opt/openfoam7/etc/bashrc
mpirun -np 4 pimpleFoam -parallel 2>/dev/null | tee log.pimpleFoam.foundation-7.docker.internal.XX
