models =
  parse: require "./helpers/parse.model"

chai = require "chai"
expect = chai.expect
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
{ digits, str, char } = require "../src/pgenerators"

sps = require "./sps"

describe "Parser Combinators", ->
  describe "getData", ->
    p = withData coroutine () ->
      sd = yield getData
      return sd
    it "should parse something", ->
      (p "data").should.parse sps.abc
      (p "data").should.parse sps.empty
    it "should get data from the parser", ->
      (p "data").should.haveParseResult sps.abc, "data"
    it "should get data even when PStream is empty", ->
      (p "data").should.haveParseResult sps.empty, "data"

  describe "setData", ->
    parser = coroutine () ->
      yield setData "new data"
      return 42
    it "should parse something", ->
      parser.should.parse sps.abc
      parser.should.parse sps.empty
    it "should set data on the parser", ->
      parser.should.haveParseResult sps.abc, 42
      parser.should.haveParseData sps.abc, "new data"
    it "should set data even when PStream is empty", ->
      parser.should.haveParseResult sps.empty, 42
      parser.should.haveParseData sps.empty, "new data"
  
  describe "mapData", ->
    p = withData coroutine () ->
      yield mapData (d) -> d.map (x) -> x * 2
      return 42
    it "should parse something", ->
      (p [1, 2, 3]).should.parse sps.abc
      (p [1, 2, 3]).should.parse sps.empty
    it "should map data on the parser", ->
      (p [1, 2, 3]).should.haveParseResult sps.abc, 42
      (p [1, 2, 3]).should.haveParseData sps.abc, [2, 4, 6]
    it "should map data even when PStream is empty", ->
      (p [1, 2, 3]).should.haveParseResult sps.empty, 42
      (p [1, 2, 3]).should.haveParseData sps.empty, [2, 4, 6]
  
  describe "withData", ->
    parser = (withData digits) "my data"
    it "should parse something", ->
      parser.should.parse sps.numalphs
      parser.should.not.parse sps.empty
    it "should have data on the parser", ->
      parser.should.haveParseResult sps.numalphs, "123"
      parser.should.haveParseData sps.numalphs, "my data"
    it "should have data even when PStream is empty", ->
      parser.should.haveParseData sps.empty, "my data"
  
  describe "pipe", ->
    parser = pipe [(str "hello"), (char ' '), (str "world")]
    it "should parse like a pipe", ->
      parser.should.parse sps.hello
    it "should fail like a parser", ->
      parser.should.not.parse sps.alphnums
    it "should act like a pipe", ->
      parser.should.haveParseResult sps.hello, "world"
  
  describe "compose", ->
    parser = compose [(str "world"), (char ' '), (str "hello")]
    it "should parse like a composition", ->
      parser.should.parse sps.hello
    it "should fail like a parser", ->
      parser.should.not.parse sps.alphnums
    it "should act like a composition", ->
      parser.should.haveParseResult sps.hello, "world"
  
  describe "tap", ->
    state = undefined
    parser = pipe [(char 'a'), (tap (x) -> state = x)]
    it "should parse something", ->
      parser.should.parse sps.abc
    it "should have been called", ->
      state.should.not.be.undefined
    it "passes check 69 (yeet²)", ->
      state.index.should.equal 1
      (expect state.data).to.be.null
      state.result.should.equal 'a'
      state.isError.should.be.false
      (expect state.error).to.be.null
    state = undefined
    it "should fail here", ->
      parser.should.not.parse sps.xyz
    it "should still be called after fail", ->
      state.should.not.be.undefined
    it "should tap the fail correctly", ->
      state.index.should.equal 0
      (expect state.data).to.be.null
      (expect state.result).to.be.undefined
      state.isError.should.be.true
      state.error.should.equal "ParseError (position 0): Expecting character 'a', got 'x'"
  
  describe "parse", ->
    it "should act like the .parse property", ->
      ((parse char 'a') sps.abc).props.should.equal ((char 'a').parse sps.abc).props
    it "doesn't have anything else interesting", ->
      true.should.not.be.false

