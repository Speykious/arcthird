Parser                     = require "./Parser"
{ reErrorExpectation }     = require "./constants"
{ getCharacterLength }     = require "./helpers"
{ StringPStream, decoder } = require "./pstreams"

# getData :: PStream t => Parser t a d
getData = new Parser (s) ->
  return if sisEerror then s
  else s.resultify s.data

# setData :: PStream t => d -> Parser t a d
setData = (d) ->
  new Parser (s) ->
    return if s.isError then s
    else state.dataify d

# mapData :: PStream t => (d -> e) -> Parser t a e
mapData = (f) ->
  new Parser (s) ->
    return if s.isError then s
    else s.dataify f s.data

# withData :: PStream t => Parser t a d -> e -> Parser t a e
withData = (parser) -> (d) ->
  (setData d).chain (-> parser)

# pipe :: PStream t => [Parser t * *] -> Parser t * *
pipe = (parsers) ->
  new Parser (s) ->
    for parser in parsers
      s = parser.pf s
    return s

# compose :: PStream t => [Parser t * *] -> Parser t * *
compose = (parsers) ->
  new Parser (s) ->
    (pipe [parsers...].reverse()).pf s

# tap :: PStream t => (ParserState t a d -> IO ()) -> Parser t a d
tap = (f) ->
  new Parser (s) ->
    f s
    return s

# parse :: PStream t => Parser t a d -> t -> Either String a
parse = (parser) -> parser.parse

# decide :: PStream t => (a -> Parser t b d) -> Parser t b d
decide = (f) ->
  new Parser (s) ->
    return if s.isError then s
    else (f s.result).pf s

# fail :: PStream t => String -> Parser t a d
fail = (e) ->
  new Parser (s) ->
    return if s.isError then s
    else s.errorify e

# succeedWith :: PStream t => a -> Parser t a d
succeedWith = Parser.of

# either :: PStream t => Parser t a d -> Parser t (Either String a) d
either = (parser) ->
  new Parser (s) ->
    if s.isError then return s
    state = parser.pf s
    { error } = state
    state.error = null
    return state.resultify (error or state.result)

# coroutine :: PStream t => (() -> Iterator (Parser t a d)) -> Parser t a d
coroutine = (g) ->
  new Parser (s) ->
    generator = g()
    value = undefined
    loop
      r = generator.next value
      v = r.value
      done = r.done
      unless done or (v and v instanceof Parser)
        throw new Error "[coroutine] yielded values must be Parsers, got #{v}."
      if done then return s.resultify v
      
      s = v.pf s
      if s.isError then return s
      value = s.result

# exactly :: PStream t => Int -> Parser t a d -> Parser t [a] d
exactly = (n) ->
  unless typeof n is "number" and n > 0
    throw new TypeError "exactly: Expected a number > 0, got #{n}."
  return (parser) ->
    (new Parser (s) ->
      if s.isError then return s
      results = []
      for i in [0..(n-1)]
        s = parser.pf s
        if s.isError then return s
        results.push s.result
      return s.resultify results
    ).errorMap ({ index, error }) ->
      "ParseError (position #{index}): Expecting #{n} #{error.replace reErrorExpectation, ""}"

# many :: PStream t => Parser t a d -> Parser t [a] d
many = (parser) ->
  new Parser (s) ->
    if s.isError then return s
    results = []
    loop
      s = parser.pf s
      if s.isError then break
      results.push s
      { target, index } = s
      if target.length() and index >= target.length() then break
    return s.resultify results

# atLeast :: PStream t => Int -> Parser t a d -> Parser t [a] d
atLeast = (n) -> (parser) ->
  new Parser (s) ->
    if s.isError then return s
    state = (many parser).pf s
    return if state.result.length >= n then state
    else s.errorify "ParseError 'atLeast' (position #{s.index}): Expecting to match at least #{n} value(s), received #{state.result.length} instead"

# atLeast1 :: PStream t => Parser t a d -> Parser t [a] d
atLeast1 = atLeast 1

# mapTo :: PStream t => (a -> b) -> Parser t b d
mapTo = (f) ->
  new Parser (s) ->
    return if s.isError then s
    else s.resultify f s.result

# errorMapTo :: PStream t => ({d, String, Int} -> String) -> Parser t a d
errorMapTo = (f) ->
  new Parser (s) ->
    return unless s.isError then s
    else s.errorify f s.errorProps()

# namedSequenceOf :: PStream t => [(String, Parser t * *)] -> Parser t (StrMap *) d
namedSequenceOf = (pairedParsers) ->
  new Parser (s) ->
    if s.isError then return s
    results = {}
    for key, parser of pairedParsers
      out = parser.pf s
      if out.isError then return out
      else
        s = out
        results[key] = out.result
    
    return s.resultify results

# sequenceOf :: PStream t => [Parser t * *] -> Parser t [*] *
sequenceOf = (parsers) ->
  new Parser (s) ->
    if s.isError then return s

    length = parsers.length
    results = new Array(length)
    for i in [0...length]
      out = parsers[i].pf s
      if out.isError then return out
      else
        s = out
        results[i] = out.result
    
    return s.resultify results

# sepBy :: PStream t => Parser t a d -> Parser t b d -> Parser t [b] d
sepBy = (sepParser) -> (valParser) ->
  new Parser (s) ->
    if s.isError then return s

    error = null
    results = []
    loop
      valState = valParser.pf s
      sepState = sepParser.pf valState
      
      if valState.isError
        error = valState
        break
      results.push valState.result
      
      if sepState.isError
        s = valState
        break
      s = sepState
    
    if error
      return if results.length is 0
      then s.resultify results else error
    
    s.resultify results

