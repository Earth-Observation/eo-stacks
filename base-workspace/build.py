import os, sys
import subprocess
import argparse
import datetime

parser = argparse.ArgumentParser()
parser.add_argument('--name', help='base name of docker container', default="eo-workspace")
parser.add_argument('--version', help='version tag of docker container', default="latest")
parser.add_argument('--deploy', help='deploy docker container to remote', action='store_true')
parser.add_argument('--flavor', help='flavor (nvidia-gpu) used for docker container', default='base')

REMOTE_IMAGE_PREFIX = "earthobservertion/"

args, unknown = parser.parse_known_args()
if unknown:
    print("Unknown arguments "+str(unknown))

# Wrapper to print out command
def call(command):
    print("Executing: "+command)
    return subprocess.call(command, shell=True)

# calls build scripts in every module with same flags
def build(module="."):
    
    if not os.path.isdir(module):
        print("Could not find directory for " + module)
        sys.exit(1)
    
    build_command = "python build.py"

    if args.version:
        build_command += " --version=" + str(args.version)

    if args.deploy:
        build_command += " --deploy"
 
    if args.flavor:
        build_command += " --flavor=" + str(args.flavor)

    working_dir = os.path.dirname(os.path.realpath(__file__))
    full_command = "cd " + module + " && " + build_command + " && cd " + working_dir
    print("Building " + module + " with: " + full_command)
    failed = call(full_command)
    if failed:
        print("Failed to build module " + module)
        sys.exit(1)

if not args.flavor:
    args.flavor = "base"

args.flavor = str(args.flavor).lower()

if args.flavor == "all":
    args.flavor = "base"
    build()
    args.flavor = "gpu"
    build()
    sys.exit(0)
# nvidia/tensorflow:22.04-tf2-py3
# unknown flavor -> try to build from subdirectory
if args.flavor not in ["base", "gpu"]:
    # assume that flavor has its own directory with build.py
    build(args.flavor + "-flavor")
    sys.exit(0)

service_name = os.path.basename(os.path.dirname(os.path.realpath(__file__)))
if args.name:
    service_name = args.name

# add flavor to service name
if str(args.flavor).lower() != "base":
    service_name += "-" + args.flavor

# docker build
git_rev = "unknown"
try:
    git_rev = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"]).decode('ascii').strip()
except:
    pass

build_date = datetime.datetime.utcnow().isoformat("T") + "Z"
try:
    build_date = subprocess.check_output(['date', '-u', '+%Y-%m-%dT%H:%M:%SZ']).decode('ascii').strip()
except:
    pass

vcs_ref_build_arg = " --build-arg ARG_VCS_REF=" + str(git_rev)
build_date_build_arg = " --build-arg ARG_BUILD_DATE=" + str(build_date)
flavor_build_arg = " --build-arg ARG_WORKSPACE_FLAVOR=" + str(args.flavor)

ROOT_CONTAINER="nvcr.io/nvidia/tensorflow:22.10.1-tf2-py3" if str(args.flavor).lower() == 'gpu' else "ubuntu:focal"
container_build_arg = " --build-arg ROOT_CONTAINER=" + str(ROOT_CONTAINER)
version_build_arg = " --build-arg ARG_WORKSPACE_VERSION=" + str(args.version)

versioned_image = service_name+":"+str(args.version)
latest_image = service_name+":latest"
failed = call("DOCKER_BUILDKIT=1 docker build -t "+ versioned_image + " -t " + latest_image + " " 
            + version_build_arg + " " + flavor_build_arg+ " " + container_build_arg+ " " + vcs_ref_build_arg + " " + build_date_build_arg + " ./")

if failed:
    print("Failed to build container")
    sys.exit(1)

remote_versioned_image = REMOTE_IMAGE_PREFIX + versioned_image
call("docker tag " + versioned_image + " " + remote_versioned_image)

remote_latest_image = REMOTE_IMAGE_PREFIX + latest_image
call("docker tag " + latest_image + " " + remote_latest_image)

if args.deploy:
    call("docker push " + remote_versioned_image)

    if "SNAPSHOT" not in args.version:
    # do not push SNAPSHOT builds as latest version
        call("docker push " + remote_latest_image)

# docker run --rm -it earthobservertion/eo-workspace-base:latest 
# docker run --rm -it --entrypoint /bin/bash earthobservertion/eo-workspace-base:latest 
# python build.py  --deploy --version=0.0.3 |& tee build.v3.17.log

# docker run -it --rm \
#     --user root \
#     -e NB_USER="my-username" \
#     -e GRANT_SUDO=yes \
#     jupyter/base-notebook