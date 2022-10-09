#!/bin/sh

# Stops script execution if a command has an error
set -e

INSTALL_ONLY=0
# Loop through arguments and process them: https://pretzelhands.com/posts/command-line-flags
for arg in "$@"; do
    case $arg in
        -i|--install) INSTALL_ONLY=1 ; shift ;;
        *) break ;;
    esac
done

if [ ! -d "/usr/local/cuda" ]; then
    echo "Installing CUDA 11.3 runtime. Please wait..."
    mkdir -p $RESOURCES_PATH"/cuda-11-3"
    cd $RESOURCES_PATH"/cuda-11-3"
    NVARCH=$(uname -m) 
    NV_CUDA_CUDART_VERSION=11.3.109-1
    NV_CUDA_COMPAT_PACKAGE=cuda-compat-11-3

    # Instructions from: https://gitlab.com/nvidia/container-images/cuda/-/tree/ubuntu18.04/10.0
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/${NVARCH}/3bf863cc.pub | apt-key add -
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/${NVARCH} /" > /etc/apt/sources.list.d/cuda.list 
    # add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/${NVARCH}/ /"
    # echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list
    # apt-get update && apt-get install -y --no-install-recommends cuda-cudart-10-0=10.0.130-1 cuda-compat-10-0
    # ln -s cuda-10.0 /usr/local/cuda
    # apt-get update && apt-get install -y --no-install-recommends cuda-libraries-10-0=10.0.130-1 cuda-nvtx-10-0=10.0.130-1
    apt-get update && apt-get install -y --no-install-recommends \
        cuda-cudart-11-3=${NV_CUDA_CUDART_VERSION} \
        ${NV_CUDA_COMPAT_PACKAGE}

    NV_CUDA_LIB_VERSION=11.3.1-1

    NV_NVTX_VERSION=11.3.109-1
    NV_LIBNPP_VERSION=11.3.3.95-1
    NV_LIBNPP_PACKAGE="libnpp-11-3=${NV_LIBNPP_VERSION}"
    NV_LIBCUSPARSE_VERSION=11.6.0.109-1

    NV_LIBCUBLAS_PACKAGE_NAME=libcublas-11-3
    NV_LIBCUBLAS_VERSION=11.5.1.109-1
    NV_LIBCUBLAS_PACKAGE="${NV_LIBCUBLAS_PACKAGE_NAME}=${NV_LIBCUBLAS_VERSION}"

    NV_LIBNCCL_PACKAGE_NAME="libnccl2"
    NV_LIBNCCL_PACKAGE_VERSION=2.9.9-1
    NCCL_VERSION=2.9.9-1
    NV_LIBNCCL_PACKAGE="${NV_LIBNCCL_PACKAGE_NAME}=${NV_LIBNCCL_PACKAGE_VERSION}+cuda11.3"


    NV_CUDNN_VERSION=8.2.0.53

    NV_CUDNN_PACKAGE="libcudnn8=$NV_CUDNN_VERSION-1+cuda11.3"
    NV_CUDNN_PACKAGE_NAME="libcudnn8"


    apt-get update && apt-get install -y --no-install-recommends \
        cuda-libraries-11-3=${NV_CUDA_LIB_VERSION} \
        ${NV_LIBNPP_PACKAGE} \
        cuda-nvtx-11-3=${NV_NVTX_VERSION} \
        libcusparse-11-3=${NV_LIBCUSPARSE_VERSION} \
        ${NV_LIBCUBLAS_PACKAGE} \
        ${NV_LIBNCCL_PACKAGE} 

    apt-get install -y --no-install-recommends \
        ${NV_CUDNN_PACKAGE} \
        && apt-mark hold ${NV_CUDNN_PACKAGE_NAME}


    apt-mark hold ${NV_LIBCUBLAS_PACKAGE_NAME} ${NV_LIBNCCL_PACKAGE_NAME}

    ln -sf cuda-11.3 /usr/local/cuda 

    /bin/rm -rf /var/lib/apt/lists/*
    # libnccl2=2.4.2-1+cuda10.0 
    # cd back otherwise clean layer will fail since it is deleted
    cd $RESOURCES_PATH
    rm -r $RESOURCES_PATH"/cuda-11-3"
else
    echo "CUDA 11.3 is already installed"
fi

# Run
if [ $INSTALL_ONLY = 0 ] ; then
    echo "Use CUDA 11.3 via supporting libraries and frameworks."
    sleep 15
fi