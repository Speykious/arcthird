models =
  parse: require "./helpers/parse.model"

chai = require "chai"
chai.should()
chai.use models.parse

Parser      = require "../src/Parser"
ParserState = require "../src/ParserState"
{ StringPStream } = require "../src/pstreams"
{
  char, anyChar, peek, str
  regex, digit, digits
  letter, letters
  anyOfString, endOfInput
  whitespace, optionalWhitespace
} = require "../src/pgenerators"

sps = require "./sps"

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
      (char 'a').should.not.parse sps.empty
      (char 'a').should.haveParseError sps.empty,
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
      (str "anything here").should.not.parse sps.empty
      (str "anything here").should.haveParseError sps.empty,
        "ParseError (position 0): Expecting string 'anything here', got end of input"
    it "should not parse an unexpected string", ->
      (str "hello").should.not.parse sps.abc
      (str "日本語").should.not.parse sps.テスト
  
  describe "regex", ->
    it "should only accept regexs", ->
      (-> regex "ab").should.throw TypeError
      (-> regex 123).should.throw TypeError
      (-> regex true).should.throw TypeError
      (-> regex ["a"]).should.throw TypeError
      (-> regex /^ab/).should.not.throw()
      (-> regex /^/).should.not.throw()
      (-> regex /^日本/).should.not.throw()
    it "should reject regexs without '^'", ->
      (-> regex /xy/).should.throw Error
      (-> regex /テスト/).should.throw Error
      (-> regex /^xy/).should.not.throw()
    it "should parse ASCII matches", ->
      (regex /^hello/).should.parse sps.hello
      (regex /^hello/).should.haveParseResult sps.hello, "hello"
      (regex /^\w+\sworld/).should.parse sps.hello
      (regex /^\w+\sworld/).should.haveParseResult sps.hello, "hello world"
    it "should parse Unicode matches", ->
      # Note: Unicode and regular expressions don't really work well together...
      (regex /^それ/).should.parse sps.テスト
      (regex /^それ/).should.haveParseResult sps.テスト, "それ"
      (regex /^それはテスト/).should.parse sps.テスト
      (regex /^それはテスト/).should.haveParseResult sps.テスト, "それはテスト"
    it "should not parse at end of input", ->
      (regex /^hello/).should.not.parse sps.empty
      (regex /^テスト/).should.not.parse sps.empty
      # Interestingly this below doesn't accept end of input
      (regex /^/).should.not.parse sps.empty
  
  describe "digit", ->
    it "should parse digits", ->
      digit.should.parse sps.nums
      digit.should.haveParseResult sps.nums, "1"
    it "should not parse non-digit characters", ->
      digit.should.not.parse sps.abc
      digit.should.haveParseError sps.abc,
        "ParseError (position 0): Expecting digit, got 'a'"
      digit.should.not.parse sps.日本語
      digit.should.haveParseError sps.日本語,
        "ParseError (position 0): Expecting digit, got '日'"
    it "should not parse at end of input", ->
      digit.should.not.parse sps.empty
      digit.should.haveParseError sps.empty,
        "ParseError (position 0): Expecting digit, got end of input"
  
  describe "digits", ->
    it "should parse digits", ->
      digits.should.parse sps.nums
      digits.should.haveParseResult sps.nums, "123456"
      digits.should.parse sps.numalphs
      digits.should.haveParseResult sps.numalphs, "123"
    it "should not parse non-digit characters", ->
      digits.should.not.parse sps.abc
      digits.should.haveParseError sps.abc,
        "ParseError (position 0): Expecting digits"
      digits.should.not.parse sps.日本語
      digits.should.haveParseError sps.日本語,
        "ParseError (position 0): Expecting digits"
    it "should not parse at end of input", ->
      digits.should.not.parse sps.empty
      digits.should.haveParseError sps.empty,
        "ParseError (position 0): Expecting digits"
  
  describe "letter", ->
    it "should parse letters", ->
      letter.should.parse sps.abc
      letter.should.haveParseResult sps.abc, 'a'
    it "should not parse non-digit characters", ->
      letter.should.not.parse sps.nums
      letter.should.haveParseError sps.nums,
        "ParseError (position 0): Expecting letter, got '1'"
    it "should not parse at end of input", ->
      letter.should.not.parse sps.empty
      letter.should.haveParseError sps.empty,
        "ParseError (position 0): Expecting letter, got end of input"
  
  describe "letters", ->
    it "should parse letters", ->
      letters.should.parse sps.abc
      letters.should.haveParseResult sps.abc, "abc"
      letters.should.parse sps.alphnums
      letters.should.haveParseResult sps.alphnums, "abc"
    it "should not parse non-letter characters", ->
      letters.should.not.parse sps.nums
      letters.should.haveParseError sps.nums,
        "ParseError (position 0): Expecting letters"
    it "should not parse at end of input", ->
      letters.should.not.parse sps.empty
      letters.should.haveParseError sps.empty,
        "ParseError (position 0): Expecting letters"
  
  describe "anyOfString", ->
    it "should only accept non-empty strings", ->
      (-> anyOfString "").should.throw TypeError
      (-> anyOfString 10).should.throw TypeError
      (-> anyOfString true).should.throw TypeError
      (-> anyOfString ["a"]).should.throw TypeError
      (-> anyOfString "x").should.not.throw()
      (-> anyOfString " \n").should.not.throw()
      (-> anyOfString "ab").should.not.throw()
      (-> anyOfString "何").should.not.throw()
      (-> anyOfString "テストです").should.not.throw()
    it "should parse ASCII strings", ->
      (anyOfString "oleh").should.parse sps.hello
      (anyOfString "oleh").should.haveParseResult sps.hello, 'h'
    it "should parse Unicode strings", ->
      (anyOfString "あれそ").should.parse sps.テスト
      (anyOfString "あれそ").should.haveParseResult sps.テスト, 'そ'
    it "should not parse at end of input", ->
      (anyOfString "simp").should.not.parse sps.empty
      (anyOfString "simp").should.haveParseError sps.empty,
        "ParseError (position 0): Expecting any of the string 'simp', got end of input"
    it "should not parse an unexpected string", ->
      (anyOfString "qwerty").should.not.parse sps.abc
      (anyOfString "あいうえ").should.not.parse sps.テスト
  
  describe "endOfInput", ->
    it "should parse at end of input", ->
      endOfInput.should.parse sps.empty
      endOfInput.should.haveParseResult sps.empty, null
    it "should not parse any input", ->
      endOfInput.should.not.parse sps.abc
      endOfInput.should.not.parse sps.nums
      endOfInput.should.not.parse sps.numalphs
      endOfInput.should.not.parse sps.日本語
      endOfInput.should.not.parse sps.テスト
    it "passes check 42 (yeet)", ->
      state = new ParserState {
        target: new StringPStream "42"
        index: 1
      }
      (endOfInput.pf state).isError.should.be.true
      state.index = 2
      (endOfInput.pf state).isError.should.be.false
  
  describe "whitespace", ->
    it "should parse whitespaces", ->
      whitespace.should.parse sps.spaces
      whitespace.should.haveParseResult sps.spaces, "   "
    it "should not parse non-whitespaces", ->
      whitespace.should.not.parse sps.abc
      whitespace.should.not.parse sps.nums
      whitespace.should.not.parse sps.numalphs
      whitespace.should.not.parse sps.日本語
      whitespace.should.not.parse sps.テスト
    it "should not parse at end of input", ->
      whitespace.should.not.parse sps.empty
  
  describe "optionalWhitespace", ->
    it "should parse whitespaces", ->
      optionalWhitespace.should.parse sps.spaces
      optionalWhitespace.should.haveParseResult sps.spaces, "   "
    it "should also parse non-whitespaces", ->
      optionalWhitespace.should.parse sps.abc
      optionalWhitespace.should.parse sps.nums
      optionalWhitespace.should.parse sps.numalphs
      optionalWhitespace.should.parse sps.日本語
      optionalWhitespace.should.parse sps.テスト
      optionalWhitespace.should.haveParseResult sps.abc, ""
      optionalWhitespace.should.haveParseResult sps.nums, ""
      optionalWhitespace.should.haveParseResult sps.numalphs, ""
      optionalWhitespace.should.haveParseResult sps.日本語, ""
      optionalWhitespace.should.haveParseResult sps.テスト, ""
    it "should also parse at end of input", ->
      optionalWhitespace.should.parse sps.empty
      optionalWhitespace.should.haveParseResult sps.empty, ""
      