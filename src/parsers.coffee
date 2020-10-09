Parser = require "./Parser"

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

# tap :: (a -> IO ()) -> Parser t a d
tap = (f) ->
  new Parser (s) ->
    f s
    return s

