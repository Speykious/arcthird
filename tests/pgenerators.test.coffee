models =
  parse: require "./helpers/parse.model"

chai = require "chai"
chai.should()
chai.use models.parse

Parser = require "../src/Parser"
{ StringPStream } = require "../src/pstreams"
{
  char, anyChar, peek, str
  regex, digit, digits
  letter, letters
  anyOfString, endOfInput
  whitespace, optionalWhitespace
} = require "../src/pgenerators"

sps =
  a:     new StringPStream "a"
  abc:   new StringPStream "abc"
  xyz:   new StringPStream "xyz"
  empty: new StringPStream ""
  日本語: new StringPStream "日本語"


describe "tautology", ->
  it "should be a tautology", ->
    "tautology".should.equal "tautology"

describe "Parser Generators", ->
  describe "char", ->
    it "should only accept characters", ->
      (-> char "").should.throw TypeError
      (-> char "ab").should.throw TypeError
      (-> char 10).should.throw TypeError
      (-> char ["a"]).should.throw TypeError
      (-> char 'x').should.not.throw()
      (-> char ' ').should.not.throw()
      (-> char '何').should.not.throw()
    it "should parse ASCII characters", ->
      (char 'a').should.parse sps.abc
    it "should parse Unicode characters", ->
      (char '日').should.parse sps.日本語
    it "should not parse at end of input", ->
      parser = char 'a'
      target = sps.empty
      parser.should.not.parse target
      parser.should.haveParseError target,
        "ParseError (position 0): Expecting character 'a', got end of input"
    it "should fail when the character received is not the one expected", ->
      (char 'a').should.not.parse sps.xyz

  describe "str", ->
    