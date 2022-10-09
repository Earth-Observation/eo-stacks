#!/bin/bash
#
# Simple script to create run foldre and gibe access to NB_UID (e.g. to install extensions)
XRDP_TLS_KEY_PATH=${XRDP_TLS_KEY_PATH:-/etc/xrdp/key.pem}
XRDP_TLS_CRT_PATH=${XRDP_TLS_CRT_PATH:-/etc/xrdp/cert.pem}
ENABLE_XDUMMY=${ENABLE_XDUMMY:-false}


# If the container started as the root user, then we have permission to refit
# the jovyan user, and ensure file permissions, grant sudo rights, and such
# things before we run the command passed to start.sh as the desired user
# (NB_USER).
#
if [ "$(id -u)" == 0 ] ; then
    # Environment variables:
    # - NB_USER: the desired username and associated home folder
    # - NB_UID: the desired user id
    # - NB_GID: a group id we want our user to belong to
    # - NB_GROUP: a group name we want for the group
    # - NB_UNPRIVILEGED_USER_GROUPS: list of groups to add for NB_USER as "104(input),125(render),124(kvm),107(messagebus)"
    # - GRANT_SUDO: a boolean ("1" or "yes") to grant the user sudo rights
    # - CHOWN_HOME: a boolean ("1" or "yes") to chown the user's home folder
    # - CHOWN_EXTRA: a comma separated list of paths to chown
    # - CHOWN_HOME_OPTS / CHOWN_EXTRA_OPTS: arguments to the chown commands

    # Refit the jovyan user to the desired the user (NB_USER)
    if id jovyan &> /dev/null ; then
        if ! usermod --home "/home/${NB_USER}" --login "${NB_USER}" jovyan 2>&1 | grep "no changes" > /dev/null; then
            _log "Updated the jovyan user:"
            _log "- username: jovyan       -> ${NB_USER}"
            _log "- home dir: /home/jovyan -> /home/${NB_USER}"
        fi
    elif ! id -u "${NB_USER}" &> /dev/null; then
        _log "ERROR: Neither the jovyan user or '${NB_USER}' exists. This could be the result of stopping and starting, the container with a different NB_USER environment variable."
        exit 1
    fi
    # Ensure the desired user (NB_USER) gets its desired user id (NB_UID) and is
    # a member of the desired group (NB_GROUP, NB_GID)
    if [ "${NB_UID}" != "$(id -u "${NB_USER}")" ] || [ "${NB_GID}" != "$(id -g "${NB_USER}")" ]; then
        _log "Update ${NB_USER}'s UID:GID to ${NB_UID}:${NB_GID}"
        # Ensure the desired group's existence
        if [ "${NB_GID}" != "$(id -g "${NB_USER}")" ]; then
            groupadd --force --gid "${NB_GID}" --non-unique "${NB_GROUP:-${NB_USER}}"
        fi
        # Recreate the desired user as we want it
        userdel "${NB_USER}"
        useradd --home "/home/${NB_USER}" --uid "${NB_UID}" --gid "${NB_GID}" --groups 100 --no-log-init "${NB_USER}"
    fi

    # Create additional groups for NB_USER
    _IFS=${IFS}; IFS=,
    for gid in ${NB_UNPRIVILEGED_USER_GROUPS?}; do
        g_id=`echo $gid | awk -F '[()]' '{print $1}'`
        g_name=`echo $gid | awk -F '[()]' '{print $2}'`
        # make sure group name, no longer than 32 char
        g_name="${g_name:0:32}"

        if ! getent group "${g_id:?}" >/dev/null 2>&1; then
            _log "create group with: groupadd --force --gid "${g_id:?}" "${g_name:-"g_${g_id:?}"}" "
            eval "groupadd --force --gid "${g_id:?}" "${g_name:-"g_${g_id:?}"}" "
            _log "Add user to group: usermod -a -G "${g_name:-"g_${g_id:?}"}" ${NB_USER}"
            eval "usermod -a -G "${g_name:-"g_${g_id:?}"}" ${NB_USER}"
        fi
    done
    IFS=$_IFS

    # Move or symlink the jovyan home directory to the desired users home
    # directory if it doesn't already exist, and update the current working
    # directory to the new location if needed.
    if [[ "${NB_USER}" != "jovyan" ]]; then
        if [[ ! -e "/home/${NB_USER}" ]]; then
            _log "Attempting to copy /home/jovyan to /home/${NB_USER}..."
            mkdir "/home/${NB_USER}"
            if cp -a /home/jovyan/. "/home/${NB_USER}/"; then
                _log "Success!"
            else
                _log "Failed to copy data from /home/jovyan to /home/${NB_USER}!"
                _log "Attempting to symlink /home/jovyan to /home/${NB_USER}..."
                if ln -s /home/jovyan "/home/${NB_USER}"; then
                    _log "Success creating symlink!"
                else
                    _log "ERROR: Failed copy data from /home/jovyan to /home/${NB_USER} or to create symlink!"
                    exit 1
                fi
            fi
        fi
        # Ensure the current working directory is updated to the new path
        if [[ "${PWD}/" == "/home/jovyan/"* ]]; then
            new_wd="/home/${NB_USER}/${PWD:13}"
            _log "Changing working directory to ${new_wd}"
            cd "${new_wd}"
        fi
    fi

    # Optionally ensure the desired user get filesystem ownership of it's home
    # folder and/or additional folders
    if [[ "${CHOWN_HOME}" == "1" || "${CHOWN_HOME}" == "yes" ]]; then
        _log "Ensuring /home/${NB_USER} is owned by ${NB_UID}:${NB_GID} ${CHOWN_HOME_OPTS:+(chown options: ${CHOWN_HOME_OPTS})}"
        # shellcheck disable=SC2086
        chown ${CHOWN_HOME_OPTS} "${NB_UID}:${NB_GID}" "/home/${NB_USER}"
    fi
    if [ -n "${CHOWN_EXTRA}" ]; then
        for extra_dir in $(echo "${CHOWN_EXTRA}" | tr ',' ' '); do
            _log "Ensuring ${extra_dir} is owned by ${NB_UID}:${NB_GID} ${CHOWN_EXTRA_OPTS:+(chown options: ${CHOWN_EXTRA_OPTS})}"
            # shellcheck disable=SC2086
            chown ${CHOWN_EXTRA_OPTS} "${NB_UID}:${NB_GID}" "${extra_dir}"
        done
    fi

    # Update potentially outdated environment variables since image build
    export XDG_CACHE_HOME="/home/${NB_USER}/.cache"

    # Prepend ${CONDA_DIR}/bin to sudo secure_path
    sed -r "s#Defaults\s+secure_path\s*=\s*\"?([^\"]+)\"?#Defaults secure_path=\"${CONDA_DIR}/bin:\1\"#" /etc/sudoers | grep secure_path > /etc/sudoers.d/path

    # Optionally grant passwordless sudo rights for the desired user
    if [[ "$GRANT_SUDO" == "1" || "$GRANT_SUDO" == "yes" ]]; then
        _log "Granting ${NB_USER} passwordless sudo rights!"
        echo "${NB_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/added-by-start-script
    fi



