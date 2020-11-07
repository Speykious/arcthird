models =
  parse: require "./helpers/parse.model"

chai = require "chai"
chai.should()
chai.use models.parse

Parser      = require "../src/Parser"
ParserState = require "../src/ParserState"
{
  getData, setData, mapData, withData
  pipe, compose, tap, parse, strparse
  decide, fail, succeedWith, either
  coroutine, exactly, many, atLeast, atLeast1
  mapTo, errorMapTo
  namedSequenceOf, sequenceOf
  sepBy, sepBy1, choice, between
  everythingUntil, everyCharUntil
  anythingExcept, anyCharExcept
  lookAhead, possibly, skip
  recursiveParser, takeRight, takeLeft
  toPromise, toValue
} = require "../src/pcombinators"

sps = require "./sps"

describe "Parser Combinators", ->
  describe "getData", ->
    p = withData coroutine () ->
      sd = yield getData
      return sd
    it "should get data from the parser", ->
      (p "data").should.haveParseResult sps.abc, "data"
    it "should get data even when PStream is empty", ->
      (p "data").should.haveParseResult sps.empty, "data"

  describe "setData", ->
    parser = coroutine () ->
      yield setData "new data"
      return 42
    it "should set data on the parser", ->
      parser.should.haveParseResult sps.abc, 42
      parser.should.haveParseData sps.abc, "new data"
    it "should set data even when PStream is empty", ->
      parser.should.haveParseResult sps.empty, 42
      parser.should.haveParseData sps.empty, "new data"
