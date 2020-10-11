Parser                 = require "./Parser"
{ reErrorExpectation } = require "./constants"
{ getCharacterLength } = require "./helpers"

# getData :: Parser t a d
getData = new Parser (s) ->
  return if s.error then s
  else s.resultify s.data

# setData :: d -> Parser t a d
setData = (d) ->
  new Parser (s) ->
    return if s.error then s
    else state.dataify d

# mapData :: (d -> e) -> Parser t a e
mapData = (f) ->
  new Parser (s) ->
    return if s.error then s
    else s.dataify f s.data

# withData :: Parser t a d -> e -> Parser t a e
withData = (parser) -> (d) ->
  (setData d).chain (-> parser)

# pipe :: [Parser * * *] -> Parser * * *
pipe = (parsers) ->
  new Parser (s) ->
    for parser in parsers
      s = parser.pf s
    return s

# compose :: [Parser * * *] -> Parser * * *
compose = (parsers) ->
  new Parser (s) ->
    (pipe [parsers...].reverse()).pf s

# tap :: (ParserState t a d -> IO ()) -> Parser t a d
tap = (f) ->
  new Parser (s) ->
    f s
    return s

# parse :: Iterable t => Parser t a d -> t -> Either String a
parse = (parser) -> parser.parse

# decide :: (a -> Parser t b d) -> Parser t b d
decide = (f) ->
  new Parser (s) ->
    return if s.error then s
    else (f s.result).pf s

# fail :: String -> Parser t a d
fail = (e) ->
  new Parser (s) ->
    return if s.error then s
    else s.errorify e

# succeedWith :: a -> Parser t a d
succeedWith = Parser.of

# either :: Parser t a d -> Parser t (Either String a) d
either = (parser) ->
  new Parser (s) ->
    if s.error then return s
    state = parser.pf s
    { error } = state
    state.error = null
    return state.resultify (error or state.result)

# coroutine :: (() -> Iterator (Parser t a d)) -> Parser t a d
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
      if s.error then return s
      value = s.result

# exactly :: Int -> Parser t a d -> Parser t [a] d
exactly = (n) ->
  unless typeof n is "number" and n > 0
    throw new TypeError "exactly: Expected a number > 0, got #{n}."
  return (parser) ->
    (new Parser (s) ->
      if s.error then return s
      results = []
      for i in [0..(n-1)]
        s = parser.pf s
        if s.error then return s
        results.push s.result
      return s.resultify results
    ).errorMap ({ index, error }) ->
      "ParseError (position #{index}): Expecting #{n} #{error.replace reErrorExpectation, ""}"

# many :: Parser t a d -> Parser t [a] d
many = (parser) ->
  new Parser (s) ->
    if s.error then return s
    results = []
    loop
      s = parser.pf s
      if s.error then break
      results.push s
      # Hmmm... This line below makes me doubt about abstraction on iterables...
      if s.target.length and s.index >= s.target.length then break
    return s.resultify results

# atLeast :: Int -> Parser t a d -> Parser t [a] d
atLeast = (n) -> (parser) ->
  new Parser (s) ->
    if s.error then return s
    state = (many parser).pf s
    return if state.result.length >= n then state
    else s.errorify "ParseError 'atLeast' (position #{s.index}): Expecting to match at least #{n} value(s), received #{state.result.length} instead"

# atLeast1 :: Parser t a d -> Parser t [a] d
atLeast1 = atLeast 1

# mapTo :: (a -> b) -> Parser t b d
mapTo = (f) ->
  new Parser (s) ->
    return if s.error then s
    else s.resultify f s.result

# errorMapTo :: ({d, String, Int} -> String) -> Parser t a d
errorMapTo = (f) ->
  new Parser (s) ->
    return unless s.error then s
    else s.errorify f s.errorProps()

###
NOTE: Here I made `char` and `anyChar` only work for strings. Maybe in the future I would allow other types of arrays.
###

