import mqc_versions_table

import std/os
import std/tempfiles

import strformat
import streams
import tables
import unittest

import yaml

var tempdir: string

suite "CLI test":
  setup:
    tempdir = createTempDir("mqc_versions_table-", "-outdir")
    echo "Setup: Created temp directory '{tempdir}'"

  teardown:
    echo fmt"Tear down: removing temp directory '{tempdir}'"
    if dirExists(tempdir):
      removeDir(tempdir)

  test "main":
    let outdir = joinPath(tempdir, "outdir")
    main(
      versions_yaml="tests/versions.yml", 
      nextflow_version="2024.4.4", 
      workflow_name="CFIA-NCFAD/nf-flu",
      workflow_version="1.2.3",
      outdir=outdir
    )
    let mqc_table_out = joinPath(outdir, "software_versions_mqc.yml")
    check(fileExists(mqc_table_out))

    var mqc_table: Table[string, string]
    var mqc_table_stream = newFileStream(mqc_table_out)
    defer: mqc_table_stream.close()
    load(mqc_table_stream, mqc_table)

    let exp_mqc_path = "tests/expected-software_versions_mqc.yml"
    var exp_mqc_table: Table[string, string]
    var exp_mqc_stream = newFileStream(exp_mqc_path)
    defer: exp_mqc_stream.close()
    load(exp_mqc_stream, exp_mqc_table)
    check(mqc_table == exp_mqc_table)
