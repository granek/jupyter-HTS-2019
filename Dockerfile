# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

FROM debian:stretch 

MAINTAINER Janice McCarthy "janice.mccarthy@duke.edu"

USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
ENV R_VERSION="3.6.2"


RUN REPO=http://cdn-fastly.deb.debian.org \
 && echo "deb $REPO/debian stretch main\ndeb $REPO/debian-security stretch/updates main" > /etc/apt/sources.list \
 && apt-get update && apt-get -yq dist-upgrade \
 && apt-get install -yq --no-install-recommends \
    wget \
    bzip2 \
    less \
    make \
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
    pkg-config \
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
    curl
 
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libxml2-dev \
    libgsl0-dev \
    libav-tools \
    fastqc default-jre \
    circos \
    parallel \
    time \
    htop

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
    lftp
    
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
    libcurl3 \
    libcurl4-gnutls-dev \
    libssl1.1 \
    libssl-dev \
#    libcurl4-openssl-dev \
    libblas-dev \
    liblapack-dev \
    libeigen3-dev \
    libpng-dev \
    libbz2-dev \
    liblzma-dev \
    libunwind-dev \
    libcairo2-dev \
    texinfo
 
# R pre-requisites
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    fonts-dejavu \
    gfortran \
    gcc  \
    graphviz \
    libgraphviz-dev \
    gnupg2 \
    openssl

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
    mkdir -p /home/$NB_USER/.local/share/jupyter/runtime && \
    printf "Host gitlab.oit.duke.edu \n \t IdentityFile ~/work/.HTSgitlab.key\n"  > /home/$NB_USER/.ssh/config && \
    echo "cacert=/etc/ssl/certs/ca-certificates.crt" > /home/$NB_USER/.curlrc

USER root

RUN pip3 install --upgrade setuptools
RUN pip3 install wheel
RUN pip3 install jupyter

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

RUN pip3 install  \
    'numpy' \
    'pillow' \
    'requests' \
    'nose' \
    'pystan' \
    'cppimport' \
    'pgmpy' \
    'pygraphviz' \
    'htseq' \
    'pysam' \
    'biopython' \
    'DukeDSClient' \
    'multiqc'

RUN pip3 install  bash_kernel && python3 -m bash_kernel.install

# downgrade matplotlib for multiqc
RUN pip3 uninstall --yes matplotlib && \
    pip3 install 'matplotlib==2.2.3'

    
# USER root    
# Activate ipywidgets extension in the environment that runs the notebook server
RUN jupyter nbextension enable --py widgetsnbextension --sys-prefix
RUN ipcluster nbextension  enable --user


USER $NB_USER

# Configure ipython kernel to use matplotlib inline backend by default
RUN mkdir -p $HOME/.ipython/profile_default/startup
COPY mplimporthook.py $HOME/.ipython/profile_default/startup/

#----------- end scipy

#----------- datascience
USER root


RUN apt-get update && \
    apt-get install dirmngr -yq --install-recommends && \
    apt-get install software-properties-common -yq && \
    apt-get install apt-transport-https -yq

# Install R
# RUN apt-get install gnupg2
# RUN mkdir ~/.gnupg && \
#      echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf && \
#      gpg2 --keyserver keys.gnupg.net --recv-keys 3F32EE77E331692F

# Add cran repo

RUN echo "deb https://cloud.r-project.org/bin/linux/debian stretch-cran35/" >> /etc/sources.list && \
    add-apt-repository 'deb https://cloud.r-project.org/bin/linux/debian stretch-cran35/'

RUN apt-get update && \
    apt-get -yq --no-install-recommends --allow-unauthenticated install \
    r-base=${R_VERSION}* \
    r-base-core=${R_VERSION}* \
    r-base-dev=${R_VERSION}* \
    r-mathlib=${R_VERSION}* \
    r-recommended=${R_VERSION}* \
    r-base-html=${R_VERSION}* \
    r-doc-html=${R_VERSION}* \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libcairo2-dev \
    libxt-dev