# The container didn't start as the root user, so we will have to act as the
# user we started as.
else
    # Warn about misconfiguration of: granting sudo rights
    if [[ "${GRANT_SUDO}" == "1" || "${GRANT_SUDO}" == "yes" ]]; then
        _log "WARNING: container must be started as root to grant sudo permissions!"
    fi

    JOVYAN_UID="$(id -u jovyan 2>/dev/null)"  # The default UID for the jovyan user
    JOVYAN_GID="$(id -g jovyan 2>/dev/null)"  # The default GID for the jovyan user

    # Attempt to ensure the user uid we currently run as has a named entry in
    # the /etc/passwd file, as it avoids software crashing on hard assumptions
    # on such entry. Writing to the /etc/passwd was allowed for the root group
    # from the Dockerfile during build.
    #
    # ref: https://github.com/jupyter/docker-stacks/issues/552
    if ! whoami &> /dev/null; then
        _log "There is no entry in /etc/passwd for our UID=$(id -u). Attempting to fix..."
        if [[ -w /etc/passwd ]]; then
            _log "Renaming old jovyan user to nayvoj ($(id -u jovyan):$(id -g jovyan))"

            # We cannot use "sed --in-place" since sed tries to create a temp file in
            # /etc/ and we may not have write access. Apply sed on our own temp file:
            sed --expression="s/^jovyan:/nayvoj:/" /etc/passwd > /tmp/passwd
            echo "${NB_USER}:x:$(id -u):$(id -g):,,,:/home/jovyan:/bin/bash" >> /tmp/passwd
            cat /tmp/passwd > /etc/passwd
            rm /tmp/passwd

            _log "Added new ${NB_USER} user ($(id -u):$(id -g)). Fixed UID!"

            if [[ "${NB_USER}" != "jovyan" ]]; then
                _log "WARNING: user is ${NB_USER} but home is /home/jovyan. You must run as root to rename the home directory!"
            fi
        else
            _log "WARNING: unable to fix missing /etc/passwd entry because we don't have write permission. Try setting gid=0 with \"--user=$(id -u):0\"."
        fi
    fi

    # Warn about misconfiguration of: desired username, user id, or group id.
    # A misconfiguration occurs when the user modifies the default values of
    # NB_USER, NB_UID, or NB_GID, but we cannot update those values because we
    # are not root.
    if [[ "${NB_USER}" != "jovyan" && "${NB_USER}" != "$(id -un)" ]]; then
        _log "WARNING: container must be started as root to change the desired user's name with NB_USER=\"${NB_USER}\"!"
    fi
    if [[ "${NB_UID}" != "${JOVYAN_UID}" && "${NB_UID}" != "$(id -u)" ]]; then
        _log "WARNING: container must be started as root to change the desired user's id with NB_UID=\"${NB_UID}\"!"
    fi
    if [[ "${NB_GID}" != "${JOVYAN_GID}" && "${NB_GID}" != "$(id -g)" ]]; then
        _log "WARNING: container must be started as root to change the desired user's group id with NB_GID=\"${NB_GID}\"!"
    fi

    # Warn if the user isn't able to write files to ${HOME}
    if [[ ! -w /home/jovyan ]]; then
        _log "WARNING: no write access to /home/jovyan. Try starting the container with group 'users' (100), e.g. using \"--group-add=users\"."
    fi