# sepBy1 :: PStream t => Parser t a d -> Parser t b d -> Parser t [b] d
sepBy1 = (sepParser) -> (valParser) ->
  new Parser (s) ->
    if s.isError then return s
    
    out = ((sepBy sepParser) valParser).pf s
    if out.isError then return out
    return if out.result.length is 0
    then s.errorify "ParseError 'sepBy1' (position #{s.index}): Expecting to match at least one separated value"
    else out

# choice :: PStream t => [Parser t * *] -> Parser t * *
choice = (parsers) ->
  new Parser (s) ->
    if s.isError then return s

    error = null
    for parser in parsers
      out = parser.pf s

      unless out.isError then return out
      if not error or (error and out.index > error.index)
        error = out
    
    return error

# between :: PStream t => Parser t a d -> Parser t b d -> Parser t c d -> Parser t b d
between = (leftp) -> (rightp) -> (parser) ->
  (sequenceOf [leftp, parser, rightp]).map ([_, x]) -> x

# everythingUntil :: StringPStream t => Parser t a d -> Parser t String d
everythingUntil = (parser) ->
  new Parser (s) ->
    unless s.target instanceof StringPStream
      throw new TypeError "everythingUntil expects a StringPStream instance as target, got #{typeof s.target} instead"
    if s.isError then return s

    results = []
    loop
      out = parser.pf s
      if out.isError
        { index, target } = s
        if target.length() <= index
          return s.errorify "ParseError 'everythingUntil' (position #{index}): Unexpected end of input"
        
        val = target.elementAt index
        if val
          results.push val
          s = s.update val, index + 1
      else break
    
    return s.resultify results

# everyCharUntil :: StringPStream t => Parser t a d -> Parser t String d
everyCharUntil = (parser) ->
  (everythingUntil parser).map (results) ->
    decoder.decode Uint8Array.from results

# anythingExcept :: StringPStream t => Parser t a d -> Parser t Char d
anythingExcept = (parser) ->
  new Parser (s) ->
    if s.isError then return s
    { target, index } = s

    out = parser.pf s
    return if out.isError
    then s.update (target.elementAt index), index + 1
    else s.errorify "ParseError 'anythingExcept' (position #{index}): Matched '#{out.result}' from the exception parser"

# anyCharExcept :: StringPStream t => Parser t a d -> Parser t Char d
anyCharExcept = (parser) ->
  new Parser (s) ->
    unless s.target instanceof StringPStream
      throw new TypeError "anyCharExcept expects a StringPStream instance as target, got #{typeof s.target} instead"
    if s.isError then return s
    { target, index } = s

    out = parser.pf s
    if out.isError
      if index < target.length()
        charWidth = target.getCharWidth index
        if index + charWidth <= target.length()
          char = target.getUtf8Char index, charWidth
          return s.update char, index + charWidth
      return s.errorify "ParseError 'anyCharExcept' (position #{index}): Unexpected end of input"
    return s.errorify "ParseError 'anyCharExcept' (position #{index}): Matched '#{out.result}' from the exception parser"

# lookAhead :: PStream t => Parser t a d -> Parser t a d
lookAhead = (parser) ->
  new Parser (s) ->
    if s.isError then return s
    state = parser.pf s
    return if state.isError
    then s.errorify state.error
    else s.resultify state.result

# possibly :: PStream t => Parser t a d -> Parser t (a | Null) d
possibly = (parser) ->
  new Parser (s) ->
    if s.isError then return s
    state = parser.pf s
    return if state.isError
    then s.resultify null
    else state

# skip :: PStream t => Parser t a d -> Parser t a d
skip = (parser) ->
  new Parser (s) ->
    if s.isError then return s
    state = parser.pf s
    return if state.isError then state
    else state.resultify s.result

# recursiveParser :: PStream t => (() -> Parser t a d) -> Parser t a d
recursiveParser = (pthunk) ->
  new Parser (s) -> pthunk().pf s

# takeRight :: PStream t => Parser t a d -> Parser t b d -> Parser t b d
takeRight = (leftp) -> (rightp) ->
  leftp.chain () -> rightp

# takeLeft :: PStream t => Parser t a d -> Parser t b d -> Parser t a d
takeLeft = (leftp) -> (rightp) ->
  leftp.chain (x) -> rightp.map () -> x

# toPromise :: PStream t => ParserState t a d -> Promise (String, Integer, d) a
toPromise = (s) ->
  if s.isError
  then Promise.reject s.errorProps()
  else Promise.resolve s.result

# toValue :: PStream t => ParserState t a d -> a
toValue = (s) ->
  if s.isError
    e = new Error s.error
    e.parseIndex = s.index
    e.data = s.data
    throw e
  return s.result

module.exports = {
  getData, setData, mapData, withData
  pipe, compose, tap, parse, decide, fail
  succeedWith, either, coroutine
  exactly, many, atLeast, atLeast1
  mapTo, errorMapTo
  namedSequenceOf, sequenceOf
  sepBy, sepBy1, choice, between
  everythingUntil, everyCharUntil
  anythingExcept, anyCharExcept
  lookAhead, possibly, skip
  recursiveParser, takeRight, takeLeft
  toPromise, toValue
}