# char :: Char -> Parser String Char d
char = (c) ->
  unless c and c.length is 1
    throw new TypeError "char must be called with a single character, got #{c} instead"
  return new Parser (s) ->
    unless typeof s.target is "string"
      throw new TypeError "char expects a string target, got #{typeof s.target} instead"
    if s.error then return s
    { index, target } = s
    if index < target.length
      char = target[index]
      return if char is c then s.update c, index + 1
      else s.errorify "ParseError (position #{index}): Expecting character '#{c}', got '#{char}'"
    return s.errorify "ParseError (position #{index}): Expecting character '#{c}', got end of input"

# anyChar :: Parser String Char d
anyChar = new Parser (s) ->
  unless typeof s.target is "string"
    throw new TypeError "anyChar expects a string target, got #{typeof s.target} instead"
  if s.error then return s
  { index, target } = s
  return if index < target.length then s.update target[index], index + 1
  else s.errorify "ParseError (position #{index}): Expecting character '#{target[index]}', got end of input"

# peek :: Parser
peek = new Parser (s) ->
  if s.error then return s
  { index, target } = s
  return if index < target.length then s.update target.charCodeAt(index), index + 1
  else s.errorify "ParseError (position #{index}): Unexpected end of input"

# str :: String -> Parser String String d
str = (xs) ->
  unless xs and xs.length > 0
    throw new TypeError "str must be called with a string with length > 0, got #{xs} instead"
  return new Parser (s) ->
    unless typeof s.target is "string"
      throw new TypeError "char expects a string target, got #{typeof s.target} instead"
    if s.error then return s
    { index, target } = s
    if index >= target.length
      return s.errorify "ParseError (position #{index}): Expecting string '#{xs}', got end of input"
    sai = target.slice index, index + xs.length
    return if xs is sai then s.update xs, index + xs.length
    else s.errorify "ParseError (position #{index}): Expecting string '#{xs}', got '#{sai}...'"

# regex :: RegExp -> Parser String String d
regex = (re) ->
  unless re instanceof RegExp
    throw new TypeError "regex must be called with a RegExp"
  unless re.source[0] is "^"
    throw new Error "regex parser must contain '^' start assertion"
  return new Parser (s) ->
    if s.error then return s
    { target, index } = s
    rest = target.slice index
    if rest.length < 1
      return s.errorify "ParseError (position #{index}): Expecting string matching '#{re}', got end of input"
    match = rest.match re
    return if match then s.update match[0], index + match[0].length
    else s.errorify "ParseError (position #{index}: Expecting string matching '#{re}', got '#{rest.slice 0, 5}...'"

# digit :: Parser String String d
digit = new Parser (s) ->
  if s.error then return s
  { target, index } = s
  if index >= target.length
    return s.errorify "ParseError (position #{index}): Expecting digit, got end of input"
  char = target[index]
  return if reDigit.test char then state.update char, index + 1
  else s.errorify "ParseError (position #{index}): Expecting digit, got '#{char}'"

# digits :: Parser String String d
digits = (regex reDigits).errorMap ({ index }) ->
  "ParseError (position #{index}): Expecting digits"

# letter :: Parser String String d
letter = new Parser (s) ->
  if s.error then return s
  { target, index } = s
  if index >= target.length
    return s.errorify "ParseError (position #{index}): Expecting letter, got end of input"
  char = target[index]
  return if reLetter.test char then state.update char, index + 1
  else s.errorify "ParseError (position #{index}): Expecting letter, got '#{char}'"

# letter :: Parser String String d
letter = (regex reLetters).errorMap ({ index }) ->
  "ParseError (position #{index}): Expecting letters"

# anyOfString :: String -> Parser String Char d
anyOfString = (xs) ->
  new Parser (s) ->
    if s.error then return s
    { target, index } = s
    if index >= target.length
      return s.errorify "ParseError (position #{index}): Expecting any of the string \"#{xs}\", got end of input"
    char = target[index]
    return if xs.includes char then state.update char, index + 1
    else s.errorify "ParseError (position #{index}): Expecting any of the string \"#{xs}\", got '#{char}'"