fi


# Create /run/dbus/ directory if it does not exist
if [ ! -d /run/dbus/ ]; then
	sudo mkdir -p /run/dbus/
	sudo chmod 755 /run/dbus/
	sudo chown messagebus: /run/dbus/
fi

# Create /run/sshd/ directory if it does not exist
if [ ! -d /run/sshd/ ]; then
	sudo mkdir -p /run/sshd/
	sudo chmod 755 /run/sshd/
fi

# Create /run/udev/ directory if it does not exist
if [ ! -d /run/udev/ ]; then
	sudo mkdir -p /run/udev/
	sudo chmod 755 /run/udev/
fi

# Create /run/user/${NB_UID}/ directory if it does not exist
if [ ! -d /run/user/"${NB_UID:?}"/ ]; then
    sudo mkdir -p /run/user/"${NB_UID:?}"/
    sudo chmod 700 /run/user/"${NB_UID:?}"/
    sudo chown "${NB_USER:?}:" /run/user/"${NB_UID:?}"/
fi

# Create /var/log/supervisor directory if it does not exist
if [ ! -d /var/log/supervisor ]; then
    sudo mkdir -p /var/log/supervisor
    sudo chmod 700 /var/log/supervisor
    sudo chown "${NB_USER:?}:" /var/log/supervisor
fi

# Create /var/log/supervisor directory if it does not exist
if [ ! -d /var/log/nginx ]; then
    sudo mkdir -p /var/log/supervisor
    sudo chmod 700 /var/log/supervisor
    sudo chown "${NB_USER:?}:" /var/log/supervisor
fi

