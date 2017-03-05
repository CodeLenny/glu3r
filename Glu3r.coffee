Promise = require "bluebird"
fs = Promise.promisifyAll require "fs"
cheerio = require "cheerio"
{SVG2CSG} = require "./SVG2CSG.js"

class NoTransformationError extends Error
  constructor: (@message) ->
    @name = "NoTransformationError"
    Error.captureStackTrace @, NoTransformationError

class Glu3rLayerInfo

  ###
  @property {Number} the index of the layer being outputted.  From 0 to
    ({Glu3rOptions.height} * {Glu3rOptions.resolution}).
  ###
  index: null

  ###
  @property {Number} the `z` offset for this layer.  From 0 to {Glu3rOptions.height}.
  ###
  z: null

class Glu3rOptions

  ###
  @property {String, Promise<String>} The contents of the SVG file to operate on.
  ###
  file: null

  ###
  @property {Function} A function to call on each layer to manipulate the output.  Given `($, layer)`, with `$` being a
    [Cheerio](https://github.com/cheeriojs/cheerio) instance pre-loaded with the SVG, and `layer` being a
    {Glu3rLayerInfo} object.  Returns a `String`, `Cheerio` instance or a Promise resolving to one of the other return
    types.
  ###
  fn: null

  ###
  @property {Number} The height of the object to be rendered, in mm.  Defaults to `10`mm.
  ###
  height: 10

  ###
  @property {Number} the resolution of each layer.  Defaults to `0.001`mm (1 micron)
  ###
  resolution: 0.001

class Glu3r

  ###
  @property {Glu3rOptions} the Glu3r configuration.
  ###
  opts: null

  ###
  Create a new Glu3r object.

  @override new Glu3r(file, opts, fn)
    @param {String} file the path to an SVG file to operate on
    @param {Glu3rOptions} opts **Optional** options to configure Glu3r
    @param {Function} fn **Optional** See {Glu3rOptions#fn}

  @override new Glu3r(opts, fn)
    @param {Glu3rOptions} opts options to configure Glu3r
    @param {Function} fn **Optional** See {Glu3rOptions#fn}

  @override new Glu3r(fn)
    @param {Function} fn **Optional** See {Glu3rOptions#fn}
  ###
  constructor: (file, @opts, fn) ->
    if typeof file is "object"
      [@opts, fn, file] = [file, @opts]
    if typeof @opts is "function" and !fn then @opts = {fn: @opts}
    if typeof file is "string"
      @opts.file = fs.readFileAsync file, "utf8"
    else
      @opts.file = Promise.resolve @opts.file
    @opts.fn ?= fn
    @opts = Object.assign {}, Glu3rOptions::, @opts

  ###
  Create and glu3 layers from the SVG together.
  @return {Promise<CSG>} resolves to a CSG to use with `openjscad`.
  ###
  glue: ->
    layers = (@layer(layer) for layer in [0...@opts.height] by @opts.resolution)
    Promise
      .all layers
      .then (layers) ->
        [out, rest...] = layers
        for layer in rest
          out = out.union layer
        out
      .catch (err) ->
        if err.layerError
          console.error "An error occured while drawing one of the layers."
        else
          console.error "#{typeof err} while composing the layers."
        throw err

  ###
  Create a single layer of output.
  @param {Number} layer the index of the layer to print
  @return {Promise<CSG>} resolves to a CSG to use with `openjscad`.
  ###
  layer: (layer) ->
    svg = null
    @opts
      .file
      .then (file) =>
        svg = file
        unless @opts.fn and typeof @opts.fn is "function"
          throw new NoTransformationError "User did not specify a transformation function."
        return svg
      .then (svg) ->
        cheerio.load svg,
          xmlMode: yes
      .then ($) =>
        @opts.fn $,
          index: layer / @opts.resolution
          z: layer
      .then (out) =>
        switch
          when typeof out is "string" then return out
          when typeof out is "function" and out.html? then return out.html()
          else
            throw new TypeError "Glu3rOptions.fn must return a String or Cheerio object.  Got #{typeof out}"
      .catch NoTransformationError, -> svg
      .then (svg) ->
        SVG2CSG svg
      .then (csg) =>
        csg
          .extrude {offset: [0, 0, @opts.resolution]}
          .translate [0, 0, layer - @opts.resolution]
      .catch (err) ->
        console.error "#{typeof err} on layer #{layer}: #{err.message}"
        err.layerError = true
        throw err

module.exports = Glu3r
