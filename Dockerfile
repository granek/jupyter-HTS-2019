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

# Install Tini
#RUN wget --quiet https://github.com/krallin/tini/releases/download/v0.10.0/tini && \
#    echo "1361527f39190a7338a0b434bd8c88ff7233ce7b9a4876f3315c22fce7eca1b0 *tini" | sha256sum -c - && \
#    mv tini /usr/local/bin/tini && \
#    chmod +x /usr/local/bin/tini

# Configure environment
#ENV CONDA_DIR /opt/conda


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
#    mkdir -p $CONDA_DIR && \
#    chown $NB_USER $CONDA_DIR

USER $NB_USER

# Setup jovyan home directory
RUN mkdir /home/$NB_USER/work && \
    mkdir /home/$NB_USER/.jupyter && \
    mkdir /home/$NB_USER/.ssh && \
    printf "Host gitlab.oit.duke.edu \n \t IdentityFile ~/work/.HTSgitlab.key\n"  > /home/$NB_USER/.ssh/config && \
    echo "cacert=/etc/ssl/certs/ca-certificates.crt" > /home/$NB_USER/.curlrc

# Install conda as jovyan
#RUN cd /tmp && \
#    mkdir -p $CONDA_DIR && \
#    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-4.3.30-Linux-x86_64.sh && \
#    # echo "bd1655b4b313f7b2a1f2e15b7b925d03 *Miniconda3-4.3.30-Linux-x86_64.sh" | sha256sum -c - && \
#    /bin/bash Miniconda3-4.3.30-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
#    rm Miniconda3-4.3.30-Linux-x86_64.sh && \
#    $CONDA_DIR/bin/conda install --quiet --yes conda==4.3.30 && \
#    $CONDA_DIR/bin/conda config --system --add channels conda-forge && \
#    $CONDA_DIR/bin/conda config --system --set auto_update_conda false 
    # conda clean -tipsy

# Temporary workaround for https://github.com/jupyter/docker-stacks/issues/210
# Stick with jpeg 8 to avoid problems with R packages
### RUN echo "jpeg 8*" >> /opt/conda/conda-meta/pinned

# Install Jupyter notebook as jovyan

#RUN pip3 install jupyter

#RUN conda install --quiet --yes \
#    'jupyter' 
    # 'notebook' \
    # 'jupyterhub' \
    # 'jupyterlab' # \
    # && conda clean -tipsy
    
#----------- scipy
USER root

# libav-tools for matplotlib anim
RUN apt-get update && \
    apt-get install -y --no-install-recommends \ 
      libav-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER $NB_USER

# Install Python 3 packages
# Remove pyqt and qt pulled in for matplotlib since we're only ever going to
# use notebook-friendly backends in these images

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
 #   'psutil' \
    'cythongsl' \
    'joblib' \
    'ipyparallel' \
    'pybind11' \
 #   'pytables' \
    'plotnine' \
    'xlrd' 
    
USER root    
# Activate ipywidgets extension in the environment that runs the notebook server
RUN jupyter nbextension enable --py widgetsnbextension --sys-prefix
RUN ipcluster nbextension  enable --user
USER $NB_USER

# Install Python 2 packages
# Remove pyqt and qt pulled in for matplotlib since we're only ever going to
# use notebook-friendly backends in these images
#RUN conda create --quiet --yes -p $CONDA_DIR/envs/python2 python=2.7 \
#    'nomkl' \
#    'ipython=4.2*' \
#    'ipywidgets=5.2*' \
#    'pandas=0.19*' \
#    'numexpr=2.6*' \
#    'matplotlib=1.5*' \
#    'scipy=0.17*' \
#    'seaborn=0.7*' \
#    'scikit-learn=0.17*' \
#    'scikit-image=0.11*' \
#    'sympy=1.0*' \
#    'cython=0.23*' \
#    'patsy=0.4*' \
#    'statsmodels=0.6*' \
#    'cloudpickle=0.1*' \
#    'dill=0.2*' \
#    'numba=0.23*' \
#    'bokeh=0.11*' \
#    'hdf5=1.8.17' \
#    'h5py=2.6*' \
#    'sqlalchemy=1.0*' \
#    'pyzmq' \
#    'vincent=0.4.*' \
#    'beautifulsoup4=4.5.*' \
#    'xlrd' && \
#    conda remove -n python2 --quiet --yes --force qt pyqt && \
#    conda clean -tipsy
# Add shortcuts to distinguish pip for python2 and python3 envs
#RUN ln -s $CONDA_DIR/envs/python2/bin/pip $CONDA_DIR/bin/pip2 && \
#    ln -s $CONDA_DIR/bin/pip $CONDA_DIR/bin/pip3

