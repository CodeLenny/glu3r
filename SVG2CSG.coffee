jscad = require "openjscad"

import {parseSVG} from "openjscad/src/io/parsers/parseSVG"

###*
Converts SVG source files into CSG objects for use in openjscad.
@param {String} svg an SVG file to convert into a CSG
@param {Object} opts options to configure the conversion.
@option opts {String} path **Optional** The filename of the SVG
@option opts {Object} params **Optional** Parameters to pass to `jscad.compile`.
###
SVG2CSG = (svg, opts={}) ->
  opts.params ?= {}
  jscad
    .compile parseSVG(svg, opts.path), opts.params
    .then (res) -> res[0]

module.exports = {parseSVG, SVG2CSG}
