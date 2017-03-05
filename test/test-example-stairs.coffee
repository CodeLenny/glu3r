chai = require "chai"
should = chai.should()

Promise = require "bluebird"
fs = Promise.promisifyAll require "fs"
jscad = require "openjscad"
stljs = Promise.promisifyAll require "@codelenny/stljs"
AdmeshParser = require "admesh-parser"
admesh = Promise.promisify new AdmeshParser()
golden = require "./golden"

Glu3r = require "../Glu3r"

width = 500

svg = """
  <svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="#{width}" height="500">
    <path id="rect" fill="black" d="M 0,0 v 500 h 500 v -500 z"></path>
  </svg>
"""

height = 200
steps = 10
notch = Math.floor width / steps

stairify = ($, layer) ->
  notches = Math.min steps, Math.floor layer.z / (height / steps)
  h = parseInt($("svg").attr("height"), 10) - (notch * notches)
  $("#rect").attr "d", "M 0,0 v 500 h #{h} v -500 z"
  $

describe "Example: Stairs", ->

  stl = "#{__dirname}/out/stairs.stl"
  [model] = []

  before ->
    new Glu3r({file: svg, height: height, resolution: (height / (steps * 2))}, stairify).glue()
      .then (stairs) ->
        fs.writeFileAsync stl, jscad.generateOutput('stlb', stairs).asBuffer()
      .then ->
        Promise.all [
          admesh(stl).then (m) -> model = m
          stljs.imageifyAsync stl, {width: 400, height: 400, dst: "#{__dirname}/out/stairs.png"}
        ]

  it "should be #{height} tall", ->
    z = model.z.max - model.z.min
    z.should.equal height

  it "should match the expected image", ->
    golden.img "stairs.png"
