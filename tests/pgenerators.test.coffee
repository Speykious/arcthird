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
  hello: new StringPStream "hello world"
  empty: new StringPStream ""
  日本語: new StringPStream "日本語"
  テスト: new StringPStream "それはテストです。"


describe "tautology", ->
  it "should be a tautology", ->
    "tautology".should.equal "tautology"

describe "Parser Generators", ->
  describe "char", ->
    it "should only accept characters", ->
      (-> char "").should.throw TypeError
      (-> char "ab").should.throw TypeError
      (-> char 10).should.throw TypeError
      (-> char true).should.throw TypeError
      (-> char ["a"]).should.throw TypeError
      (-> char 'x').should.not.throw()
      (-> char ' ').should.not.throw()
      (-> char '何').should.not.throw()
    it "should parse ASCII characters", ->
      (char 'a').should.parse sps.abc
      (char 'a').should.haveParseResult sps.abc, 'a'
    it "should parse Unicode characters", ->
      (char '日').should.parse sps.日本語
      (char '日').should.haveParseResult sps.日本語, '日'
    it "should not parse at end of input", ->
      parser = char 'a'
      parser.should.not.parse sps.empty
      parser.should.haveParseError sps.empty,
        "ParseError (position 0): Expecting character 'a', got end of input"
    it "should not parse an unexpected character", ->
      (char 'a').should.not.parse sps.xyz
      (char '本').should.not.parse sps.日本語

  describe "anyChar", ->
    it "should parse ASCII characters", ->
      anyChar.should.parse sps.abc
      anyChar.should.haveParseResult sps.abc, 'a'
    it "should parse Unicode characters", ->
      anyChar.should.parse sps.日本語
      anyChar.should.haveParseResult sps.日本語, '日'
    it "should not parse at end of input", ->
      anyChar.should.not.parse sps.empty
      anyChar.should.haveParseError sps.empty,
        "ParseError (position 0): Expecting any character, got end of input"
  
  describe "peek", ->
    it "should peek non-empty strings", ->
      for stream in [sps.a, sps.abc, sps.xyz, sps.日本語]
        peek.should.parse stream
        peek.should.haveParseResult stream, stream.elementAt 0
    it "should not peek at end of input", ->
      peek.should.not.parse sps.empty
      peek.should.haveParseError sps.empty,
        "ParseError (position 0): Unexpected end of input"
    it "should not change the index", ->
      for stream in [sps.a, sps.abc, sps.xyz, sps.日本語]
        peek.should.haveParserState stream, ({ index }) -> index is 0
  
  describe "str", ->
    it "should only accept non-empty strings", ->
      (-> str "").should.throw TypeError
      (-> str 10).should.throw TypeError
      (-> str true).should.throw TypeError
      (-> str ["a"]).should.throw TypeError
      (-> str "x").should.not.throw()
      (-> str " \n").should.not.throw()
      (-> str "ab").should.not.throw()
      (-> str "何").should.not.throw()
      (-> str "テストです").should.not.throw()
    it "should parse ASCII strings", ->
      (str "hello").should.parse sps.hello
      (str "hello").should.haveParseResult sps.hello, "hello"
    it "should parse Unicode strings", ->
      (str "それ").should.parse sps.テスト
      (str "それ").should.haveParseResult sps.テスト, "それ"
    it "should not parse at end of input", ->
      parser = str "anything here"
      parser.should.not.parse sps.empty
      parser.should.haveParseError sps.empty,
        "ParseError (position 0): Expecting string 'anything here', got end of input"
    it "should not parse an unexpected string", ->
      (str "hello").should.not.parse sps.abc
      (str "日本語").should.not.parse sps.テスト
      