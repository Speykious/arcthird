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



describe "tautology", ->
  it "should be a tautology", ->
    "tautology".should.equal "tautology"

describe "parser generator: char", ->
  it "should parse ASCII characters", ->
    (char 'a').should.parse new StringPStream "abc"
  it "should parse Unicode characters", ->
    (char '日').should.parse new StringPStream "日本語"
  it "should not parse at end of input", ->
    parser = char 'a'
    target = new StringPStream ""
    parser.should.not.parse target
    parser.should.haveParseError target,
      "ParseError (position 0): Expecting character 'a', got end of input"
  it "should fail when the character received is not the one expected", ->
    (char 'a').should.not.parse new StringPStream "xyz"