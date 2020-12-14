models =
  parse: require "./helpers/parse.model"

chai = require "chai"
expect = chai.expect
chai.should()
chai.use models.parse

{ strparse } = require "../src/pcombinators"
{ digits, letters } = require "../src/pgenerators"


describe "Parser", ->
  it "should map correctly", ->
    parser = digits.map Number
    parser.should.haveParseResult "69", 69
    parser.should.haveParseResult "42", 42
    # Is this alright? I thought it would output NaN...
    parser.should.haveParseResult "banana", undefined
  it "should filter correctly", ->
    parser = letters.filter (l) -> l.length >= 3 and l.length <= 10
    parser.should.parse "letters"
    parser.should.not.parse "a"
    parser.should.not.parse "thisverylongsequenceofletters"
