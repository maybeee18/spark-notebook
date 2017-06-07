#!/bin/bash

# AWS EMR bootstrap script for installing Jupyter notebooks using Anaconda
# 2017-06-06 - Tested with EMR 5.6.0

ANACONDA_VERSION="4.3.1"
ANACONDA_PYTHON_VERSION="2"

# check for master node
if grep isMaster /mnt/var/lib/info/instance.json | grep true;
then
    # Download, install and set environment for Anaconda Python
    curl -o /mnt/tmp/anaconda.sh https://repo.continuum.io/archive/Anaconda$ANACONDA_PYTHON_VERSION-$ANACONDA_VERSION-Linux-x86_64.sh
    bash /mnt/tmp/anaconda.sh -b -p /mnt/anaconda
    echo '' >> /home/hadoop/.bashrc
    echo 'export PATH="/mnt/anaconda/bin:$PATH"' >> /home/hadoop/.bashrc
    echo 'export SPARK_HOME=/usr/lib/spark' >> /home/hadoop/.bashrc
    echo 'export PYTHONPATH=$SPARK_HOME/python/:$SPARK_HOME/python/lib/py4j-src.zip:$PYTHONPATH' >> /home/hadoop/.bashrc
    source /home/hadoop/.bashrc
    python --version

    # Create the workspace and jupyter and ipython config directories
    mkdir -p /mnt/workspace
    mkdir -p ~/.jupyter
    mkdir -p ~/.ipython/profile_default

    # Generate the Jupyter notebook password
    NOTEBOOK_PASSWORD="$( bash <<EOF
python -c 'from notebook.auth import passwd
print(passwd("$1"))'
EOF
    )"

    # Write the jupyter_notebook_config
    echo "c = get_config()" > ~/.jupyter/jupyter_notebook_config.py
    echo "c.NotebookApp.ip = '*'" >> ~/.jupyter/jupyter_notebook_config.py
    echo "c.NotebookApp.open_browser = False" >> ~/.jupyter/jupyter_notebook_config.py
    echo "c.NotebookApp.notebook_dir = '/mnt/workspace'" >> ~/.jupyter/jupyter_notebook_config.py
    echo "c.NotebookApp.password = u'$NOTEBOOK_PASSWORD'"  >> ~/.jupyter/jupyter_notebook_config.py

    # Write the ipython_config
    echo "c = get_config()" > ~/.ipython/profile_default/ipython_config.py
    echo 'c.InteractiveShellApp.exec_files = ["/home/hadoop/s3helper.py"]' >> ~/.ipython/profile_default/ipython_config.py

    # Download s3helper.py TODO: URL needs to be updated
    curl -o /home/hadoop/s3helper.py https://raw.githubusercontent.com/kevincoakley/spark-notebook/klc/provision/remote/s3helper.py

    # Download the FileIO notebook to the workspace TODO: URL needs to be updated
    curl -o /mnt/workspace/FilesIO.ipynb https://raw.githubusercontent.com/kevincoakley/spark-notebook/klc/provision/workspace/FilesIO.ipynb

    # Install Python 3 kernel
    #conda install nb_conda_kernels -y
    #conda create -n py36 python=3.6 ipykernel -y

    # Install additional Python modules
    conda install -c conda-forge jupyter_nbextensions_configurator -y

    jupyter notebook &
fi