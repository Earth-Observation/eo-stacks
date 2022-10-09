# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# Ubuntu 20.04 (focal)
# https://hub.docker.com/_/ubuntu/?tab=tags&name=focal
ARG ROOT_CONTAINER=ubuntu:focal


ARG RESTY_VERSION="1.21.4.1-3"

FROM openresty/openresty:${RESTY_VERSION}-focal AS copy-resty

FROM ${ROOT_CONTAINER} AS base

ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"
ARG NB_UNPRIVILEGED_GROUPS=""

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update --yes && \
    # - apt-get upgrade is run to patch known vulnerabilities in apt-get packages as
    #   the ubuntu base image is rebuilt too seldom sometimes (less than once a month)
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \
    # - bzip2 is necessary to extract the micromamba executable.
    bzip2 \
    ca-certificates \
    fonts-liberation \
    locales \
    # - pandoc is used to convert notebooks to html files
    #   it's not present in arm64 ubuntu image, so we install it here
    pandoc \
    # - run-one - a wrapper script that runs no more
    #   than one unique  instance  of  some  command with a unique set of arguments,
    #   we use `run-one-constantly` to support `RESTARTABLE` option
    run-one \
    sudo \
    # - tini is installed as a helpful container entrypoint that reaps zombie
    #   processes and such of the actual executable we want to start, see
    #   https://github.com/krallin/tini#why-tini for details.
    tini \
    wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER="${NB_USER}" \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    NB_UNPRIVILEGED_GROUPS=${NB_UNPRIVILEGED_GROUPS} \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH="${CONDA_DIR}/bin:${PATH}" \
    HOME="/home/${NB_USER}"

# Copy a script that we will use to correct permissions after running certain commands
COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

# Copy a script that we will use to clean layer after running apt update commands
COPY resources/scripts/bin/clean-layer /usr/local/bin/clean-layer
RUN chmod a+rx /usr/local/bin/clean-layer

# Enable prompt color in the skeleton .bashrc before creating the default NB_USER
# hadolint ignore=SC2016
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
   # Add call to conda init script see https://stackoverflow.com/a/58081608/4413446
   echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc

# Create NB_USER with name jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd -l -m -s /bin/bash -N -u "${NB_UID}" "${NB_USER}" && \
    mkdir -p "${CONDA_DIR}" && \
    chown "${NB_USER}:${NB_GID}" "${CONDA_DIR}" && \
    chmod g+w /etc/passwd && \
	echo "${NB_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/added-by-start-script && \
    fix-permissions "${HOME}" && \
    fix-permissions "${CONDA_DIR}"

USER ${NB_UID}

# Pin python version here, or set it to "default"
ARG PYTHON_VERSION=3.8

# Setup work directory for backward-compatibility
RUN mkdir "/home/${NB_USER}/work" && \
    fix-permissions "/home/${NB_USER}"

