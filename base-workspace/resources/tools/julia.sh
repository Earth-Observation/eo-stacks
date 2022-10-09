




    julia_arch=$(uname -m)
    julia_short_arch="${julia_arch}"
    if [ "${julia_short_arch}" == "x86_64" ]; then \
      julia_short_arch="x64"; \
    fi; \
    julia_installer="julia-${JULIA_VERSION}-linux-${julia_arch}.tar.gz"
    julia_major_minor=$(echo "${JULIA_VERSION}" | cut -d. -f 1,2)
    mkdir "/opt/julia-${JULIA_VERSION}"
    wget -q "https://julialang-s3.julialang.org/bin/linux/${julia_short_arch}/${julia_major_minor}/${julia_installer}"
    tar xzf "${julia_installer}" -C "/opt/julia-${JULIA_VERSION}" --strip-components=1
    rm "${julia_installer}"
    ln -fs /opt/julia-*/bin/julia /usr/local/bin/julia


    mkdir /etc/julia
    echo "push!(Libdl.DL_LOAD_PATH, \"${CONDA_DIR}/lib\")" >> /etc/julia/juliarc.jl


    ulia -e 'import Pkg; Pkg.update()'
    julia -e 'import Pkg; Pkg.add("HDF5")'
    julia -e 'using Pkg; pkg"add IJulia"; pkg"precompile"'
    # move kernelspec out of home \
    mv "${HOME}/.local/share/jupyter/kernels/julia"* "${CONDA_DIR}/share/jupyter/kernels/"
    chmod -R go+rx "${CONDA_DIR}/share/jupyter"
    rm -rf "${HOME}/.local"