# Import matplotlib the first time to build the font cache.
#ENV XDG_CACHE_HOME /home/$NB_USER/.cache/
#RUN MPLBACKEND=Agg $CONDA_DIR/envs/python2/bin/python -c "import matplotlib.pyplot"

# Configure ipython kernel to use matplotlib inline backend by default
RUN mkdir -p $HOME/.ipython/profile_default/startup
COPY mplimporthook.py $HOME/.ipython/profile_default/startup/

USER root

# Install Python 2 kernel spec globally to avoid permission problems when NB_UID
# switching at runtime.
#RUN $CONDA_DIR/envs/python2/bin/python -m ipykernel install

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
    pkg-config && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install dirmngr -yq --install-recommends && \
    apt-get install software-properties-common -yq &&\
    apt-get install apt-transport-https -yq 

# Public key for cran 
# RUN echo "mQGiBEXUFiURBADkTqPqcRYdLIguhC6fnwTvIxdkoN1UEBuPR6NYW4iJzvRSas/g5bPo5ZxE2i5BXiuVfYrSk/YiU+/lc0K6VYNDygbOfpBgGGhtfzYfFRTYNq8QsdD8L8BMYtOu5rYo5BYta0vuantIS9mn9QnH7885uy5tX/TXO7ICYVHxnFNr2wCguNtMdz9+DRQ38n4iiHzTtj/7UHsD/0+0TLHHvY1FfakVinamR9oCm9uH9PmkGTy6jRnrvg5Z+TTgygiDdTBKPc1TqpFgoFtqh8G5DpDPbyh5GzBj8Ky1mBJb3bMwy2RUth1cztHEWI36xuCl+KrLtA4OYuCwJJZhOWDIO9aO2LW5kJhIwIuvSrEtOgTxpzy82g7eEzvLBADUrQ01fj+9VDrO2Vept8jtaGK+4kW3cBAG/UbOrTjt63VurXwyvNb6q7hKFUaVH42Fc0e64F217mutCyftPWYJwY4SR8hUmjEM/SYcezUDWWvVxmkF8M4rMhHa0j+q+et3mTKwgxehQO9hLUqRebnmJuwNqNJKb9izsPqmh83Zo7Q7Sm9oYW5uZXMgUmFua2UgKENSQU4gRGViaWFuIGFyY2hpdmUpIDxqcmFua2VAdW5pLWJyZW1lbi5kZT6IRgQQEQIABgUCRdQ+nQAKCRAvD04U9kmvkJ3+AJ4xLMELB/fT1AwtR1azcH0lKg/TegCdEvtp3SUfaHP3Jvg2CkzTZOatfFuIRgQQEQIABgUCS4VoCgAKCRDvfNpxC67+5ZFyAKCAzgPTqM6sSMhBiaZbNCpiVtwDrQCgjMy+iqPm7SVOCq0XJsCCbxymfB+IXgQTEQIAHgUCRdQWJQIbAwYLCQgHAwIDFQIDAxYCAQIeAQIXgAAKCRAG+Q3lOBukgM09AKCuapN6slttAFRjs2/mgtaMMwO9sgCfZD2au39Oo8QLXZhZTipN8c7j9mM==BRgm" > key.asc

