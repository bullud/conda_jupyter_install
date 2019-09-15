#!/bin/bash
#set -e
#set -x
#  echo "c.NotebookApp.ip = '$1'" >> env_install/jupyter_notebook_config.py

#if [ $# != 1 ]; then
#  echo 'need to specify the local host ip '
#  exit 1
#fi

CONDA3PATH=$HOME/ML/tools/miniconda3
INSTALLCONDA=y
DATADIR=/home/lidian/data
WORKSPACE=$HOME/ML/workspace
JUPYTERDIR=$HOME/.jupyter
ENVNAME=py3.6_pt1.0
PYTHON=3.6
CUDA=10.0
PYTORCH=1.0
TORCHVISION=0.2.2
OPENCV=3.4.1


sudo python -m pip install --upgrade pip

sudo pip  install jupyter

if [ ! -d $DATADIR ]; then
    echo 'create data dir on ssd'
    mkdir $DATADIR
fi

echo ''

if [ -d $CONDA3PATH ]; then
  read -n 1 -p "conda exist: $CONDA3PATH, reinstall y/n ?" INSTALLCONDA   
  echo ''  
  if [ $INSTALLCONDA == 'y' ]; then
    rm -rf $CONDA3PATH
  fi 
fi

if [ $INSTALLCONDA == 'y' ]; then 
  wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O Miniconda3-latest-Linux-x86_64.sh
  bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/ML/tools/miniconda3
  rm Miniconda3-latest-Linux-x86_64.sh 
  echo "conda activate $ENVNAME" >> env_install/conda.rc
  cat env_install/conda.rc >> ~/.bashrc
  sed -i '$d' env_install/conda.rc
fi

export PATH=$HOME/ML/tools/miniconda3/bin:$PATH

conda create  -y -n $ENVNAME  python=$PYTHON
conda install -y -n $ENVNAME  cython matplotlib scikit-image numpy pyyaml scipy ipython ninja typing
conda install -y -n $ENVNAME  cudatoolkit=$CUDA -c pytorch
conda install -y -n $ENVNAME  opencv=$OPENCV
conda install -y -n $ENVNAME  ipykernel
conda install -y -n $ENVNAME  pytorch=$PYTORCH torchvision=$TORCHVISION -c pytorch
#conda install -y -n $ENVNAME  pytorch=$PYTORCH -c pytorch

$HOME/ML/tools/miniconda3/envs/$ENVNAME/bin/python -m ipykernel install --user --name $ENVNAME --display-name "$ENVNAME"

if [ ! -d $DATADIR ]; then
  mkdir $DATADIR
fi
  
if [ ! -d $WORKSPACE ]; then
  mkdir -p $WORKSPACE
fi

if [ -h $HOME/jupyter ]; then
  rm $HOME/jupyter
fi
ln -s $WORKSPACE  $HOME/jupyter

if [ -h $HOME/ML/data ]; then
  rm $HOME/ML/data
fi
ln -s $DATADIR $HOME/ML/data
  
if [ ! -d $JUPYTERDIR ]; then
  mkdir $JUPYTERDIR
fi


cp env_install/jupyter_notebook_config.py env_install/jupyter_notebook_config.new.py
echo "c.NotebookApp.notebook_dir = u'$HOME/jupyter'" >> env_install/jupyter_notebook_config.new.py
cp env_install/jupyter_notebook_config.new.py ~/.jupyter/jupyter_notebook_config.py
#sed -i '$d' env_install/jupyter_notebook_config.py
rm env_install/jupyter_notebook_config.new.py

cp env_install/jupyter.service env_install/jupyter.new.service
echo "User=`id -u -n`" >> env_install/jupyter.new.service
echo "Group=`id -g -n`" >> env_install/jupyter.new.service
echo "ExecStart=/usr/local/bin/jupyter-notebook --config=$HOME/.jupyter/jupyter_notebook_config.py" >> env_install/jupyter.new.service
echo "WorkingDirectory=$HOME/jupyter/" >> env_install/jupyter.new.service 
sudo cp env_install/jupyter.new.service  /etc/systemd/system/jupyter.service
#sed -i '$d' env_install/jupyter.service
#sed -i '$d' env_install/jupyter.service
rm env_install/jupyter.new.service

sudo systemctl enable jupyter
sudo systemctl restart jupyter
sudo systemctl status jupyter
