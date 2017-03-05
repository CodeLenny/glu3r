Promise = require "bluebird"
fs = Promise.promisifyAll require "fs-extra"
path = require "path"
{rollup} = require "rollup"
nodeResolve = require "rollup-plugin-node-resolve"
coffee = require "rollup-plugin-coffee-script"
commonjs = require "rollup-plugin-commonjs"
json = require "rollup-plugin-json"
{exec} = require "child-process-promise"


jsCadVersion = require("openjscad/package.json").version
svg2csg = fs
  .writeFileAsync "#{__dirname}/../node_modules/openjscad/src/jscad/version.js", """
      export const version = "#{jsCadVersion}";
    """
  .then ->
    rollup
        entry: require("path").resolve "#{__dirname}/../SVG2CSG.coffee"
        plugins: [
          json()
          coffee()
          nodeResolve
            extensions: [".js", ".json", ".coffee"]
            skip: ["node_modules/openjscad/dist/module.js"]
            jsnext: yes
            main: yes
          commonjs
            extensions: [".js", ".json", ".coffee"]
            namedExports:
                "node_modules/openjscad/src/csg.js": [ "CSG", "CAG" ]
        ]
  .then (bundle) ->
    bundle.write
      format: "cjs"
      dest: path.resolve "#{__dirname}/../SVG2CSG.js"

glu3r = exec "coffee -c #{__dirname}/../Glu3r.coffee"

mkdir = fs
  .removeAsync "#{__dirname}/../node_modules/package.json"
  .then ->
    fs.mkdirsAsync "#{__dirname}/../node_modules/glu3r/"

manifest = mkdir.then ->
  fs.copyAsync "#{__dirname}/../package.json", "#{__dirname}/../node_modules/glu3r/package.json"

fake_module = Promise
  .all [
    svg2csg
    glu3r
    mkdir
  ]
  .then ->
    Promise.all [
      manifest
      fs.copyAsync "#{__dirname}/../Glu3r.js", "#{__dirname}/../node_modules/glu3r/Glu3r.js"
      fs.copyAsync "#{__dirname}/../SVG2CSG.js", "#{__dirname}/../node_modules/glu3r/SVG2CSG.js"
    ]

Promise.all [glu3r, svg2csg, fake_module]