RUN echo  "mQINBFgrUUoBEADRwPTWV1OsmT4ulnwN6Oj3xQRo7CET3nd0CdaZ50NUAha91is+mx2nPhDa \
7GqxGDKt3Nl/aYMBPrDglDjfbobxXuoBARhKMaYHWf9ev2ZGJzvBfyppVIpC4tg0tLVhWQyU \
95FhJxEsrSH3cAsJ9wGDzp2mo9OjrdFo4qYLi1p/INVdFnXorJ0PrmbwcF0xtIjrf+JIk3t9 \
/Y0l9rLUB0AMoE/sr2XHvnfkmNz+HREXbC9Dg+e3oJKbtONTFbAmaoC77U2WOnNJS2mA3kz0 \
A9P5uvwwt1BknGFDTWp1KnzhJE7G1+7R9zkKG34QLja0o/N4xCo3hVGLcMPd4ZiX64hevZzp \
aLhpjt3pgyNKEbHtvjCc9f8mFmcNXRP49UzWCi1m5GraQTg1NzSwQxP/VKWnsGdx44YcGMNe \
0RCa+z6AHXUS0j+xbsuoVSlazvmu1a2/ODm7EIJKaM6kdmAhTzZGjqva9+hkrtBOeHsetfyX \
lEM3CImT+DI/MGWfueuJvYmUz+skJDxSNiH0113+6gKjSvxsGtvOPxMTfMklTvW0mtYzCauz \
ovc8T1tV+H654PyfkckZpQq0jOTqMA//6XXP+nBaK87gJfqooQV2Z4v6IJH/a8VNvjdBSg1V \
dSPVg74jeGD3XDu7S8HBJC2hs9VRb/+XMbn6Zhe2A1mRAHoXoQARAQABtCVKb2hhbm5lcyBS \
YW5rZSA8anJhbmtlQHVuaS1icmVtZW4uZGU+iQI4BBMBAgAiBQJYK5sgAhsDBgsJCAcDAgYV \
CAIJCgsEFgIDAQIeAQIXgAAKCRCtX5YKJWoEr+6SEACyqB1y/EeN+AS0/GiHMowruqYTuVgW \
wKUGD2Ci5leaJtz6E2yBbDCXnEJ8hQ30MUK95znPWwpf+hKUlGplQFlCZUEa09DOkOg+nsOh \
rwDvV8T2hagU0kHrESFEtPksYbN5milDqeSeGoZkyxWZVRoqjJo0dDz+seMJqPZCOC/ySRb2 \
mi+WG3M7vlBSCyLjxLD3UAU7U5tXFJqtgA13OTScP7v5RqlV2rrd4xzPjz5b4Yw1at7LlGJm \
LwtqFJnOhmrd4Pd5g1OAQQ+o3AoCOTd5g7hBKCUEviMNKx6E02h7rKpgkw317zf0KHTekXAQ \
kDPsP939vjjvcizasV2V4VbCz/I5QKEfoiUNgaizJ1LKs8XxpgXFWs7NZh8VxEkFfuO5AUhA \
IkDsfggHr1gEv1hp3YLtkNA4slVTypw3Zm+fTyB2Q2FIM8kLJvD7VBi/qNwAoggKhN7xLy2B \
3gx3c7G9nKkye6pGYBZ886guXLdC+J7pFM6xgm2jMyUKFvyIZi/zh74TmN45QvaBIbt9Ot34 \
D/joyOjzhokY7YyS6/XbI9j7ErSBF1N8sEOwWvCGi/UwTsDWY2bUV7SWFbk7SN8yn39J1jdO \
FqzMsYhM6JkOY08Nt4ylhEoWDkdyS88EcHM2YIPxtYpLqXt10C9Qruuy2vDDd4j8T++/RXLe \
XPXZ3YhGBBARAgAGBQJYK6hcAAoJEC8PThT2Sa+QMfIAoNLsseulhh6mmnQDmsZvFZU4JJ3a \
AKCoBkPnQyWtjEzz0Eb5tTrq98SjfYhGBBARAgAGBQJYK6nbAAoJEAb5DeU4G6SAeMkAn0M+ \
+kjMtfdWGymQ/c04u+C4exomAJ92dvCvAyLAUDLM6kwr7kACuaD7+bRESm9oYW5uZXMgUmFu \
a2UgKFdpc3NlbnNjaGFmdGxpY2hlciBCZXJhdGVyKSA8am9oYW5uZXMucmFua2VAanJ3Yi5k \
ZT6JAjsEEwECACUCGwMGCwkIBwMCBhUIAgkKCwQWAgMBAh4BAheABQJYK6W+AhkBAAoJEK1f \
lgolagSvP4kQAMb4rAYk4YoyBjIwemiZ+tK+xz1df6JyW9fUT6ssQemxvRQyHisnLu8d4sgu \
KRksoM0ej2uzYDFdcVVir6LOXxz/KS69hf4mhz0iWdfCkyPzDu8jIttu5u1RnB5ckgVSFMgE \
kjImLYF2QdvyQlmumAbmFwXS1buKxEUdKT7cBRhX7PmENIktk5xh89AcS5wgurApj2TT9OS4 \
D40plpJRFlu9qcEh9C23tdQoyO5PymC0bsHoXZO8IVgf3Soi2hPSTw+v09Xz64CYC0hbRton \
M7WvLvqzLMj6zQPZXDI4XeV/+XRBr4twM0+cFlsfQRe555c0stG5RlkQuRApu1ELvs/2zjwz \
cM/XIjidIyK7Nj4mBH0wlb9v2ow3EGiHN4TiDTGkz0HhY8ULk5v2qyV7jdiB0gjsFeN2+59o \
v56NOzedlz6rkXusU5q8WzVMTJC34YOuFWwWVnSIsS9cMC/21GO10kdpu/1cp+sMRsg/CdQf \
aDv9o7NHb9mwgV8BiWMA79FuIum3/EjGXD8rndfi68jiWA7FkhtsC0ufYs4ZAPBFIMlqugQJ \
FPNR7/XL96y9K1YAf3nZmGkjj9BX8RGVvTJOaDnC1+xYZxqysntrcGqQDXoE+ioDlVUUi30g \
w/enf4SBR+sKCCCXasFZNus1U9XxvQzn2hUsEnpkIbM5DKBBiEYEEBECAAYFAlgrqFwACgkQ \
Lw9OFPZJr5AgRACgot5RuRWnZPHxJl/DLh5dUDPE52EAoKTYcBZbiFb5Sw8MWwwRBbKg2N6H \
iEYEEBECAAYFAlgrqdsACgkQBvkN5TgbpIBSXgCgsbzDlD+5CQhicxNjIFL7+O+RICEAoI5O \
X3elj3Ia+EqOiZu1JxQ43Rl5uQGNBFgraOABDAC8T4nRSYijZXHiv6IkxbtZovleiy+QEUka \
xR1WUwX312TithyBRAZMhQQUMHg4TzfUMXdx1koDY6Yicz+eiSVJBpZc0eE7TnkH6MyCnLnM \
MiHJ4rIGTMAIBUxCIsYCPoiVJY8QCvgkGtUrMFKJ7++4v6GeYqw3w5jv1homCaOO9FW98g13 \
nh0ZuejGmBazh9TaYcnt9pnOUtlN0f3Le7UY2VVmq4UHHoobciN3gJcsH5Ier6lkx8E7xHNs \
WBhhEK+DxVhXz4MWgU0RYnUgjmmxa/HFNfRmfonz2TBBHSNEiuIOctX2D/E+1ZZIVZkqGFUy \
OV+jWLm/rUWr8T58vdSDU0PCQMJth7hfGsY/MpIIQ1C4s/if8IuLA/h5nwQJ/LM3rk+ey42e \
rOifoMp4SWp9qBWT4ZNLwhpBd+eez7K6SHn9cLeAGUDlUrj8nLGEplelt52nBh+xcDRYY52Y \
M5SQDA3wtJrKFCPT1+ez7izaCXDq0dqGB3/byq3Yro33L6sAEQEAAYkDxAQYAQIADwUCWCto \
4AIbAgUJCWYBgAGpCRCtX5YKJWoEr8DdIAQZAQIABgUCWCto4AAKCRD8rioOEVw9ijaNC/95 \
Syw+Tyi3ihahdjLxQVuzOKFfkGc2yZ4Z1NI7ydRjhBPXTn/768ALcSWBisSWISSe2sOz/flJ \
NiSZo8cY2rn+DWn9RYsv0aXna9guPLyt3iCfxNuhhT30SghyOydQ9lCVGH5/iFXq2Epellzz \
rEQm1DB3Arsca+Suk4YVJsufEV2fHAaevpxetNeQXzxlUwnmeBK7l3/7SHUn4iAuxYtP7cYw \
6B2+tWdrOvPc0b0/Hxc95GdysAyVaONLsOexZxriCexZDjimOteWkG9tW4AORDnTvtNL+57C \
sDMvcKc4SlWa30hP1NySr51H1sy5YVtMBsSNRjjP1HQH2Sd3Q3ehwI/3B/b6dRqopZQICX/t \
fsxZKsfmA4S7Hvv7bfFUzMpiB3nkoywQC4Eob1DvZx4wsNrVcnUYK7tT7jOLCJRMiSGFwEot \
aM3o8W+wPHFhDsTRctYM0U1fUqiKXO3/qZROKURRf4kxCN/0pDzsjAKGe3JZvBoA2dBBFkIQ \
epGyF7P8iA/+IskqDQj+Muci15bNiUT6G8ugfcEyh00N8kBiyhR4YaCgpaHjkqY6NXFsRR3E \
Af8lm/4SijeFxzP/gDl2JI7Pl1UgwaylAMWXpFj8KpX/M3iuzgAOuUozo704PT+S6IIC+nVE \
FUczp1HIcKvUdVOOkWPSbJ8zL/RlfGiptHvBnnN1ePfNQkf5F9GO5uF3LjliTUKKGrVXtvmR \
K+o9DUZ1T/4FYYcN0a6Gbuu4sCazzleR/nWKGoPj/sZHtWxNsN7MlHMG64+W+AVpQvRdLiDm \
yQAS0R5MqFwUPEMA1TototkxzT9c7jD2tKmX5Ddao3wXH2ed19By14W3lT3QMGQViNMzEsz6 \
763dep02pa3H8HIlwWuIGrt3vU+5h1wnPB289KF2bze6zGvyJqMIxMzgvnjxC77LlGaTepWE \
RXvc+98K8FPjXXPZxokR9/a77unGeoZR7NPkX4z6RX5bNsjZlnI6wouTgAzs5GBl88Y4Coo9 \
Uk72RZdKW8d/h6VErRU48PQjUmp8RkwUoH0Qd6QIDHQvSPDmZHZeDnHqlkAd0cH6p2I3hVOy \
cvYI3kA7Fh2YutLe+ab5+nvNVWbhnqpCxfHbwM/Ic5h8d2ihiaa39RDs65aXqJ5eWbmFG/GC \
I7WK6C31tm52ntFbY9XgVCP2hND2nE1zBqwTgHFwD7IU01a5AY0EWCtsFAEMANHVfEshHFjD \
zzxbfOmUfafxMvJvsVqCbak0fMzAs9b5+sQ4BXhvG96ZW7hBGZbngej8cVdvw86/QYV5+SR3 \
WecaB/YxA3kPmGT3aIZtNJAAMxQtr3ahdaqAjlRNUXlE4fJlk9qNf7aWQPN56lGc6L2CZh42 \
HdPsO+XKgB+HDU85Emwd6czyivb23BkMJ+KdTwBhLf/vglm2I4XgEdiUhvXwiu/2VUsqoEaE \
epfOT2UoaeZAPyZyWXB8t9A6pYsH6sqVb2Q7gnXAaxKRA6FG2eBgZ4wu2JAVt8B6cMF34xo+ \
iDGV1DfT2Ihlz1CIfzmQ8r4L2GgJ2Og43KgoRcJmilG9WKa2H6mlKT8CCnxO17GyxRkSA04L \
0mbaHU7rqjH8teVyRkKecuhll5lvRHS5b0oMLANZVGZHHijMBtXgsJKAwzPwDUa7J8/3sMzC \
uN+aw/IaNzN7inJzzfWjLFuaGCu8HFtWkiBa1w1CrbJVG7rgqL54+ZN2XqnO+iC0sBkhIQAR \
AQABiQIlBBgBAgAPBQJYK2wUAhsMBQkJZgGAAAoJEK1flgolagSvHYAP/0o7YVoMYv4R619j \
DQhEPhb8+qTIUUSpD1+DXDvf0KPzn3xf3JLNfkcMUPBmyXkOOx9bFXUG1xzNLMZfu1Wl1HDx \
s5mQwVNiiLFWt+bS58kb/j0nPJzPY8xYwYW+EN6miAVjIeQDgDtPK4VnDG36EUfsT/CG0F3P \
KhMR/R0Jp6NDhEdh6qTnprI8DWuZEono7zg71WVVK36JRvZmqcF/J6j1FrPQtepzUTDKwgln \
1sivnp/CWXkyoZwTHwKizAjRs7HQQ00UvIYlyJmLxcD9yLZSsyVveGRzyd3WvDpFbWAoocna \
yLINDM+WjZ5/HUeed+Ss4hlMTpH5I38dZbFI22V/aOM5oQPJe/Y2glB2gtIFF2bvR+TgCdFT \
B15HhE0fw0voO7MlcD2AaIsSeskm6N9d7E3TXqruabFU0Cc0AjTXCeD3zDVL3PWHdOIJjdFQ \
7BMlTzLJXxWx1k9TY1B39ule+rNw2sf/3J5TLTTDTAX5+PyY/L8IpZxZVQigzsX5tmVY/J4y \
zr2ReTVgf7msxGU83tASlNEebE658+aN0ILllUG7cWD41U1PMstmQCsqZOfKSz0XWQExY7aS \
p5gHMoBwT7DJKZHjr+uYeQPdzC86i1RFV/HZicTlHx7eUDSMTnMtmL5ezkWywpMBOfI6XAsk \
7gR+AcMM6pjehMwUJ5wguQINBFgrUUoBEACU7fGWxi80aeDLpj/vivRQ9VwD4IEcKfhwfYus \
bhnzIozoaTrA82GSpOH8217TzorQ+Cpf3kMXT379C8lovs5F18szNJuQ1uuaQvUye12BmkWa \
glN8Cla2zKtN9pTa6sjgVvxeT3kEEcuzUiwjSmC3AxCEv2Y7gekYM9rTShlcMt97YlqqW28T \
09SoXejKtyHTsoRlMyBxOqy3cRIkuSzQTITH+EmFFCMjMqC8Rg7Bk3rZ2gwib3PltOz1WBh7 \
zXIApI+GMyqLE1OtTj01UGuK7b79/CIhmpq+ZdhyHbNnUQiOe7izg5BO60EsRFV7/XFDkpLD \
NoEGCA1GFVHH9c11RTTQtga9oPq9ZJSQ7vlPPNVhgXvF7hgyXwmiE3171gXlza8teatyJnif \
mVJQCEOxmJOrL61wVpX4akyfQicNO2mZ7CP3HS/v83A1SealZkxd4tIvtKKfwedcI7CHF9U1 \
+4v+lk49tFWETD+ntC8moBgSOKLAkW+l1dqYcdVLWsp2ZmBcGrz4XN4Lh9vOVTHkp09N8Mny \
IJxPBN0AwZh4ohdqwBoir0JH4cUzkGqHcCL/n5IjCStlvw2VlOdI4JZNdThOOhoROfd6Azmc \
y+OTURpGTbL6vxDwbVZ8wZwPdKBh1O1eEdYbowBT/BSC0yOdzrFhcV1V0qbl2OVdaM/aLwAR \
AQABiQIfBBgBAgAJBQJYK1FKAhsMAAoJEK1flgolagSvW8sP/2fR0Msh//zZCV+/DMiExySY \
xdx2LC4Iwh7ZWog/goY+nzrU6DtHiylMuf0PI9rWB4EBYne9uPAajK4PdPJwED5pTFuxON3C \
lsQKWpxDrzoSfAvqRFt2CdVp930fsmV281iWjMF6ARO5smcR9QN1YCgUvVnaiyBAGqBO9Y5X \
u8HYGhQU8pB2p4MKyKg+SzdOXhICmkjYuTPt6CjL5ItqqJBP9Iw/ofi1qgFeVb+L/aQ0vN45 \
uxmcFGOu5dDhkMAM6KYeLuGa8VI9xWGE7zsXZ0EuAhFYsNMTud0Uu+KKEChp9BbHK0bk8lsw \
qPjdk4qZZ2E3iV3aJyjAV/BQKvCMCxwdgwREWPQtlFtvUzcSJZPNEW7joym489qMpDzDwJSW \
Mc16iwp9UV7Xn1EJl1CLx+RFBXonvvvi5oAxUt12y+NuBxABR7cEI3bU4Pi0dVToLmVZDPQL \
e6w+kT0nCtVyJIC81BGur4NpMQz7VoSQubn98d9D87eoSbgPdTA3CPRsNe9MrvRMzi18Vjj2 \
GD9tlZowSuASeOki8LpSoz3kVOWJRr4HdQrLnVr15zUfZxClPaBhlbMDZ90y8n/FsAHd+831 \
Z7CQYbS22YAjv7ES23X2AOGXf+nJVhAmTkkZeN5ojvuGBCF1G04h4AIDF1uADZ4vHYDtokwc \
J1AGGEIkUBQt \
=hOCg" > key.asc


