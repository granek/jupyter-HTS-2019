# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

FROM debian:stretch 

MAINTAINER Mark McCahill "mark.mccahill@duke.edu"
# Modified by Janice McCarthy 5/9/2019

USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
RUN REPO=http://cdn-fastly.deb.debian.org \
 && echo "deb $REPO/debian stretch main\ndeb $REPO/debian-security stretch/updates main" > /etc/apt/sources.list \
 && apt-get update && apt-get -yq dist-upgrade \
 && apt-get install -yq --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    git \
    ssh \
    vim \
    jed \
    emacs \
    xclip \
    build-essential \
    python-dev \
    python3-dev \
    unzip \
    libsm6 \
    pandoc \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-fonts-extra \
    texlive-fonts-recommended \
    texlive-generic-recommended \
    libxrender1 \
    inkscape \
    rsync \
    gzip \
    tar \
    python3-pip \
    apt-utils \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

ENV SHELL /bin/bash
ENV NB_USER jovyan
ENV NB_UID 1000
ENV HOME /home/$NB_USER
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV PATH $HOME/.local/bin:$PATH


# Create jovyan user with UID=1000 and in the 'users' group
RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER

USER $NB_USER

# Setup jovyan home directory
RUN mkdir /home/$NB_USER/work && \
    mkdir /home/$NB_USER/.jupyter && \
    mkdir /home/$NB_USER/.ssh && \
    printf "Host gitlab.oit.duke.edu \n \t IdentityFile ~/work/.HTSgitlab.key\n"  > /home/$NB_USER/.ssh/config && \
    echo "cacert=/etc/ssl/certs/ca-certificates.crt" > /home/$NB_USER/.curlrc

USER root

# libav-tools for matplotlib anim
RUN apt-get update && \
    apt-get install -y --no-install-recommends \ 
      libav-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER $NB_USER

RUN pip3 install --upgrade setuptools
RUN pip3 install wheel
RUN pip3 install --user jupyter

RUN pip3 install --no-cache-dir  \
 #   'nomkl' \
    'ipywidgets' \
    'pandas' 
    
RUN pip3 install --no-cache-dir 'numexpr' \
    'matplotlib' \
    'scipy' \
    'seaborn' 
    
RUN pip3 install --no-cache-dir 'scikit-learn' \
    'scikit-image' \
    'sympy' \
    'cython'
    
RUN pip3 install --no-cache-dir 'patsy' \
    'statsmodels' \
    'cloudpickle' \
    'dill' 
    
RUN pip3 install --no-cache-dir 'numba' \
    'bokeh' \
    'sqlalchemy'
 #   'hdf5' \
 
RUN pip3 install --no-cache-dir 'h5py' \
	'pyzmq' \
    'vincent' \
    'beautifulsoup4' \
    'openpyxl'
    
RUN pip3 install --no-cache-dir 'pandas-datareader' \
    'ipython-sql' \
    'pandasql' \
    'memory_profiler'\
    'psutil' \
    'cythongsl' \
    'joblib' \
    'ipyparallel' \
    'pybind11' \
    'tables' \
    'plotnine' \
    'xlrd' 
    
USER root    
# Activate ipywidgets extension in the environment that runs the notebook server
RUN jupyter nbextension enable --py widgetsnbextension --sys-prefix
RUN ipcluster nbextension  enable --user
USER $NB_USER


# Configure ipython kernel to use matplotlib inline backend by default
RUN mkdir -p $HOME/.ipython/profile_default/startup
COPY mplimporthook.py $HOME/.ipython/profile_default/startup/


USER $NB_USER

#----------- end scipy

#----------- datascience
USER root

# R pre-requisites
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    fonts-dejavu \
    gfortran \
    gcc  \
    graphviz \
    libgraphviz-dev \
    gnupg2 \
    openssl \ 
    pkg-config && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install dirmngr -yq --install-recommends && \
    apt-get install software-properties-common -yq &&\
    apt-get install apt-transport-https -yq 


# Add cran repo    
RUN echo "deb https://cloud.r-project.org/bin/linux/debian stretch-cran35/" >> /etc/sources.list

RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/debian stretch-cran35/' && \ 
    apt-get update && \
    apt-cache policy r-base
# R packages

RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/debian stretch-cran35/' && \ 
    apt-get update && \
    apt-get install -yq --allow-unauthenticated -t stretch-cran35 r-recommended=3.5.3-1~stretchcran.0 \
             r-base=3.5.3-1~stretchcran.0 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN Rscript -e "install.packages(c('IRkernel','plyr','devtools','tidyverse','shinyr'), repos = 'https://cloud.r-project.org/')"

RUN Rscript -e "install.packages(c('rmarkdown', 'forecast', 'rsqlite', 'reshape2', 'nycflights13'), repos = 'https://cloud.r-project.org/')"

RUN Rscript -e "install.packages(c('caret', 'rcurl', 'crayon', 'randomforest', 'htmltools'), repos = 'https://cloud.r-project.org/')"

RUN Rscript -e "install.packages(c('sparklyr', 'htmlwidgets', 'hexbin'), repos = 'https://cloud.r-project.org/')"

RUN Rscript -e "IRkernel::installspec(user = FALSE)"


#----------- end datascience

