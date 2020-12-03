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
      (char 'a').should.parse "abc"
      (char 'a').should.haveParseResult "abc", 'a'
    it "should parse Unicode characters", ->
      (char '日').should.parse "日本語"
      (char '日').should.haveParseResult "日本語", '日'
    it "should not parse at end of input", ->
      (char 'a').should.not.parse ""
      (char 'a').should.haveParseError "",
        "ParseError (position 0): Expecting character 'a', got end of input"
    it "should not parse an unexpected character", ->
      (char 'a').should.not.parse "xyz"
      (char '本').should.not.parse "日本語"

  describe "anyChar", ->
    it "should parse ASCII characters", ->
      anyChar.should.parse "abc"
      anyChar.should.haveParseResult "abc", 'a'
    it "should parse Unicode characters", ->
      anyChar.should.parse "日本語"
      anyChar.should.haveParseResult "日本語", '日'
    it "should not parse at end of input", ->
      anyChar.should.not.parse ""
      anyChar.should.haveParseError "",
        "ParseError (position 0): Expecting any character, got end of input"
  
  describe "peek", ->
    it "should peek non-empty strings", ->
      for stream in ["a", "abc", "xyz", "日本語"]
        peek.should.parse stream
        peek.should.haveParseResult stream, Buffer.from(stream)[0]
    it "should not peek at end of input", ->
      peek.should.not.parse ""
      peek.should.haveParseError "",
        "ParseError (position 0): Unexpected end of input"
    it "should not change the index", ->
      for stream in ["a", "abc", "xyz", "日本語"]
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
      (str "hello").should.parse "hello world"
      (str "hello").should.haveParseResult "hello world", "hello"
    it "should parse Unicode strings", ->
      (str "それ").should.parse "それはテストです。"
      (str "それ").should.haveParseResult "それはテストです。", "それ"
    it "should not parse at end of input", ->
      (str "anything here").should.not.parse ""
      (str "anything here").should.haveParseError "",
        "ParseError (position 0): Expecting string 'anything here', got end of input"
    it "should not parse an unexpected string", ->
      (str "hello").should.not.parse "abc"
      (str "日本語").should.not.parse "それはテストです。"
  
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
      (regex /^hello/).should.parse "hello world"
      (regex /^hello/).should.haveParseResult "hello world", "hello"
      (regex /^\w+\sworld/).should.parse "hello world"
      (regex /^\w+\sworld/).should.haveParseResult "hello world", "hello world"
    it "should parse Unicode matches", ->
      # Note: Unicode and regular expressions don't really work well together...
      (regex /^それ/).should.parse "それはテストです。"
      (regex /^それ/).should.haveParseResult "それはテストです。", "それ"
      (regex /^それはテスト/).should.parse "それはテストです。"
      (regex /^それはテスト/).should.haveParseResult "それはテストです。", "それはテスト"
    it "should not parse at end of input", ->
      (regex /^hello/).should.not.parse ""
      (regex /^テスト/).should.not.parse ""
      # Interestingly this below doesn't accept end of input
      (regex /^/).should.not.parse ""
  
  describe "digit", ->
    it "should parse digits", ->
      digit.should.parse "123456"
      digit.should.haveParseResult "123456", "1"
    it "should not parse non-digit characters", ->
      digit.should.not.parse "abc"
      digit.should.haveParseError "abc",
        "ParseError (position 0): Expecting digit, got 'a'"
      digit.should.not.parse "日本語"
      digit.should.haveParseError "日本語",
        "ParseError (position 0): Expecting digit, got '日'"
    it "should not parse at end of input", ->
      digit.should.not.parse ""
      digit.should.haveParseError "",
        "ParseError (position 0): Expecting digit, got end of input"
  
  describe "digits", ->
    it "should parse digits", ->
      digits.should.parse "123456"
      digits.should.haveParseResult "123456", "123456"
      digits.should.parse "123abc"
      digits.should.haveParseResult "123abc", "123"
    it "should not parse non-digit characters", ->
      digits.should.not.parse "abc"
      digits.should.haveParseError "abc",
        "ParseError (position 0): Expecting digits"
      digits.should.not.parse "日本語"
      digits.should.haveParseError "日本語",
        "ParseError (position 0): Expecting digits"
    it "should not parse at end of input", ->
      digits.should.not.parse ""
      digits.should.haveParseError "",
        "ParseError (position 0): Expecting digits"
  
  describe "letter", ->
    it "should parse letters", ->
      letter.should.parse "abc"
      letter.should.haveParseResult "abc", 'a'
    it "should not parse non-digit characters", ->
      letter.should.not.parse "123456"
      letter.should.haveParseError "123456",
        "ParseError (position 0): Expecting letter, got '1'"
    it "should not parse at end of input", ->
      letter.should.not.parse ""
      letter.should.haveParseError "",
        "ParseError (position 0): Expecting letter, got end of input"
  
  describe "letters", ->
    it "should parse letters", ->
      letters.should.parse "abc"
      letters.should.haveParseResult "abc", "abc"
      letters.should.parse "abc123"
      letters.should.haveParseResult "abc123", "abc"
    it "should not parse non-letter characters", ->
      letters.should.not.parse "123456"
      letters.should.haveParseError "123456",
        "ParseError (position 0): Expecting letters"
    it "should not parse at end of input", ->
      letters.should.not.parse ""
      letters.should.haveParseError "",
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
      (anyOfString "oleh").should.parse "hello world"
      (anyOfString "oleh").should.haveParseResult "hello world", 'h'
    it "should parse Unicode strings", ->
      (anyOfString "あれそ").should.parse "それはテストです。"
      (anyOfString "あれそ").should.haveParseResult "それはテストです。", 'そ'
    it "should not parse at end of input", ->
      (anyOfString "simp").should.not.parse ""
      (anyOfString "simp").should.haveParseError "",
        "ParseError (position 0): Expecting any of the string 'simp', got end of input"
    it "should not parse an unexpected string", ->
      (anyOfString "qwerty").should.not.parse "abc"
      (anyOfString "あいうえ").should.not.parse "それはテストです。"
  
  describe "endOfInput", ->
    it "should parse at end of input", ->
      endOfInput.should.parse ""
      endOfInput.should.haveParseResult "", null
    it "should not parse any input", ->
      endOfInput.should.not.parse "abc"
      endOfInput.should.not.parse "123456"
      endOfInput.should.not.parse "123abc"
      endOfInput.should.not.parse "日本語"
      endOfInput.should.not.parse "それはテストです。"
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
      whitespace.should.parse "   hmmm"
      whitespace.should.haveParseResult "   hmmm", "   "
    it "should not parse non-whitespaces", ->
      whitespace.should.not.parse "abc"
      whitespace.should.not.parse "123456"
      whitespace.should.not.parse "123abc"
      whitespace.should.not.parse "日本語"
      whitespace.should.not.parse "それはテストです。"
    it "should not parse at end of input", ->
      whitespace.should.not.parse ""
  
  describe "optionalWhitespace", ->
    it "should parse whitespaces", ->
      optionalWhitespace.should.parse "   hmmm"
      optionalWhitespace.should.haveParseResult "   hmmm", "   "
    it "should also parse non-whitespaces", ->
      optionalWhitespace.should.parse "abc"
      optionalWhitespace.should.parse "123456"
      optionalWhitespace.should.parse "123abc"
      optionalWhitespace.should.parse "日本語"
      optionalWhitespace.should.parse "それはテストです。"
      optionalWhitespace.should.haveParseResult "abc", ""
      optionalWhitespace.should.haveParseResult "123456", ""
      optionalWhitespace.should.haveParseResult "123abc", ""
      optionalWhitespace.should.haveParseResult "日本語", ""
      optionalWhitespace.should.haveParseResult "それはテストです。", ""
    it "should also parse at end of input", ->
      optionalWhitespace.should.parse ""
      optionalWhitespace.should.haveParseResult "", ""
      