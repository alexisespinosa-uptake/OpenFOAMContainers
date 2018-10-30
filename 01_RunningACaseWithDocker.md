## Running a tutorial (or any case) within your local host with Docker

---
Within your local host computer, cd to the case directory. In my case:
```
cd /Users/MyMac/OpenFOAM/espinosa-3.0.1/tests/cavity
```
Any openfoam command can be ran through the container.
The trick here is to run it inside a bash kernel using the **"bash -c"** command:
```
docker run --rm -v $PWD:/home/ofuser/case alexisespinosa/openfoam:3.0.1 bash -c 'cd case && blockMesh > logMesh 2>&1'
```
* **--rm** is for avoiding Docker to save the container as a process in its container's process list.
The container will run and then disappear.
* **-v $PWD:/home/ofuser/case** mounts the local directory into the directory /home/ofuser/case
* **bash -c** is the command to be executed in the container and, within this kernel, the desired commands are executed.

The user can see the result of the command by exploring the file logMesh, which should be in the current directory
of the host computer.

Now, the same approach should be followed to run the solver:
```
docker run --rm -v $PWD:/home/ofuser/case alexisespinosa/openfoam:3.0.1 bash -c 'cd case && icoFoam > logRun 2>&1'
```