# Download and install Micromamba, and initialize Conda prefix.
#   <https://github.com/mamba-org/mamba#micromamba>
#   Similar projects using Micromamba:
#     - Micromamba-Docker: <https://github.com/mamba-org/micromamba-docker>
#     - repo2docker: <https://github.com/jupyterhub/repo2docker>
# Install Python, Mamba, Jupyter Notebook, Lab, and Hub
# Generate a notebook server config
# Cleanup temporary files and remove Micromamba
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
COPY --chown="${NB_UID}:${NB_GID}" initial-condarc "${CONDA_DIR}/.condarc"
WORKDIR /tmp
RUN set -x && \
    arch=$(uname -m) && \
    if [ "${arch}" = "x86_64" ]; then \
        # Should be simpler, see <https://github.com/mamba-org/mamba/issues/1437>
        arch="64"; \
    fi && \
    wget -qO /tmp/micromamba.tar.bz2 \
        "https://micromamba.snakepit.net/api/micromamba/linux-${arch}/latest" && \
    tar -xvjf /tmp/micromamba.tar.bz2 --strip-components=1 bin/micromamba && \
    rm /tmp/micromamba.tar.bz2 && \
    PYTHON_SPECIFIER="python=${PYTHON_VERSION}" && \
    if [[ "${PYTHON_VERSION}" == "default" ]]; then PYTHON_SPECIFIER="python"; fi && \
    if [ "${arch}" == "aarch64" ]; then \
        # Prevent libmamba from sporadically hanging on arm64 under QEMU
        # <https://github.com/mamba-org/mamba/issues/1611>
        # We don't use `micromamba config set` since it instead modifies ~/.condarc.
        echo "extract_threads: 1" >> "${CONDA_DIR}/.condarc"; \
    fi && \
    # Install the packages
    ./micromamba install \
        --root-prefix="${CONDA_DIR}" \
        --prefix="${CONDA_DIR}" \
        --yes \
        "${PYTHON_SPECIFIER}" \
        'mamba' \
        'notebook' \
        'jupyterhub' \
        'jupyterlab' && \
    rm micromamba && \
    # Pin major.minor version of python
    mamba list python | grep '^python ' | tr -s ' ' | cut -d ' ' -f 1,2 >> "${CONDA_DIR}/conda-meta/pinned" && \
    jupyter notebook --generate-config && \
    mamba clean --all -f -y && \
    npm cache clean --force && \
    jupyter lab clean && \
    rm -rf "/home/${NB_USER}/.cache/yarn" && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

USER root

# Technical Environment Variables
ENV \
    # XDG_CACHE_HOME="${HOME}/.cache/" \
    # XDG_RUNTIME_DIR="/tmp" \
    # DISPLAY=":1" \
    # TERM="xterm" \
    TERM="xterm-256color" \
    DEBIAN_FRONTEND="noninteractive" \
    RESOURCES_PATH="/opt/resources" \
    SSL_RESOURCES_PATH="/opt/resources/ssl" \
    WORKSPACE_HOME="/workspace"

RUN \
	mkdir -p "${RESOURCES_PATH}" && \
    chown "${NB_USER}:${NB_GID}" "${RESOURCES_PATH}" && \
    fix-permissions "${RESOURCES_PATH}"


ADD --chown=${NB_UID}:${NB_GID} ./resources/tools/ ${RESOURCES_PATH}/tools/

# Install pipx
ENV PIPX_HOME=/opt/conda/envs/pipx/ \
    PIPX_BIN_DIR=/opt/conda/envs/pipx/bin

ENV PATH=${PATH}:${PIPX_BIN_DIR}

# prepare ssh for inter-container communication for remote python kernel
## Glances webtool is installed in python via pipx
RUN \
    apt-get update  \
    && apt-get install -y --no-install-recommends \
        openssh-client \
        openssh-server \
        rsyslog \
        rsync \
        zsh \
        cron \
        # SSLH for SSH + HTTP(s) Multiplexing
        sslh \
        # SSH Tooling
        autossh \
        mussh \
    && apt-get install --yes --no-install-recommends \
        # Common useful utilities
        git \
        nano-tiny \
        tzdata \
        unzip \
        vim-tiny \
        # Inkscape is installed to be able to convert SVG files
        inkscape \
        # git-over-ssh
        openssh-client \
        # less is needed to run help in R
        # see: https://github.com/jupyter/docker-stacks/issues/1588
        less \
        # nbconvert dependencies
        # https://nbconvert.readthedocs.io/en/latest/install.html#installing-tex
        texlive-xetex \
        texlive-fonts-recommended \
        texlive-plain-generic \
        build-essential \
        # for latex labels
        cm-super \
        dvipng \
        # for matplotlib anim
        ffmpeg \
    # Create alternative for nano -> nano-tiny
    && update-alternatives --install /usr/bin/nano nano /bin/nano-tiny 10 \
    && chmod go-w ${HOME} \
    && mkdir -p ${HOME}/.ssh/ \
    # create empty config file if not exists
    && touch ${HOME}/.ssh/config  \
	&& printenv >> ${HOME}/.ssh/environment \
    && chown -R "${NB_USER}:${NB_GID}" ${HOME}/.ssh \
    && chmod 700 ${HOME}/.ssh \
    && chmod -R a+rwx /usr/local/bin/ \
	# Cleanup
    && clean-layer

