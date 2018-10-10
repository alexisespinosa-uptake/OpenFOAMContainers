## 1. ThirdParty compilation

### An error copying [agm]* files
Happens for versions: -v1606+,-3.0.1:
Seems not to be a harmfull error, just the files to cp are not there.

It looks like this in the log file of the ThirdParty compilation:
```
cp -f ../bin/[agm]* /software/OpenFOAM/ThirdParty-3.0.1/platforms/linux64GccInt32/scotch_6.0.3/bin
cp -f ../bin/d[agm]* /software/OpenFOAM/ThirdParty-3.0.1/platforms/linux64GccInt32/scotch_6.0.3/bin
cp: cannot stat '../bin/d[agm]*': No such file or directory
Makefile:115: recipe for target 'install' failed
make: [install] Error 1 (ignored)
```


