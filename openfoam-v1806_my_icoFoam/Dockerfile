# I. BUILDING YOUR OWN TOOLS INSIDE THE CONTAINER
# 0. Prepare your tool in your local file.
#    (Usually, the user should have its own develpment in their local computer.
#     In this example I will copy out the solver icoFoam and rename it as my_icoFoam in my local computer.
#     my_icoFoam will play the role of my own solver. My own development in my local computer.
#     This development is the one that within this Dockerfile is later copied into the new container
#     and compiled within.)
#    (0.1) Creating my_icofoam for the example:
#          (0.1.1) In your local computer create the solvers directory:
#                  mkdir -p applications/solvers
#          (0.1.2) Copy the icoFoam solver into your local computer:
#                  docker run --rm --user $(id -u):$(id -g) -v $PWD:/localDir alexisespinosa/openfoam:v1806 bash -c 'cp -r $FOAM_APP/solvers/incompressible/icoFoam /localDir/applications/solvers/my_icoFoam'
#          (0.1.3) Rename the source code to "my_icoFoam.C"
#                  mv applications/solvers/my_icoFoam/icoFoam.C appications/solvers/my_icoFoam/my_icoFoam.C
#          (0.1.4) Just figure out which files have the old name within their instructions/code:
#                  find . -type f -name "*" | xargs grep icoFoam
#          (0.1.5) Replace all the occurrences of "icoFoam" with "my_icoFoam":
#                  find . -type f -name "*" | xargs sed -i 's,icoFoam,my_icoFoam,g'
#          (0.1.6) Just see that the replacements were done:
#                  find . -type f -name "*" | xargs grep icoFoam
#          (0.1.7) In the files withing the "Make" directory, perform changes for the tool to be
#                  created in the FOAM_USER_APPBIN:
#                  sed -i 's,FOAM_APPBIN,FOAM_USER_APPBIN,g' Make/files
#
# 1. Build an image with this Dockerfile. The important point is to copy your tool from the local computer
#    into the container itself. This is performed in Section B.
#    Notice that the local folder "applications" is copied into a folder "applications"
#    within the $WM_PROJECT_USER_DIR (which belongs to the container user "ofuser" that was created in
#    the image alexisespinosa/openfoam:v1806)
#    Later, in Section C. the solver "my_icoFoam" is compiled with openfoam procedure.
#
#    1.1 So, to execute this step, the image needs to be built:
#        docker build -t alexisepinosa/openfoam:v1806_my_icoFoam .
#
# 2. Test that your own solver which is now inside the container works.
#    (2.1) First we create a case to be solved. If the case do not exist,
#          we copy this case from the container itself:
#          mkdir -p run/tutorials
#          docker run --rm --user $(id -u):$(id -g) -v $PWD:/localDir alexisespinosa/openfoam:v1806_my_icoFoam bash -c 'cp -r $FOAM_TUTORIALS/incompressible/icoFoam/cavity/cavity /localDir/run/tutorials'
#    2.2 In your local computer "cd" to your case
#        cd run/tutorials/cavity/
#    2.3 Build the mesh using the container
#        docker run --rm --user $(id -u):$(id -g) -v $PWD:/cavity -w /cavity alexisespinosa/openfoam:v1806_my_icoFoam blockMesh
#    2.4 Use your own solver within the new container: 
#        docker run --rm --user $(id -u):$(id -g) -v $PWD:/cavity -w /cavity alexisespinosa/openfoam:v1806_my_icoFoam my_icoFoam
# 3. Now, the my_icoFoam solver is available in the container and can be used as any other solver.
#    To use it at Pawsey, you need to push it to your repository in docker hub, and the pull it to pawsey.
#    Use it as any other openfoam container.
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
# B. Copying the application into the container (This is the critical step) 
WORKDIR $WM_PROJECT_USER_DIR 
COPY applications ./applications

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
# C. Compiling the openfoam application
WORKDIR $WM_PROJECT_USER_DIR/applications/solvers/my_icoFoam
RUN wclean \
 && wmake

#........
#Fixing ownerships and permissions
RUN chown -R ofuser:ofuser $WM_PROJECT_USER_DIR \
 && chmod -R 777 $WM_PROJECT_USER_DIR

#---------------------------------------------------------------
#---------------------------------------------------------------
#---------------------------------------------------------------
# D. Trick for making apt-get work again. This is very weird.
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
# E. Starting as ofuser by default
USER ofuser
WORKDIR /home/ofuser