RUN \
    chmod a+rx -R ${RESOURCES_PATH}/tools/ \
	# ls -la ${RESOURCES_PATH}/tools/ \
    && bash ${RESOURCES_PATH}/tools/py-utils.sh \
	# Cleanup
    && clean-layer

ADD --chown=${NB_UID}:${NB_GID} ./resources/ ${RESOURCES_PATH}/
ADD --chown=${NB_UID}:${NB_GID} ./resources/etc /etc/


# Install nginx and Openresty to be a reverse proxy
########### Openresty Install
# ARG RESTY_VERSION=1.21.4.1-3
# ARG RESTY_CONTAINER=openresty/openresty:${RESTY_VERSION}-focal

ENV RESTY_VERSION=${RESTY_VERSION} \
    RESTY_PREFIX=/usr/local/openresty  \
    NGINX_PREFIX=/usr/local/openresty/nginx

COPY --from=copy-resty ${RESTY_PREFIX} ${RESTY_PREFIX}

# Add additional binaries into PATH for convenience
ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin

# Add LuaRocks paths
# If OpenResty changes, these may need updating:
#    /usr/local/openresty/bin/resty -e 'print(package.path)'
#    /usr/local/openresty/bin/resty -e 'print(package.cpath)'
ENV LUA_PATH="/usr/local/openresty/site/lualib/?.ljbc;/usr/local/openresty/site/lualib/?/init.ljbc;/usr/local/openresty/lualib/?.ljbc;/usr/local/openresty/lualib/?/init.ljbc;/usr/local/openresty/site/lualib/?.lua;/usr/local/openresty/site/lualib/?/init.lua;/usr/local/openresty/lualib/?.lua;/usr/local/openresty/lualib/?/init.lua;./?.lua;/usr/local/openresty/luajit/share/luajit-2.1.0-beta3/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;/usr/local/openresty/luajit/share/lua/5.1/?.lua;/usr/local/openresty/luajit/share/lua/5.1/?/init.lua"

ENV LUA_CPATH="/usr/local/openresty/site/lualib/?.so;/usr/local/openresty/lualib/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so;/usr/local/openresty/luajit/lib/lua/5.1/?.so"

# Install system packages
RUN \
	apt-get update \
	&& apt-get install -y --no-install-recommends \
		adwaita-icon-theme-full \
		gnupg \
		gnupg2 \
		# lsb-release \
		adwaita-qt \
		audacity \
		bash \
		bash-completion \
		binutils \
		clinfo \
		dbus \
		dbus-x11 \
		desktop-file-utils \
		dialog \
		engrampa \
		exo-utils \
		file \
		# firefox \
		fonts-dejavu \
		fonts-liberation \
		fonts-noto \
		fonts-noto-color-emoji \
		fonts-ubuntu \
		fuse3 \
		git \
		gnome-keyring \
		gtk2-engines-pixbuf \
		htop \
		indicator-application \
		indicator-messages \
		iproute2 \
		iputils-ping \
		libavcodec-extra \
		libcanberra-gtk-module \
		libcanberra-gtk3-module \
		libgtk-3-bin \
		librsvg2-common \
		lshw \
		lsof \
		lsscsi \
		menu \
		menu-xdg \
		# menulibre \
		mesa-utils \
		mesa-utils-extra \
		mime-support \
		mousepad \
		# mugshot \
		nano \
		net-tools \
		netcat-openbsd \
		parole \
		pavucontrol \
		pciutils \
		procps \
		psmisc \
		pulseaudio-utils \
		ristretto \
		strace \
		sudo \
		thunar-archive-plugin \
		tumbler \
		unzip \
		usbutils \
		vulkan-tools \
		wget \
		x11-utils \
		x11-xkb-utils \
		xauth \
		xdg-user-dirs \
		xdg-utils \
		xfce4 \
		xfce4-indicator-plugin \
		xfce4-notifyd \
		xfce4-pulseaudio-plugin \
		xfce4-screenshooter \
		xfce4-statusnotifier-plugin \
		xfce4-taskmanager \
		xfce4-terminal \
		xfce4-whiskermenu-plugin \
		xfonts-base \
		xfpanel-switch \
		xinput \
		xterm \
		xserver-xorg-core \
		xserver-xorg-input-evdev \
		xserver-xorg-input-joystick \
		xserver-xorg-input-libinput \
		xserver-xorg-video-dummy \
		xserver-xorg-video-fbdev \
		xserver-xorg-video-vesa \
		xubuntu-default-settings \
		xutils \
		xz-utils \
		zenity \
		zip \
	# Cleanup
    && clean-layer

