models =
  parse: require "./helpers/parse.model"

chai = require "chai"
expect = chai.expect
chai.should()
chai.use models.parse

Parser      = require "../src/Parser"
ParserState = require "../src/ParserState"
{ StringPStream } = require "../src/pstreams"
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
  toValue
} = require "../src/pcombinators"
{
  digit, digits, letter, letters
  str, char, whitespace
} = require "../src/pgenerators"

join = (s) -> (l) -> l.join s

describe "Parser Combinators", ->
  describe "getData", ->
    p = withData coroutine () ->
      sd = yield getData
      return sd
    it "should parse something", ->
      (p "data").should.parse "abc"
      (p "data").should.parse ""
    it "should get data from the parser", ->
      (p "data").should.haveParseResult "abc", "data"
    it "should get data even when PStream is empty", ->
      (p "data").should.haveParseResult "", "data"

  describe "setData", ->
    parser = coroutine () ->
      yield setData "new data"
      return 42
    it "should parse something", ->
      parser.should.parse "abc"
      parser.should.parse ""
    it "should set data on the parser", ->
      parser.should.haveParseResult "abc", 42
      parser.should.haveParseData "abc", "new data"
    it "should set data even when PStream is empty", ->
      parser.should.haveParseResult "", 42
      parser.should.haveParseData "", "new data"
  
  describe "mapData", ->
    p = withData coroutine () ->
      yield mapData (d) -> d.map (x) -> x * 2
      return 42
    it "should parse something", ->
      (p [1, 2, 3]).should.parse "abc"
      (p [1, 2, 3]).should.parse ""
    it "should map data on the parser", ->
      (p [1, 2, 3]).should.haveParseResult "abc", 42
      (p [1, 2, 3]).should.haveParseData "abc", [2, 4, 6]
    it "should map data even when PStream is empty", ->
      (p [1, 2, 3]).should.haveParseResult "", 42
      (p [1, 2, 3]).should.haveParseData "", [2, 4, 6]
  
  describe "withData", ->
    parser = (withData digits) "my data"
    it "should parse something", ->
      parser.should.parse "123abc"
      parser.should.not.parse ""
    it "should have data on the parser", ->
      parser.should.haveParseResult "123abc", "123"
      parser.should.haveParseData "123abc", "my data"
    it "should have data even when PStream is empty", ->
      parser.should.haveParseData "", "my data"
  
  describe "pipe", ->
    parser = pipe [(str "hello"), (char ' '), (str "world")]
    it "should parse like a pipe", ->
      parser.should.parse "hello world"
    it "should fail like a parser", ->
      parser.should.not.parse "abc123"
    it "should act like a pipe", ->
      parser.should.haveParseResult "hello world", "world"
  
  describe "compose", ->
    parser = compose [(str "world"), (char ' '), (str "hello")]
    it "should parse like a composition", ->
      parser.should.parse "hello world"
    it "should fail like a parser", ->
      parser.should.not.parse "abc123"
    it "should act like a composition", ->
      parser.should.haveParseResult "hello world", "world"
  
  describe "tap", ->
    state = undefined
    parser = pipe [(char 'a'), (tap (x) -> state = x)]
    it "should parse something", ->
      parser.should.parse "abc"
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
      parser.should.not.parse "xyz"
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
      abc = new StringPStream "abc"
      ((parse char 'a') abc).props.should.equal ((char 'a').parse abc).props
    it "doesn't have anything else interesting", ->
      true.should.not.be.false
  
  describe "strparse", ->
    abc = new StringPStream "abc"
    it "should just work", ->
      ((strparse char 'a') "abc").props.should.equal ((char 'a').parse abc).props
  
  describe "decide", ->
    df = (res) -> switch res
      when "abc" then digits
      when "hello" then str " world"
      else fail "nope"
    parser = pipe [letters, decide df]
    it "should decide the right thing (1)", ->
      parser.should.parse "abc123"
      parser.should.haveParseResult "abc123", "123"
    it "should decide the right thing (2)", ->
      parser.should.parse "hello world"
      parser.should.haveParseResult "hello world", " world"
    it "should not decide the wrong thing", ->
      parser.should.not.parse "xyz"
      parser.should.haveParseError "xyz", "nope"
  
  describe "fail", ->
    it "fails successfully", ->
      (fail "task failed successfully").should.not.parse "hello world"
    it "generates the right error", ->
      (fail "task failed successfully").should.haveParseError "hello world", "task failed successfully"
  
  describe "succeedWith", ->
    it "should parse anything", ->
      (succeedWith "a career").should.parse "abc"
      (succeedWith "a career").should.parse "それはテストです。"
    it "should parse nothing", ->
      (succeedWith "nothing").should.parse ""
    it "should actually succeed with the value", ->
      (succeedWith "a career").should.haveParseResult "abc", "a career"
      (succeedWith "nothing").should.haveParseResult "", "nothing"
  
  describe "either", ->
    it "should work when it works", ->
      (either char 'a').should.parse "abc"
      (either char 'a').should.parse "abc123"
    it "should work when it fails", ->
      (either char 'a').should.parse "xyz"
      (either char 'a').should.parse "それはテストです。"
      (either char 'a').should.parse ""
      (either fail "nope").should.parse "hello world"
      (either fail "nope").should.parse ""
  
  describe "coroutine", ->
    parser = coroutine () ->
      part1 = yield letters
      part2 = yield digits
      return [part1, part2]
    it "should correctly use yielded parsers", ->
      parser.should.parse "abc123"
      parser.should.haveParseResult "abc123", ["abc", "123"]
    it "should not be stateful on second usage", ->
      parser.should.parse "xyz987"
      parser.should.haveParseResult "xyz987", ["xyz", "987"]
    it "should show the correct error", ->
      parser.should.not.parse "abc"
      parser.should.haveParseError "abc", "ParseError (position 3): Expecting digits"
    it "should only accept parsers as yielded values", ->
      fakeParser = coroutine () ->
        part1 = yield letters
        part2 = yield 42
        return [part1, part2]
      (-> (strparse fakeParser) "abc123").should.throw Error
      (-> (strparse fakeParser) "abc123").should.throw "[coroutine] yielded values must be Parsers, got 42."
  
  describe "exactly", ->
    it "should work exactly as expected", ->
      ((exactly 3) letter).should.haveParseResult "abc", ['a', 'b', 'c']
    it "should fail exactly as expected", ->
      ((exactly 3) letter).should.not.parse "123abc"
      ((exactly 3) letter).should.haveParseError "123abc", "ParseError (position 0): Expecting 3 letter, got '1'"
    it "should fail at end of input", ->
      ((exactly 4) letter).should.not.parse "abc"
      (strparse (exactly 4) letter) "123abc", "ParseError (position 0): Expecting 4 letter, got '1'"
    it "should only accept a number > 0", ->
      (-> exactly 0).should.throw TypeError
      (-> exactly 'a').should.throw TypeError
  
  describe "many", ->
    it "should parse many things", ->
      (many digit).should.parse "123456"
      (many digit).should.haveParseResult "123abc", ['1', '2', '3']

    it "should not fail when nothing is parsed", ->
      (many digit).should.parse "abc"
      (many digit).should.haveParseResult "abc", []
  
  describe "atLeast", ->
    it "should parse at least x things", ->
      ((atLeast 2) digit).should.haveParseResult "123abc", ['1', '2', '3']
      ((atLeast 1) digit).should.haveParseResult "123456", ['1', '2', '3', '4', '5', '6']
    it "should not fail when nothing is parsed for at least 0", ->
      ((atLeast 0) digit).should.haveParseResult "abc", []
    it "should fail when there aren't enough parsed results", ->
      ((atLeast 4) digit).should.not.parse "123abc"
      ((atLeast 4) digit).should.haveParseError "123abc", "ParseError 'atLeast' (position 0): Expecting to match at least 4 value(s), received 3 instead"
      ((atLeast 1) digit).should.not.parse "abc"
      ((atLeast 1) digit).should.haveParseError "abc", "ParseError 'atLeast' (position 0): Expecting to match at least 1 value(s), received 0 instead"
  
  describe "atLeast1", ->
    it "should parse at least 1 thing", ->
      (atLeast1 digit).should.haveParseResult "123abc", ['1', '2', '3']
      (atLeast1 digit).should.haveParseResult "123456", ['1', '2', '3', '4', '5', '6']
    it "should fail when there isn't at least 1 parsed result", ->
      (atLeast1 digit).should.not.parse "abc"
      (strparse atLeast1 digit) "abc", "ParseError 'atLeast' (position 0): Expecting to match at least 1 value(s), received 0 instead"

  describe "mapTo", ->
    parser = pipe [(char 'a'), mapTo (x) -> ({ letter: x })]
    it "should map correctly", ->
      parser.should.haveParseResult "abc", { letter: 'a' }
      (mapTo (x) -> "bruh").should.haveParseResult "", "bruh"
  
  describe "errorMapTo", ->
    parser = pipe [
      choice [ sequenceOf [whitespace, letters]
               sequenceOf [letters, digits] ]
      errorMapTo ({ index }) -> "Failed to parse structure @ #{index}"
    ]
    it "shouldn't change the behavior of the parser", ->
      parser.should.parse "   hmmm"
      parser.should.parse "abc123"
    it "should give the mapped error", ->
      parser.should.not.parse "abc"
      parser.should.haveParseError "abc", "Failed to parse structure @ 3"
  
  describe "namedSequenceOf", ->
    parser = namedSequenceOf [ ["letters", letters]
                               ["numbers", digits] ]
    it "should parse like sequenceOf but named", ->
      parser.should.haveParseResult "abc123", {
        letters: "abc"
        numbers: "123"
      }
    it "should fail like sequenceOf but named", ->
      parser.should.not.parse "abc"
      parser.should.haveParseError "abc", "ParseError (position 3): Expecting digits"
  
  describe "sequenceOf", ->
    parser = sequenceOf [letters, digits]
    it "should parse like a sequence of parsers", ->
      parser.should.haveParseResult "abc123", ["abc", "123"]
    it "should fail when one of them fail", ->
      parser.should.not.parse "abc"
      parser.should.haveParseError "abc", "ParseError (position 3): Expecting digits"
  
  describe "sepBy", ->
    parser = (sepBy char ',') letter
    it "should correctly separate input", ->
      parser.should.haveParseResult "a,b,c", ['a', 'b', 'c']
    it "should accept empty input", ->
      parser.should.haveParseResult "", []
    it "should give nothing if the main parser doesn't work", ->
      parser.should.haveParseResult "1,2,3", []
    it "Hmmm... I'm not sure about that test", ->
      parser.should.not.parse "a,b,"
      parser.should.haveParseError "a,b,", "ParseError (position 4): Expecting letter, got end of input"
  
  describe "sepBy1", ->
    parser = (sepBy1 char ',') letter
    it "should correctly separate input", ->
      parser.should.haveParseResult "a,b,c", ['a', 'b', 'c']
    it "should not accept empty input", ->
      parser.should.not.parse ""
      parser.should.haveParseError "", "ParseError 'sepBy1' (position 0): Expecting to match at least one separated value"
    it "should fail if the main parser doesn't work", ->
      parser.should.not.parse "1,2,3"
      parser.should.haveParseError "1,2,3", "ParseError 'sepBy1' (position 0): Expecting to match at least one separated value"
    it "Hmmm... I'm not sure about that test", ->
      parser.should.not.parse "a,b,"
      parser.should.haveParseError "a,b,", "ParseError (position 4): Expecting letter, got end of input"
  
  describe "choice", ->
    parser = choice [letter, digit, char '!']
    it "should work for each choice", ->
      parser.should.haveParseResult "abcd", 'a'
      parser.should.haveParseResult "1bcd", '1'
      parser.should.haveParseResult "!bcd", '!'
    it "should not work for anything else", ->
      parser.should.not.parse "-bcd"
      parser.should.haveParseError "-bcd", "ParseError (position 0): Expecting letter, got '-'"
  
  describe "between", ->
    parser = between(char '(')(char ')') letters
    it "should parse between parsers", ->
      parser.should.haveParseResult "(hello)", "hello"
    it "should parse between parsers (2)", ->
      (between(char '[')(char ']') (sepBy char ',') digit).should.haveParseResult "[1,2,3,4]", '1234'.split ''
    it "should not parse when incomplete", ->
      parser.should.not.parse "(hello world)"
      parser.should.haveParseError "(hello world)", "ParseError (position 6): Expecting character ')', got ' '"
  
  describe "everythingUntil", ->
    parser = everythingUntil char '!'
    it "should parse everything until the parser", ->
      parser.should.haveParseResult "テスト!日本語に", [(Buffer.from "テスト")...]
    it "should work with a simple pipe", ->
      (pipe [parser, char '!']).should.haveParseResult "テスト!日本語に", '!'
    it "should be able to give nothing", ->
      parser.should.haveParseResult "!", []
    it "should fail if the until never arrives", ->
      parser.should.not.parse ""
      parser.should.haveParseError "", "ParseError 'everythingUntil' (position 0): Unexpected end of input"
  
  describe "everyCharUntil", ->
    parser = everyCharUntil char '!'
    it "should parse every char until the parser", ->
      parser.should.haveParseResult "テスト!日本語に", "テスト"
    it "should work with a simple pipe", ->
      (pipe [parser, char '!']).should.haveParseResult "テスト!日本語に", '!'
    it "should be able to give nothing (really?)", ->
      parser.should.haveParseResult "!", ""
    it "should fail if the until never arrives", ->
      parser.should.not.parse ""
      parser.should.haveParseError "", "ParseError 'everythingUntil' (position 0): Unexpected end of input"
  
  describe "anythingExcept", ->
    parser = anythingExcept char '!'
    it "should parse anything except the parser", ->
      parser.should.haveParseResult "a", ('a'.charCodeAt 0)
      parser.should.haveParseResult "1", ('1'.charCodeAt 0)
    it "should do the same for unicode characters", ->
      parser.should.haveParseResult "あ", (Buffer.from 'あ')[0]
    it "should fail when the parser doesn't", ->
      parser.should.not.parse "!"
      parser.should.haveParseError "!", "ParseError 'anythingExcept' (position 0): Matched '!' from the exception parser"
  
  describe "anyCharExcept", ->
    parser = anyCharExcept char '!'
    it "should parse anything except the parser", ->
      parser.should.haveParseResult "a", 'a'
      parser.should.haveParseResult "1", '1'
    it "should do the same for unicode characters", ->
      parser.should.haveParseResult "あ", 'あ'
    it "should fail when the parser doesn't", ->
      parser.should.not.parse "!"
      parser.should.haveParseError "!", "ParseError 'anyCharExcept' (position 0): Matched '!' from the exception parser"
  
  describe "lookAhead", ->
    parser = lookAhead char 'a'
    it "should give the correct result", ->
      parser.should.haveParseResult "aaaa", 'a'
    it "should work in a pipe", ->
      (pipe [parser, char 'a']).should.haveParseResult "aaaa", 'a'
    it "should fail if the inner parser fails", ->
      parser.should.not.parse "b"
      parser.should.haveParseError "b", "ParseError (position 0): Expecting character 'a', got 'b'"
  
  describe "possibly", ->
    parser = possibly char 'a'
    it "should be possible", ->
      parser.should.haveParseResult "a", 'a'
    it "should be optional", ->
      parser.should.haveParseResult "b", null
    it "should be optional for an empty input", ->
      parser.should.haveParseResult "", null
    it "should be optional even for a literal failure", ->
      (possibly fail "nope").should.parse "a", null
  
  describe "skip", ->
    parser = skip char 'a'
    it "should skip the inner parser", ->
      parser.should.haveParseResult "a", undefined
    it "should fail if the inner parser fails", ->
      parser.should.not.parse "b"
      parser.should.haveParseError "b", "ParseError (position 0): Expecting character 'a', got 'b'"
  
  describe "recursiveParser", ->
    parser = recursiveParser () -> choice [letter, digit, arr]
    arr = between(char '[')(char ']') (sepBy char ',') parser
    it "should just work", ->
      parser.should.haveParseResult "abc", 'a'
      parser.should.haveParseResult "123", '1'
    it "should just work²", ->
      parser.should.haveParseResult "[1,a,b]", ['1', 'a', 'b']
      parser.should.haveParseResult "[1,a,[2,b]]", ['1', 'a', ['2', 'b']]
    it "should fail like any parser", ->
      parser.should.not.parse "!nope"
      parser.should.haveParseError "!nope", "ParseError (position 0): Expecting letter, got '!'"
    it "should also fail at empty input", ->
      parser.should.not.parse ""
      parser.should.haveParseError "", "ParseError (position 0): Expecting letter, got end of input"
  
  describe "takeRight", ->
    parser = (takeRight str "abc") str "def"
    it "should abandon the left one", ->
      parser.should.haveParseResult "abcdef", "def"
    it "should fail like a sequence", ->
      parser.should.not.parse "abc"
      parser.should.haveParseError "abc", "ParseError (position 3): Expecting string 'def', got end of input"
    it "should fail at empty input like the left parser", ->
      parser.should.not.parse ""
      parser.should.haveParseError "", "ParseError (position 0): Expecting string 'abc', got end of input"
  
  describe "takeLeft", ->
    parser = (takeLeft str "abc") str "def"
    it "should abandon the right one", ->
      parser.should.haveParseResult "abcdef", "abc"
    it "should fail like a sequence", ->
      parser.should.not.parse "abc"
      parser.should.haveParseError "abc", "ParseError (position 3): Expecting string 'def', got end of input"
    it "should fail at empty input like the right parser", ->
      parser.should.not.parse ""
      parser.should.haveParseError "", "ParseError (position 0): Expecting string 'abc', got end of input"
  
  describe "toValue", ->
    lparser = (strparse str "haha yesn't") "nope"
    rparser = (strparse str "yeet") "yeet²"
    it "should throw an error when the parser fails", ->
      try
        toValue lparser
        throw new Error "Expected to throw error"
      catch e
        # Not sure if str should behave like that
        e.message.should.equal "ParseError (position 0): Expecting string 'haha yesn't', got end of input"
        e.parseIndex.should.equal 0
    it "should return the value when it succeeds", ->
      (toValue rparser).should.equal "yeet"

  # Note: due to UnhandledPromiseRejection problems, toPromise is probably gonna get its own unique testing file without using chai in the process.
