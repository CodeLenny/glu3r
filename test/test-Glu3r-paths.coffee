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

manualClose = """
  <svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="50" height="50">
    <path fill="black" d="M 5,5 v 40 h 40 v-40 h-40"></path>
  </svg>
"""

autoClose = """
  <svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="50" height="50">
    <path fill="black" d="M 5,5 v 40 h 40 v-40 z"></path>
  </svg>
"""

hollow = """
  <svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="50" height="50">
    <path fill="black" d="M 20,20 v 10 h 10 v -10 z M 0,50 v -50 h 50 v 50 z"></path>
  </svg>
"""

describe "Glu3ing <path>", ->

  regular =
    "manually closed":
      svg: manualClose
      file: "square-path-manual"
    "automatically closed":
      svg: autoClose
      file: "square-path-auto"

  describe "squares", ->
    for own desc, {svg, file} of regular
      do (desc, svg, file) ->
        describe "(#{desc}, #{file}.stl)", ->

          stl = "#{__dirname}/out/#{file}.stl"
          [cube, model] = []

          before ->
            @timeout 5000
            new Glu3r({file: svg, height: 2, resolution: 0.5})
              .glue()
              .then (c) ->
                cube = c
                fs.writeFileAsync stl, jscad.generateOutput('stlb', cube).asBuffer()
              .then ->
                Promise.all [
                  admesh(stl).then (m) -> model = m
                  stljs.imageifyAsync stl, {width: 400, height: 400, dst: "#{__dirname}/out/#{file}.png"}
                ]

          it "should be square", ->
            x = model.x.max - model.x.min
            y = model.y.max - model.y.min
            x.should.equal y

          it "should be 2mm tall", ->
            z = model.z.max - model.z.min
            z.should.equal 2

          match = if desc is "manually closed" then it.skip else it
          match "should match the expected image", ->
            golden.img "#{file}.png"