EXPOSE 8888
WORKDIR /home/$NB_USER/work


# tini is included in docker. Just use --init in run command
# Or not. Competing documentation...

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]


# Configure container startup

CMD ["/usr/local/bin/start-notebook.sh"]

# Add local files as late as possible to avoid cache busting
COPY start.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/
COPY start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py /home/$NB_USER/.jupyter/
RUN chown -R $NB_USER:users /home/$NB_USER/.jupyter

#--------- Duke-specific additions ---
# add bash kernel for the user jovyan
USER jovyan
RUN pip3 install  bash_kernel && python3 -m bash_kernel.install

USER root

RUN pip3 install  \
    'numpy' \
    'pillow' \
    'requests' \
    'nose' \
    'pystan'
    
USER root

# we need dvipng so that matplotlib can do LaTeX
# we want OpenBLAS for faster linear algebra as described here: http://brettklamer.com/diversions/statistical/faster-blas-in-r/
# Armadillo C++ linear algebra library - see http://arma.sourceforge.net
RUN apt-get update \
 && apt-get install -yq --no-install-recommends \
    dvipng \
    libopenblas-base \
    libarmadillo7 \
    libarmadillo-dev \
    liblapack3 \
    libcurl4-openssl-dev \
    libblas-dev \
    liblapack-dev \
    libeigen3-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
 
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    graphviz \
    libgraphviz-dev \
    pkg-config && apt-get clean && \
    rm -rf /var/lib/apt/lists/*
 

USER jovyan
# ggplot
#
#RUN pip install ggplot

RUN pip3 install cppimport
RUN pip3 install pgmpy
RUN pip3 install pygraphviz


####### start HTS-summer-2018 additions

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    less \
    make \
    libxml2-dev \
    libgsl0-dev \
    fastqc default-jre \
    circos \
    parallel \
    time \
    htop \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN echo "deb http://ftp.debian.org/debian stretch-backports main" >  /etc/apt/sources.list.d/backports.list && \
    apt-get update && \
    apt-get -t stretch-backports install -y --no-install-recommends \
    bwa \
    samtools \
    tabix \
    picard-tools \
    openjdk-11-jdk \
    openjdk-11-jre \
    sra-toolkit \
    bcftools \
    bedtools \
    vcftools \
    seqtk \
#    ea-utils \
    rna-star \
    lftp \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#  this part of the build hangs seemingly forever - so comment it out for now
# RUN Rscript -e "install.packages(pkgs = c('pwr','RColorBrewer','GSA','dendextend','pheatmap','cgdsr', 'caret', 'ROCR'), \
#    repos='https://cran.revolutionanalytics.com/', \
#    dependencies=TRUE)"
# RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); \
#     biocLite(pkgs=c('DESeq2','qvalue','multtest','org.EcK12.eg.db','genefilter','GEOquery','KEGG.db','golubEsets', \
#     'ggbio', 'limma'))"


# Install R and bioconductor packages for Kouros's notebooks
RUN Rscript -e "install.packages(pkgs = c('ROCR','mvtnorm','pheatmap','formatR'), \
            repos='https://cran.revolutionanalytics.com/', \
            dependencies=TRUE)"
RUN Rscript -e "install.packages(pkgs = c('dendextend'), \
            repos='https://cran.revolutionanalytics.com/', \
            dependencies=TRUE)"
#RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); \
#    biocLite(pkgs=c('golubEsets','multtest','qvalue','limma','gage','pheatmap'))"

USER $NB_USER


# Configure ipython kernel to use matplotlib inline backend by default
RUN mkdir -p $HOME/.ipython/profile_default/startup
RUN mkdir -p $HOME/thisisatest
# COPY mplimporthook.py $HOME/.ipython/profile_default/startup/

USER root

RUN Rscript -e "if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager', repos = 'https://cloud.r-project.org/'); \ 
                   BiocManager::install()"
                   
RUN Rscript -e "BiocManager::install(c('golubEsets','multtest','qvalue','limma','gage','pheatmap', 'ggbio', 'ShortRead', 'DESeq2', 'dada2'))"

# RUN conda install --quiet --yes -c bioconda bioconductor-ggbio
#RUN conda install --quiet --yes -c bioconda bioconductor-shortread
#RUN conda install --quiet --yes -c bioconda bioconductor-dada2
#RUN conda install --quiet --yes 'nbdime' 
#RUN conda install --quiet --yes -c bioconda bioconductor-deseq2 bioconductor-pathview r-rentrez
#RUN conda install --quiet --yes -n python2 --channel https://conda.anaconda.org/Biobuilds htseq pysam biopython tophat

# add htseq-count to path
#ENV PATH=${PATH}:$CONDA_DIR/envs/python2/bin

# Setup up git auto-completion based on https://git-scm.com/book/en/v1/Git-Basics-Tips-and-Tricks#Auto-Completion
# RUN wget --directory-prefix /etc/bash_completion.d/ \
#      https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash

# directories to hold data for the students and a common shared space
#######
# RUN mkdir /data /shared_space 
# RUN chown jovyan /data /shared_space 

####### end HTS-summer-2018 additions

#------end Duke-specific additions ---

# Switch back to jovyan to avoid accidental container runs as root
USER jovyan

