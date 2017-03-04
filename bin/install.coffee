Promise = require "bluebird"
fs = Promise.promisifyAll require "fs"
path = require "path"
{rollup} = require "rollup"
nodeResolve = require "rollup-plugin-node-resolve"
coffee = require "rollup-plugin-coffee-script"
commonjs = require "rollup-plugin-commonjs"
json = require "rollup-plugin-json"


jsCadVersion = require("openjscad/package.json").version
fs
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
