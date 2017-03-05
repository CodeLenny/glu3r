chai = require "chai"
should = chai.should()

Promise = require "bluebird"
fs = Promise.promisifyAll require "fs"
stljs = Promise.promisifyAll require "@codelenny/stljs"
jscad = require "openjscad"
golden = require "./golden"

{units, SVG2CSG} = require "../SVG2CSG.js"

describe "SVG2CSG", ->

  [shape] = []

  before ->
    fs
      .readFileAsync "#{__dirname}/shape.svg", "utf8"
      .then (s) -> shape = s

  it "should produce a CSG object", ->
    SVG2CSG shape
      .then (out) ->
        out.should.be.an.object
        out.should.have.property "sides"

  it "should produce extrudable objects", ->
    @timeout 4000
    SVG2CSG shape
      .then (out) ->
        out.extrude {offset: [0, 0, 10]}
      .then (extruded) ->
        fs.writeFileAsync "#{__dirname}/out/shape-extruded.stl", jscad.generateOutput('stlb', extruded).asBuffer()
      .then ->
        stljs.imageifyAsync "test/out/shape-extruded.stl",
          {width: 400, height: 400, dst: "test/out/shape-extruded.png"}
      .then ->
        golden.img "shape-extruded.png"

  it "should provide unit conversions", ->
    units.should.be.an.object
    units.should.have.property "px2mm"
    units.px2mm.should.be.a.number
    units.px2mm.should.be.within 1, 5
    units.should.have.property "inch2mm"
    units.should.have.property "pt2mm"
    units.should.have.property "pc2mm"
