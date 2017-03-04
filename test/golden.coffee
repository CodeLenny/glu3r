Promise = require "bluebird"
fs = Promise.promisifyAll require "fs"
imageDiff = Promise.promisifyAll require "image-diff"

chai = require "chai"
should = chai.should()

###
Compares files in `out` to files in `golden`.
###
golden =

  ###
  Compare a generic file.
  ###
  file: (file) ->
    Promise
      .all [
        fs.readFileAsync "#{__dirname}/out/#{file}"
        fs.readFileAsync "#{__dirname}/golden/#{file}"
      ]
      .then ([out, expected]) ->
        out.should.equal expected, "generated #{file} doesn't match golden"

  ###
  Compare an image visually
  @param {String} file the filename to compare
  @param {Number} tolerance the percentage of visual difference allowed, out of `1`.  Defaults to 0.
  ###
  img: (file, tolerance=0) ->
    imageDiff
      .getFullResultAsync
        actualImage: "#{__dirname}/out/#{file}"
        expectedImage: "#{__dirname}/golden/#{file}"
        diffImage: "#{__dirname}/out/DIFF_#{file}"
      .then (res) ->
        allow = Math.round tolerance * 100
        actual = Math.round res.percentage * 100
        res.percentage.should.be.at.most tolerance,
          "generated #{file} doesn't match golden (#{allow}% difference allowed, was #{actual}% different)"

module.exports = golden
