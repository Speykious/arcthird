###
chai = require "chai"
chai.should()
chaiAsPromised = require "chai-as-promised"
chai.use chaiAsPromised

Parser = require "../src/Parser"
{ toPromise, strparse, fail } = require "../src/pcombinators"


describe "toPromise", ->
  failer = toPromise (strparse fail "crash") "nope"
  succer = toPromise (strparse Parser.of "all good") "nope"
  
  try
    await failer
    .then (x) ->
      console.log x
      console.log "throwing error expected to reject"
      throw new Error "Expected to reject :("
    .catch (s) ->
      it "should reject with error when failing", ->
        s.error.should.equal "crash"
        s.index.should.equal 0
    
    await succer
    .then (x) -> x.should.equal "all good"
    .catch (e) ->
      it "should resolve with result when succeeding", ->
        console.log "WTF ->", e
        throw new Error "Expected to resolve, got '#{e}'"
  catch e
    console.log e
###
