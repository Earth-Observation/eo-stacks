#!/bin/sh

# Stops script execution if a command has an error
set -e

INSTALL_ONLY=0
PYTHON_VERSION=${2:-${PYTHON_VERSION:-"default"}}

# Loop through arguments and process them: https://pretzelhands.com/posts/command-line-flags
for arg in "$@"; do
    case $arg in
        -i|--install) INSTALL_ONLY=1 ; shift ;;
        *) break ;;
    esac
done

if ! hash conda 2>/dev/null; then
    echo "Installing conda. Please wait..."
arch=$(uname -m) 
    if [ "${arch}" = "x86_64" ]; then \
        # Should be simpler, see <https://github.com/mamba-org/mamba/issues/1437>
        arch="64"; \
    fi 
    wget -qO /tmp/micromamba.tar.bz2 \
        "https://micromamba.snakepit.net/api/micromamba/linux-${arch}/latest" 
    tar -xvjf /tmp/micromamba.tar.bz2 --strip-components=1 bin/micromamba 
    rm /tmp/micromamba.tar.bz2 
    PYTHON_SPECIFIER="python=${PYTHON_VERSION}" 
    if [[ "${PYTHON_VERSION}" == "default" ]]; then PYTHON_SPECIFIER="python"; fi 
    if [ "${arch}" == "aarch64" ]; then \
        # Prevent libmamba from sporadically hanging on arm64 under QEMU
        # <https://github.com/mamba-org/mamba/issues/1611>
        # We don't use `micromamba config set` since it instead modifies ~/.condarc.
        echo "extract_threads: 1" >> "${CONDA_DIR}/.condarc"; \
    fi 
    # Install the packages
    ./micromamba install \
        --root-prefix="${CONDA_DIR}" \
        --prefix="${CONDA_DIR}" \
        --yes \
        "${PYTHON_SPECIFIER}" \
        'mamba' \
		'mamba_gator' \
        'notebook' \
        'jupyterhub' \
        'jupyterlab=3.4.7' \
        'conda-build'
        # 'nodejs=16.4.*' 
    rm micromamba 
    # Pin major.minor version of python
    mamba list python | grep '^python ' | tr -s ' ' | cut -d ' ' -f 1,2 >> "${CONDA_DIR}/conda-meta/pinned"
    mamba list jupyterlab | grep '^jupyterlab ' | tr -s ' ' | cut -d ' ' -f 1,2 >> "${CONDA_DIR}/conda-meta/pinned" 
    jupyter notebook --generate-config 
    mamba clean --all -f -y 
    npm cache clean --force 
    jupyter lab clean 
    rm -rf "/home/${NB_USER}/.cache/yarn" 
    fix-permissions "${CONDA_DIR}" 
    fix-permissions "/home/${NB_USER}" 
    # Install Jupyter Notebook, Lab, and Hub
    # Generate a notebook server config
    # Cleanup temporary files
    # Correct permissions
    # Do all this in a single RUN command to avoid duplicating all of the
    # files across image layers when the permissions change  --quiet
    # $CONDA_DIR/bin/conda create -f --yes -n $ENV_NAME \
    mamba install -c conda-forge --name base --quiet --yes  \
        'graphviz' \
        'pydot' \
        'altair' \
        'beautifulsoup4' \
        'bokeh' \
        'bottleneck' \
        'cloudpickle' \
        'conda-forge::blas=*=openblas' \
        'cython' \
        'dask' \
        'dill' \
        'h5py' \
        'ipympl'\
        'ipywidgets' \
        'matplotlib-base' \
        'numba' \
        'numexpr' \
        'pandas' \
        'patsy' \
        'protobuf' \
        'pytables' \
        'scikit-image' \
        'scikit-learn' \
        'scikit-learn-intelex' \
        'scipy' \
        'seaborn' \
        'sqlalchemy' \
        'statsmodels' \
        'sympy' \
        'widgetsnbextension'\
        'xlrd' \
        'cmake' \
        'pdal' \
        'python-pdal' \
        'entwine' \
        'ipyleaflet'  \
        'gdal' \
        'pdal' \
        'pyproj' \
        'richdem' \
        'rasterio' \
        'xarray' \
        'zarr' \
        'rioxarray' \
        'netcdf4' \
        'h5netcdf' \
        'astropy' \
        'pyroSAR' \
        'pygmt' \
        'geopandas' \
        'cartopy' \
        'isce2' \
        'isce3' \
        'dask-geopandas' \
        'eoreader' \
        'fiona' \
        'shapely' \
        'leafmap' \
        'leafmaptools' \
        'jupyterlab-git' \
        'jupyterlab_code_formatter' \
        'bqplot' \
        'pandas-profiling' \
        'panel' \
        'ipyleaflet' \
        'ipympl' \
        'pythreejs' \
        'ipycytoscape' \
        'evidently' \
        'jupytext' \
        'voila' \
        'nikola' \
        'nbdime' \
        'ipyparallel' \
        'nbformat' \
        'fastai::nbdev' \
        'nbclient' \
        'nbqa' \
        'dask-sql' \
        'dask-labextension' \
        'jupyterlab-drawio' \
        'jupyterlab-system-monitor' \
        'jupyterlab-lsp' \
        'jupyter-lsp' \
        'jupyter-lsp-python' \
        'python-lsp-server'
    echo  "$(which python)" 
    echo "############## Install Jupyterlab extensions ########" 
    jupyter nbextension enable --py widgetsnbextension --sys-prefix 
    # jupyter labextension install \
    #     @jupyterlab/mathjax3-extension \
    #     @jupyterlab/geojson-extension \
    #     @jupyterlab/katex-extension \
    #     @jupyterlab/fasta-extension \
    #     @jupyterlab/latex 2>&1 > /tmp/jupyterlab.log || echo "There were failing tests!" 
    # cat /tmp/jupyterlab-debug-*.log 
    pip install --quiet --no-cache-dir jupyterlab-novnc jupyterlab_iframe 
    # jupyter labextension install jupyterlab_iframe 
    # jupyter serverextension enable --py jupyterlab_iframe 
    jupyter lab clean
    jupyter lab build -y --debug-log-path=/tmp/jupyterlab-build.log --log-level=WARN  || echo "There were failing tests!"
    # Cleanup
    jupyter lab clean
    jlpm cache clean
    npm cache clean --force 
    
else
    echo "conda is already installed"
fi

# Run
if [ $INSTALL_ONLY = 0 ] ; then
    echo "Starting conda Terminal..."
    echo "Conda is a Terminal application."
    conda
    sleep 10
fi