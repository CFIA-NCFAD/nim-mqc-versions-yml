# nim-mqc-versions-yml

[![Build](https://github.com/CFIA-NCFAD/nim-mqc-versions-yml/actions/workflows/build.yml/badge.svg)](https://github.com/CFIA-NCFAD/nim-mqc-versions-yml/actions/workflows/build.yml)

This repo contains a [Nim] implementation of the [nf-core/modules dumpsoftwareversions.py](https://github.com/nf-core/modules/blob/master/modules/nf-core/custom/dumpsoftwareversions/templates/dumpsoftwareversions.py) Python script to convert a typical Nextflow workflow `versions.yml` file to a [MultiQC] custom HTML table YAML.

## Usage

Show help with `--help`.

```
$ ./mqc_versions_table --help
Usage:
  main [REQUIRED,optional-params]
Convert a Nextflow versions.yml into a MultiQC YAML with HTML content. Aggregate versions by the module name (derived from
fully-qualified process name)
Options:
  -h, --help                                  print this cligen-erated help
  --help-syntax                               advanced: prepend,plurals,..
  --version                 bool    false     print version
  -v=, --versions_yaml=     string  REQUIRED  Path to Nextflow 'versions.yml'
  -n=, --nextflow_version=  string  REQUIRED  Nextflow version
  -w=, --workflow_name=     string  REQUIRED  Nextflow workflow name e.g. $workflow.manifest.name
  --workflow_version=       string  REQUIRED  Nextflow workflow version, e.g. $workflow.manifest.version
  -o=, --outdir=            string  "."       Output directory for software_versions.yml and software_versions_mqc.yml
```

Typical usage might look like this:

```bash
./mqc_versions_table \
  --versions-yaml path/to/versions.yml \
  --nextflow-version $NEXTFLOW_VERSION \
  --workflow-name $WORKFLOW_NAME \
  --workflow-version $WORKFLOW_VERSION
```

## Installation

You can get the latest statically compiled binary from the [releases](https://github.com/CFIA-NCFAD/nim-mqc-versions-yml/releases) page.

## Why?

For the small portable binary clocking in at around 200KB.

The `dumpsoftwareversions` process in nf-core/modules uses an older version of MultiQC (v1.11) so if you're using newer version of MultiQC (e.g. v1.23) for report generation with Docker/Singularity, you'll likely be downloading a lot just to use the `pyyaml` library required by the `dumpsoftwareversions.py` script. 

It's easy to compile small portable binaries with [Nim] especially when using [Musl](https://musl.libc.org/) for maximum portability, [strip](https://web.mit.edu/gnu/doc/html/binutils_9.html) to strip all symbols and [upx](https://upx.github.io/) for binary compression.


[Nim]: https://nim-lang.org/
[MultiQC]: https://multiqc.info/