RUN Rscript -e "install.packages(c('IRkernel', 'plyr','devtools', 'RCurl', 'curl', 'tidyverse', 'shiny'), repos = 'https://cloud.r-project.org/')"

RUN Rscript -e "install.packages(c('rmarkdown', 'forecast', 'RSQLite', 'reshape2', 'nycflights13'), repos = 'https://cloud.r-project.org/')"

RUN Rscript -e "install.packages(c('caret', 'crayon', 'randomforest', 'htmltools'), repos = 'https://cloud.r-project.org/')"

RUN Rscript -e "install.packages(c('sparklyr', 'htmlwidgets', 'hexbin'), repos = 'https://cloud.r-project.org/')"

RUN Rscript -e "IRkernel::installspec(user = FALSE)"

#--------------------------------------------
# Install R and bioconductor packages for Kouros's notebooks
RUN Rscript -e "install.packages(pkgs = c('ROCR','mvtnorm','pheatmap','formatR'), \
            repos='https://cran.revolutionanalytics.com/', \
            dependencies=TRUE)"
RUN Rscript -e "install.packages(pkgs = c('dendextend', 'rentrez'), \
            repos='https://cran.revolutionanalytics.com/', \
            dependencies=TRUE)"

RUN Rscript -e "if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager', repos = 'https://cloud.r-project.org/'); \ 
                   BiocManager::install()"
                   
RUN Rscript -e "BiocManager::install(c('golubEsets','multtest','qvalue','limma','gage','pheatmap', 'ggbio', 'ShortRead', 'DESeq2', 'dada2', 'KEGG.db'))"

RUN Rscript -e "BiocManager::install(c('pwr','RColorBrewer','GSA','dendextend','pheatmap','cgdsr', 'caret', 'ROCR'))"

RUN Rscript -e "BiocManager::install(c('org.EcK12.eg.db','genefilter','GEOquery', 'airway'))"

# install fastq-mcf and fastq-multx from source since apt-get install causes problems
RUN mkdir -p /usr/bin && \
    	  cd /tmp && \
	  wget https://github.com/ExpressionAnalysis/ea-utils/archive/1.04.807.tar.gz && \
	  tar -zxf 1.04.807.tar.gz &&  \
    	  cd ea-utils-1.04.807/clipper &&  \
    	  make fastq-mcf fastq-multx &&  \
    	  cp fastq-mcf fastq-multx /usr/bin &&  \
    	  cd /tmp &&  \
    	  rm -rf ea-utils-1.04.807
	  
#----------- end datascience



#----------- notebook
EXPOSE 8888
WORKDIR /home/$NB_USER/work

# tini init

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

#----------- eDirect

USER $NB_USER

# RUN cd ~/work
# RUN  /bin/bash \
#   perl -MNet::FTP -e \
#     '$ftp = new Net::FTP("ftp.ncbi.nlm.nih.gov", Passive => 1); \
#      $ftp->login; $ftp->binary; \
#      $ftp->get("/entrez/entrezdirect/edirect.tar.gz");' \
#   gunzip -c edirect.tar.gz | tar xf - \
#   rm edirect.tar.gz \
#   builtin exit \
#   export PATH=${PATH}:$HOME/work/edirect >& /dev/null || setenv PATH "${PATH}:$HOME/work/edirect" \
#   ./edirect/setup.sh
  
  
# Setup up git auto-completion based on https://git-scm.com/book/en/v1/Git-Basics-Tips-and-Tricks#Auto-Completion
# RUN wget --directory-prefix /etc/bash_completion.d/ \
#      https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash

# directories to hold data for the students and a common shared space

# UNDER CONSTRUCTION: Nerd Work Zone >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# USER $NB_USER
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    art-nextgen-simulation-tools \
    art-nextgen-simulation-tools-profiles

RUN Rscript -e "BiocManager::install(c('Gviz'))"
RUN Rscript -e "BiocManager::install(c('phyloseq'))"


# UNDER CONSTRUCTION: Nerd Work Zone <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

#######
USER root

# Clean up 
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /data /shared_space 
RUN chown jovyan /data /shared_space 

# Switch back to jovyan to avoid accidental container runs as root
USER jovyan