RUN \
	touch /var/run/crond.pid \
	&& chmod gu+rw /var/run \
	&& chmod gu+s /usr/sbin/cron

USER ${NB_UID}
RUN \
	mamba install \
		--yes \
		python-crontab \ 
		# Cleanup
    && clean-layer

# RUN \
# 	&& mkdir -p 
	
EXPOSE 8080

# Configure container startup
ENTRYPOINT ["tini", "-g", "--"]
CMD ["start-notebook.sh"]

# Copy local files as late as possible to avoid cache busting
COPY start.sh start-notebook.sh start-singleuser.sh /usr/local/bin/
# Currently need to have both jupyter_notebook_config and jupyter_server_config to support classic and lab
COPY jupyter_server_config.py /etc/jupyter/

# Fix permissions on /etc/jupyter as root
USER root

# Legacy for Jupyter Notebook Server, see: [#1205](https://github.com/jupyter/docker-stacks/issues/1205)
RUN sed -re "s/c.ServerApp/c.NotebookApp/g" \
    /etc/jupyter/jupyter_server_config.py > /etc/jupyter/jupyter_notebook_config.py && \
    fix-permissions /etc/jupyter/ \
	&& fix-permissions /usr/local/bin/


# Set default values for environment variables
ENV CONFIG_BACKUP_ENABLED="true" \
    SHUTDOWN_INACTIVE_KERNELS="false" \
    SHARED_LINKS_ENABLED="true" \
    AUTHENTICATE_VIA_JUPYTER="false" \
    DATA_ENVIRONMENT=$WORKSPACE_HOME"/environment" \
    WORKSPACE_BASE_URL="/" \
    INCLUDE_TUTORIALS="true" \
    # Main port used for sshl proxy -> can be changed
    WORKSPACE_PORT="8080" \
	# Jupyter notebook port
	NOTEBOOKAPP_PORT="8090" \
    # Set zsh as default shell (e.g. in jupyter)
    SHELL="/usr/bin/zsh" \
    NB_UNPRIVILEGED_USER_GROUPS= \
    # Fix dark blue color for ls command (unreadable):
    # https://askubuntu.com/questions/466198/how-do-i-change-the-color-for-directories-with-ls-in-the-console
    # USE default LS_COLORS - Dont set LS COLORS - overwritten in zshrc
    # LS_COLORS="" \
    # set number of threads various programs should use, if not-set, it tries to use all
    # this can be problematic since docker restricts CPUs by stil showing all
    MAX_NUM_THREADS="auto"

# HEALTHCHECK documentation: https://docs.docker.com/engine/reference/builder/#healthcheck
# This healtcheck works well for `lab`, `notebook`, `nbclassic`, `server` and `retro` jupyter commands
# https://github.com/jupyter/docker-stacks/issues/915#issuecomment-1068528799
HEALTHCHECK  --interval=15s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -O- --no-verbose --tries=1 --no-check-certificate \
    http${GEN_CERT:+s}://localhost:${NOTEBOOKAPP_PORT}${JUPYTERHUB_SERVICE_PREFIX:-/}api || exit 1


# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

WORKDIR "${HOME}"

VOLUME ["${WORKSPACE_HOME}"]
WORKDIR "${WORKSPACE_HOME}"


