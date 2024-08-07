import std/algorithm
import logging
import os
import sequtils
import streams
import strformat
import strutils
import tables

import yaml, yaml/data, yaml/parser, yaml/hints

let VERSION = "0.1.0"
let version = VERSION
let logger = newConsoleLogger(fmtStr="[$time] - $levelname: ", useStderr=true)

proc parseVersionsYaml(versions_yaml: string): Table[string, Table[string, string]] =
  ## Parse versions.yml which may contain duplicate top level keys
  ## Since there may be duplicate keys YAML load cannot be used due to a 
  ## duplicate table key error resulting in a YamlConstructionError
  ## so manual parsing is required.
  var versionsByProcess = initTable[string, Table[string, string]]()
  var s = newFileStream(versions_yaml)
  defer: s.close()
  var yamlParser = initYamlParser()
  var events = yamlParser.parse(s)
  var context = initConstructionContext(events)

  assert events.next().kind == yamlStartStream
  assert events.next().kind == yamlStartDoc
  assert events.next().kind == yamlStartMap
  var nextEvent = events.next()
  var tmpMap: Table[string, string]
  var currModule: string
  while nextEvent.kind != yamlEndMap:
    if nextEvent.kind == yamlScalar:
      currModule = nextEvent.scalarContent
      versionsByProcess[currModule] = initTable[string, string]()
    elif nextEvent.kind == yamlStartMap:
      nextEvent = events.next()
      tmpMap = versionsByProcess[currModule]
      while nextEvent.kind != yamlEndMap:
        if nextEvent.kind == yamlScalar and events.peek().kind == yamlScalar:
          tmpMap[nextEvent.scalarContent] = events.next().scalarContent
        nextEvent = events.next()
      versionsByProcess[currModule] = tmpMap
    nextEvent = events.next()
  assert events.next().kind == yamlEndDoc
  assert events.next().kind == yamlEndStream
  return versionsByProcess

proc makeHtmlTable(versions: Table[string, Table[string, string]]): string =
  ## Generate a tabular HTML output of all versions for MultiQC.
  var html: seq[string]
  html.add("""
    <style>
    #nf-core-versions tbody:nth-child(even) {
        background-color: #f2f2f2;
    }
    </style>
    <table class="table" style="width:100%" id="nf-core-versions">
        <thead>
            <tr>
                <th> Process Name </th>
                <th> Software </th>
                <th> Version  </th>
            </tr>
        </thead>
        <tbody>
    """.dedent())
  var i: int = 0
  var p: string
  for process in sorted(toSeq(versions.keys())):
    i = 0
    for tool in sorted(toSeq(versions[process].keys())):
      p = if i == 0: process else: ""
      html.add fmt"""
        <tr>
            <td><samp>{p}</samp></td>
            <td><samp>{tool}</samp></td>
            <td><samp>{versions[process][tool]}</samp></td>
        </tr>
        """.dedent()
      i += 1
  html.add "</tbody>"
  html.add "</table>"
  return html.join("\n")

proc main*(
  versions_yaml: string, 
  nextflow_version: string, 
  workflow_name: string, 
  workflow_version: string,
  outdir: string = "."
) =
  ## Convert a Nextflow versions.yml into a MultiQC YAML with HTML content.
  logger.log(lvlInfo, fmt"mqc_versions_table {version}")
  if not fileExists(versions_yaml):
    raise newException(IOError, fmt"Versions YAML file {versions_yaml} not found")
  if not dirExists(outdir):
    createDir(outdir)
    logger.log(lvlInfo, fmt"Output directory '{outdir}' created!")
  else:
    logger.log(lvlInfo, fmt"Output directory '{outdir}' already exists.")

  var versionsByProcess = parseVersionsYaml(versions_yaml)

  logger.log(lvlInfo, fmt"versionsByProcess={versionsByProcess}")
  
  ## Aggregate versions by the module name (derived from fully-qualified process name)
  var versions_by_module = initTable[string, Table[string, string]]()
  for process, process_versions in versionsByProcess.pairs:
    let module = process.split(":")[^1]
    if versions_by_module.hasKey(module):
      if versions_by_module[module] != process_versions:
        raise newException(ValueError, 
          fmt"Software versions are assumed to be the same between all modules. versions_by_module[module]={versions_by_module[module]} DOES NOT EQUAL process_versions={process_versions}!"
        )
    else:
      versions_by_module[module] = process_versions

  versions_by_module["MQC_VERSIONS_TABLE"] = initTable[string, string]()
  versions_by_module["MQC_VERSIONS_TABLE"]["mqc_versions_table"] = version
  versions_by_module["Workflow"] = initTable[string, string]()
  versions_by_module["Workflow"]["Nextflow"] = nextflow_version
  versions_by_module["Workflow"][workflow_name] = workflow_version

  var htmlTable: string
  htmlTable = makeHtmlTable(versions_by_module)

  var versions_mqc = initTable[string, string]()
  versions_mqc["id"] = "software_versions"
  versions_mqc["section_name"] = fmt"{workflow_name} Software Versions"
  versions_mqc["section_href"] = fmt"https://github.com/{workflow_name}"
  versions_mqc["plot_type"] = "html"
  versions_mqc["description"] = "are collected at run time from the software output."
  versions_mqc["data"] = htmlTable

  let software_versions_yml_path = joinPath(outdir, "software_versions.yml")
  var software_versions_yml_out = newFileStream(software_versions_yml_path, fmWrite)
  defer: software_versions_yml_out.close()
  let software_versions_mqc_yml_path = joinPath(outdir, "software_versions_mqc.yml")
  var software_versions_mqc_yml_out = newFileStream(software_versions_mqc_yml_path, fmWrite)
  defer: software_versions_mqc_yml_out.close()
  var dumper = Dumper()
  dumper.setBlockOnlyStyle()
  dumper.dump(versions_by_module, software_versions_yml_out)
  logger.log(lvlInfo, fmt"Wrote '{software_versions_yml_path}'.")
  dumper.dump(versions_mqc, software_versions_mqc_yml_out)
  logger.log(lvlInfo, fmt"Wrote '{software_versions_mqc_yml_path}' for use with MultiQC.")
  logger.log(lvlInfo, "Done!")

when isMainModule:
  import cligen
  clCfg.version = VERSION
  dispatch(main,
    help={
      "versions_yaml": "Path to Nextflow 'versions.yml'",
      "workflow_name": "Nextflow workflow name e.g. $workflow.manifest.name",
      "workflow_version": "Nextflow workflow version, e.g. $workflow.manifest.version",
      "outdir": "Output directory for software_versions.yml and software_versions_mqc.yml",
      "nextflow_version": "Nextflow version"
    }
  )
