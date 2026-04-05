# Container Setup

This directory contains the Apptainer (formerly Singularity) container
definition for the project's R environment. Using a container ensures
identical package versions across local machines, DCC, and TACC.

## Building the Container

```bash
# On a machine with root/sudo access (not on HPC login nodes):
apptainer build project.sif Apptainer.def

# Or using --fakeroot on systems that support it:
apptainer build --fakeroot project.sif Apptainer.def
```

Build time: ~20-40 minutes depending on the number of R packages.

## Deploying to Clusters

### Duke DCC
```bash
scp project.sif dcc:/opt/apps/containers/community/<your_user>/project.sif
```

Then update `IMG` in `tasks/generic.make`:
```makefile
IMG ?= /opt/apps/containers/community/<your_user>/project.sif
```

### TACC (Lonestar6)
```bash
scp project.sif ls6.tacc.utexas.edu:/work/<project_num>/<user>/project.sif
```

Then update `IMG` in `tasks/generic.make` for the TACC path.

## Testing

```bash
# Check R version and packages
apptainer exec project.sif Rscript -e 'sessionInfo()'

# Run a script inside the container
apptainer exec --bind /path/to/repo:/path/to/repo project.sif \
    Rscript code/my_script.R --arg1 val1

# Interactive R session
apptainer exec project.sif R
```

## Adding Packages

1. Edit `Apptainer.def` — add to the `%post` section.
2. Rebuild the container.
3. Deploy to both clusters.

**Temporary workaround** (if you can't rebuild immediately):
Install to your user library on the cluster:
```r
install.packages("newpackage", lib = "~/R/library")
```
Remove the user-library copy once the container is rebuilt.

## Version Pinning

Some packages may need version pins for older compilers on HPC:
```r
# Example: sf needs pinning on systems with GDAL < 3.1
remotes::install_version("sf", version = "1.0-12")
```

Document any version pins in `Apptainer.def` with a comment explaining why.
