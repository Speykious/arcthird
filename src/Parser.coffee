ParserState = require "./ParserState"

class Parser
  # Parser :: PStream t => (ParserState t * d -> ParserState t a d) -> Parser t a d
  constructor: (@pf) ->

  # parse :: PStream t => Parser t a d ~> t -> ParserState t a d
  parse: (target) -> @pf new ParserState { target }

  # fork :: PStream t => Parser t a d ~> (t, (ParserState t a d -> x), (ParserState t a d -> y)) -> (Either x y)
  fork: (target, errf, succf) ->
    state = @pf new ParserState { target }
    return (if state.isError then errf else succf) state

  # map :: PStream t => Parser t a d ~> (a -> b) -> Parser t b d
  map: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return if state.isError then state
      else state.resultify f state.result
  
  # chain :: PStream t => Parser t a d ~> (a -> Parser t b d) -> Parser t b d
  chain: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return if state.isError then state
      else (f state.result).pf state
  
  # ap :: PStream t => Parser t a d ~> Parser t (a -> b) d -> Parser t b d
  ap: (poff) ->
    pf = @pf
    return new Parser (s) ->
      if s.isError then return s
      argstate = pf s
      if argstate.isError then return argstate
      fnstate = poff.pf argstate
      if fnstate.isError then return fnstate
      return fnstate.resultify fnstate.result argstate.result
  
  # errorMap :: PStream t => Parser t a d ~> ({d, String, Int} -> String) -> Parser t a d
  errorMap: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return unless state.isError then state
      else state.errorify f state.errorProps()
    
  # errorChain :: PStream t => Parser t a d ~> ({d, String, Int} -> Parser t a d) -> Parser t a d
  errorChain: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return unless state.isError then state
      else (f state.errorProps()).pf state
  
  # mapFromData :: PStream t => Parser t a d ~> ({a, d} -> b) -> Parser t b d
  mapFromData: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return if state.isError then state
      else state.resultify f state.dataProps()

  # chainFromData :: PStream t => Parser t a d ~> ({a, d} -> Parser t b e) -> Parser t b e
  chainFromData: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return if state.isError then state
      else (f state.dataProps()).pf state

  # mapData :: PStream t => Parser t a d ~> (d -> e) -> Parser t a e
  mapData: (f) ->
    pf = @pf
    return new Parser (s) ->
      state = pf s
      return state.dataify f state.data

  # of :: PStream t => Parser t a d ~> x -> Parser t x d
  @of: (x) -> new Parser (s) -> s.resultify(x)

module.exports = Parser
