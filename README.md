# HTS Jupyter notebook container

As part of the National Institutes of Health (NIH) Big Data to Knowledge (BD2K)
initiative, the Department of Biostatistics and Bioinformatics, together with 
faculty from the Duke Center for Genomic and Computational Biology, has been 
funded to host a 6-week summer course May 20th to June 27th 2019 on 
High Throughput Sequencing (HTS). Our goal is to teach the next generation 
of scientists the biological, statistical, computational and informatics 
knowledge for implementing a well-designed genomics experiment.

     https://biostat.duke.edu/education/high-throughput-sequencing-course

This is the source for the Docker container used to run the course Jupyter
notebooks. 



# Using the image
## Install docker

To run a container on your local machine or laptop, download the docker program from <https://www.docker.com>. 


## Run image on your local computer

Once you have the docker program installed, open the program (you should get a terminal screen with command line). Enter the command:
```
docker pull dukehtscourse/jupyter-hts-2019
```

This will pull down the course docker image from dockerhub. It may take a few minutes. Next, run the command to start a container:
```
docker run --name hts-course -v YOUR_DIRECTORY_WITH_COURSE_MATERIAL:/home/jovyan/work \
-d -p 127.0.0.1\:9999\:8888 \
-e PASSWORD="YOUR_CHOSEN_NOTEBOOK_PASSWORD" \
-e NB_UID=1000 \
-t dukehtscourse/jupyter-hts-2019
```
The most important parts of this verbiage are the `YOUR_DIRECTORY_WITH_COURSE_MATERIALS` and `YOUR_CHOSEN_NOTEBOOK_PASSWORD`. 
-   `YOUR_DIRECTORY_WITH_COURSE_MATERIALS` (Bind mounting): The directory name is the one you extracted your course materials into. So, if you put them in your home directory, it might look something like: `-v /home/janice/HTS2019-notebooks:/home/jovyan/work`
-   `YOUR_CHOSEN_NOTEBOOK_PASSWORD`: The password is whatever you want to use to password protect your notebook. Now, this command is running the notebook so that it is only 'seen' by your local computer - no one else on the internet can access it, and you cannot access it remotely, so the password is a bit of overkill. Use it anyway. An example might be: `-e PASSWORD="Pssst_this_is_Secret"` except that this is a terrible password and you should follow standard rules of not using words, include a mix of capital and lowercase and special symbols. etc.
-   `-d -p 127.0.0.1\:9999\:8888` part of the command is telling docker to run the notebook so that it is only visible to the local machine. It is absolutely possible to run it as a server to be accessed across the web - but there are some security risks associated, so if you want to do this proceed with great caution and get help.

Of course, it would be better either configure HTTPS (see the options section below) or run an Nginx proxy in front of the container instance so you get https (encryption) instead of http.

### Open the Jupyter in your browser

Open a browser and point it to http://127.0.0.1:9999
You should get to a Jupyter screen asking for a password. This is the password you created in the docker run command.
Now, you should be able to run anything you like from the course. Depending on your laptop's resources (RAM, cores), this might be slow, so be aware and start by testing only one file (vs the entire course data set).

### Stopping Docker
The container will continue running, even if you do not have Jupyter open in a web browser.  If you don't plan to use it for a while, you might want to shut it down so it isn't using resources on your computer.  Here are two ways to do that:
#### Kitematic
Included in the [Docker for Mac](https://docs.docker.com/docker-for-mac/) and the [Docker for Windows](https://docs.docker.com/docker-for-windows/) installations.
   
#### Commandline
You may want to familiarize yourself with the following Docker commands.
-   `docker stop`
-   `docker rm`
-   `docker ps -a`
-   `docker images`
-   `docker rmi`

### Windows Note
These instructions have not been tested in a Windows environment.  If you have problems with them, please give us feedback

## Run image on a server
To run on a remote server you will want to use a slightly different command from above, because you *will need to connect remotely*:

```
docker run --name hts-course \
-v YOUR_DIRECTORY_WITH_COURSE_MATERIAL:/home/jovyan/work \
-d -p 8888:8888 \
-e USE_HTTPS="yes" \
-e PASSWORD="YOUR_CHOSEN_NOTEBOOK_PASSWORD" \
-e NB_UID=1000 \
-t dukehtscourse/jupyter-hts-2019
```

## Options

You may customize the execution of the Docker container and the Notebook server it contains with the following optional arguments.

* `-e PASSWORD="YOURPASS"` - Configures Jupyter Notebook to require the given password. Should be conbined with `USE_HTTPS` on untrusted networks.
* `-e USE_HTTPS=yes` - Configures Jupyter Notebook to accept encrypted HTTPS connections. If a `pem` file containing a SSL certificate and key is not provided (see below), the container will generate a self-signed certificate for you.
* **(v4.0.x)** `-e NB_UID=1000` - Specify the uid of the `jovyan` user. Useful to mount host volumes with specific file ownership.
* `-e GRANT_SUDO=yes` - Gives the `jovyan` user passwordless `sudo` capability. Useful for installing OS packages. **You should only enable `sudo` if you trust the user or if the container is running on an isolated host.**
* `-v /some/host/folder/for/work:/home/jovyan/work` - Host mounts the default working directory on the host to preserve work even when the container is destroyed and recreated (e.g., during an upgrade).
* **(v3.2.x)** `-v /some/host/folder/for/server.pem:/home/jovyan/.ipython/profile_default/security/notebook.pem` - Mounts a SSL certificate plus key for `USE_HTTPS`. Useful if you have a real certificate for the domain under which you are running the Notebook server.
* **(v4.0.x)** `-v /some/host/folder/for/server.pem:/home/jovyan/.local/share/jupyter/notebook.pem` - Mounts a SSL certificate plus key for `USE_HTTPS`. Useful if you have a real certificate for the domain under which you are running the Notebook server.
* `-e INTERFACE=10.10.10.10` - Configures Jupyter Notebook to listen on the given interface. Defaults to '*', all interfaces, which is appropriate when running using default bridged Docker networking. When using Docker's `--net=host`, you may wish to use this option to specify a particular network interface.
* `-e PORT=8888` - Configures Jupyter Notebook to listen on the given port. Defaults to 8888, which is the port exposed within the Dockerfile for the image. When using Docker's `--net=host`, you may wish to use this option to specify a particular port.


## Running the Course Image with Singularity
Docker requires root permissions to run, so you are unlikely to be able to run Docker on a computer that you are not fully in control of.  As an alternative you can run the course image with [Singularity](https://sylabs.io/singularity/), another container system. Singularity is similar to Docker, and can run Docker images, but you do not need special permissions to run Singularity images *or* Docker images with Singularity (as long as Singularity is actually installed on the computer).

The following command uses Singularity to start up a container from the course Jupyter image.
```
export USE_HTTPS=yes; \
    singularity exec docker://dukehtscourse/jupyter-hts-2019 \
    /usr/local/bin/start-notebook.sh 
```

### Install Singularity
Here are instructions for installing:

- [Singularity version 2.6](https://sylabs.io/guides/2.6/user-guide/quick_start.html#quick-installation-steps)
- [Singularity version 3.2](https://sylabs.io/guides/3.2/user-guide/quick_start.html#quick-installation-steps)
- [Singularity Desktop for macOS (Alpha Preview)](https://sylabs.io/singularity-desktop-macos/)
