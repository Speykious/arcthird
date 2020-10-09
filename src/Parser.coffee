class Parser
  # Parser :: Iterable t => (ParserState t * d -> ParserState t a d) -> Parser t a d
  constructor: (@pf) ->

  # parse :: Iterable t => Parser t a d ~> t -> ParserState t a d
  parse: (target) -> @pf new ParserState { target }

  # fork :: Iterable t => Parser t a d ~> (t, (ParserState t a d -> x), (ParserState t a d -> y)) -> (Either x y)
  fork: (target, errf, succf) ->
    state = @pf new ParserState { target }
    return (if state.error then errf else succf) state

  # map :: Iterable t => Parser t a d ~> (a -> b) -> Parser t b d
  map: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return if state.error then state
      else state.resultify f state.result
  
  # chain :: Iterable t -> Parser t a d ~> (a -> Parser t b d) -> Parser t b d
  chain: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return if state.error then state
      else (f state.result).pf state
  
  # ap :: Iterable t -> Parser t a d ~> Parser t (a -> b) d -> Parser t b d
  ap: (poff) ->
    pf = @pf
    return new Parser (s) ->
      if s.error then return s
      argstate = pf s
      if argstate.error then return argstate
      fnstate = poff.pf argstate
      if fnstate.error then return fnstate
      return fnstate.resultify fnstate.result argstate.result
  
  # errorMap :: Iterable t => Parser t a d ~> ({d, String, Int} -> String) -> Parser t a d
  errorMap: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return unless state.error then state
      else state.errorify f state.errorProps()
    
  # errorChain :: Iterable t => Parser t a d ~> ({d, String, Int} -> Parser t a d) -> Parser t a d
  errorChain: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return unless state.error then state
      else (f state.errorProps()).pf state
  
  # mapFromData :: Iterable t => Parser t a d ~> ({a, d} -> b) -> Parser t b d
  mapFromData: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return if state.error then state
      else state.resultify f state.dataProps()

  # chainFromData :: Iterable t => Parser t a d ~> ({a, d} -> Parser t b e) -> Parser t b e
  chainFromData: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return if state.error then state
      else (f state.dataProps()).pf state

  # mapData :: Iterable t => Parser t a d ~> (d -> e) -> Parser t a e
  mapData: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return state.dataify f state.data

  # of :: Iterable t => Parser t a d ~> x -> Parser t x d
  @of: (x) -> new Parser (s) -> s.resultify(x)

module.exports = Parser