# Add cran repo    
RUN echo "deb https://cloud.r-project.org/bin/linux/debian stretch-cran35/" >> /etc/sources.list

RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/debian stretch-cran35/' && \ 
    apt-get update && \
    apt-cache policy r-base
# R packages

RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/debian stretch-cran35/' && \ 
    apt-get update && \
    apt-get install -yq --allow-unauthenticated -t stretch-cran35 r-base=3.6.0-1~stretchcran.0 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN Rscript -e "install.packages(c('irkernel','plyr','devtools','tidyverse','shinyr'), repos = 'https://cloud.r-project.org/')"
RUN Rscript -e "install.packages(c('rmarkdown', 'forecast', 'rsqlite', 'reshape2', 'nycflights13'), repos = 'https://cloud.r-project.org/')"
RUN Rscript -e "install.packages(c('caret', 'rcurl', 'crayon', 'randomforest', 'htmltools'), repos = 'https://cloud.r-project.org/')"
RUN Rscript -e "install.packages(c('sparklyr', 'htmlwidgets', 'hexbin'), repos = 'https://cloud.r-project.org/')"


#----------- end datascience

EXPOSE 8888

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

WORKDIR /home/$NB_USER/work

# Configure container startup

CMD ["start-notebook.sh"]

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
    ea-utils \
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
# COPY mplimporthook.py $HOME/.ipython/profile_default/startup/

USER root

RUN Rscript -e "if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager', repos = 'https://cloud.r-project.org/'); \ 
                   BiocManager::install()"
                   
RUN Rscript -e "BiocManager::install(c('golubEsets','multtest','qvalue','limma','gage','pheatmap'))"

# RUN conda install --quiet --yes -c r r-essentials
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

