## Adding Tools and Re-building a New Image

In order to add tools to an existing openfoam container (like waves2foam or CFDEM) it is very useful to try the
installation within an interactive session and write the Dockerfile as a list of commands needed for the installation.
The exact order and syntax of this series of commands is the result of the gained experience during the interactive
sessions. This is usually a cycle of tests until the right Dockerfile is achieved.

### Example - Installing VTK, CFDEM and LIGGGTHS to openfoam:4.x

Dockerfile within openfoam-4.x_CFDEM is self explanatory about the process.
An example for running a tutorial case is within the same folder under tutorials_pawsey ...