# Enable xdummy service if ENABLE_XDUMMY is true
if [ "${ENABLE_XDUMMY:?}" = 'true' ]; then
	sudo ln -s /etc/sv/xdummy /etc/service/
fi

# Define VGL_DISPLAY variable if it is not set
if [ -z "${VGL_DISPLAY-}" ]; then
	# Use the dummy X server if it is enabled
	if [ "${ENABLE_XDUMMY:?}" = 'true' ]; then
		export VGL_DISPLAY=:0.0
	# Otherwise try to use the EGL backend
	else
		for card in /dev/dri/card*; do
			if /opt/VirtualGL/bin/eglinfo -B "${card:?}" 2>/dev/null; then
				export VGL_DISPLAY="${card:?}"
				break
			fi
		done
	fi
fi

# Generate SSH keys if they do not exist
if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
	sudo ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N '' >/dev/null
fi
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
	sudo ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N '' >/dev/null
fi

# Generate RDP certificate if it does not exist
if [ ! -f "${XRDP_TLS_KEY_PATH:?}" ] || [ ! -f "${XRDP_TLS_CRT_PATH:?}" ]; then
	FQDN=$(hostname --fqdn)

	(umask 077 \
		&& sudo openssl ecparam -genkey -name prime256v1 > "${XRDP_TLS_KEY_PATH:?}" \
	) >/dev/null

	(umask 022 \
		&& sudo openssl req -x509 -sha256 -days 3650 -subj "/CN=${FQDN:?}" -addext "subjectAltName=DNS:${FQDN:?}" -key "${XRDP_TLS_KEY_PATH:?}" > "${XRDP_TLS_CRT_PATH:?}" \
	) >/dev/null
fi

# Print RDP certificate fingerprint
openssl x509 -in "${XRDP_TLS_CRT_PATH:?}" -noout -fingerprint -sha1
openssl x509 -in "${XRDP_TLS_CRT_PATH:?}" -noout -fingerprint -sha256

# Dump environment variables
env | grep -Ev '^(PWD|OLDPWD|HOME|USER|SHELL|TERM|([^=]*(PASSWORD|SECRET)[^=]*))=' | sort > /etc/environment


# Branding
# Jupyter Lab
cp -f ${RESOURCES_PATH}/branding/favicon.ico ${CONDA_DIR}/lib/python3*/site-packages/jupyter_server/static/favicons/favicon.ico
cp -f ${RESOURCES_PATH}/branding/favicon.ico ${CONDA_DIR}/lib/python3*/site-packages/jupyter_server/static/favicon.ico
cp -f ${RESOURCES_PATH}/branding/favicon.ico ${CONDA_DIR}/lib/python3*/site-packages/jupyter_server/static/logo/logo.png
# Jupyter Notebook
cp -f ${RESOURCES_PATH}/branding/favicon.ico ${CONDA_DIR}/lib/python3*/site-packages//notebook/static/base/images/favicon.ico
cp -f ${RESOURCES_PATH}/branding/favicon.ico ${CONDA_DIR}/lib/python3*/site-packages/notebook/static/favicon.ico
cp -f ${RESOURCES_PATH}/branding/favicon.ico ${CONDA_DIR}/lib/python3*/site-packages/notebook/static/base/images/logo.png  

# Fielbrowser Branding
mkdir -p ${RESOURCES_PATH}"/filebrowser/img/icons/" && \
cp -f ${RESOURCES_PATH}/branding/favicon_io/favicon.ico ${RESOURCES_PATH}"/filebrowser/img/icons/favicon.ico" && \
cp -f ${RESOURCES_PATH}/branding/favicon_io/favicon-32x32.png ${RESOURCES_PATH}"/filebrowser/img/icons/favicon-32x32.png" && \
cp -f ${RESOURCES_PATH}/branding/favicon_io/favicon-16x16.png ${RESOURCES_PATH}"/filebrowser/img/icons/favicon-16x16.png" && \
cp -f ${RESOURCES_PATH}/branding/eo-workspace-logo.svg ${RESOURCES_PATH}"/filebrowser/img/logo.svg"      

mkdir -p /tmp/supervisor
# fix-permissions /etc/jupyter/

