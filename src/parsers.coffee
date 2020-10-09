Parser                 = require "./Parser"
{ reErrorExpectation } = require "./constants"

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

# errorMapTo :: (ParserState t a d -> String) -> Parser t a d
errorMapTo = (f) ->
  new Parser (s) ->
    return unless s.error then s
    else s.errorify f s