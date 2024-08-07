# Package

version       = "0.2.0"
author        = "Peter Kruczkiewicz"
description   = "Nextflow versions.yml to MultiQC HTML table custom content YAML."
license       = "Apache-2.0"
bin           = @["mqc_versions_table"]


# Dependencies

requires "nim >= 2.0.0"
requires "cligen >= 1.7.2"
requires "yaml >= 2.1.1"


# Nimble tasks
from macros import error
from ospaths import splitFile, `/`


proc binOptimize(binFile: string) =
  ## Optimize size of the ``binFile`` binary.
  echo ""
  if findExe("strip") != "":
    echo "Running 'strip -s' .."
    exec "strip -s " & binFile
  if findExe("upx") != "":
    # https://github.com/upx/upx/releases/
    echo "Running 'upx --best' .."
    exec "upx --best " & binFile

task musl, "Builds an optimized static binary using musl":
  let
    nimFile = bin[0] & ".nim"
    (dirName, baseName, _) = splitFile(nimFile)
    binFile = dirName / baseName  # Save the binary in the same dir as the nim file
    nimArgs = "build -d:static " # & nimFile
  # echo "[debug] nimFile = " & nimFile & ", binFile = " & binFile

  # Build binary
  echo "\nRunning 'nim " & nimArgs & "' .."
  exec "nimble " & nimArgs

  # Optimize binary
  binOptimize(binFile)

  echo "\nCreated binary: " & binFile
