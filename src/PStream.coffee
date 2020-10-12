# class PStream a
class PStream
  constructor: (@structure) ->
    @index = 0

  # length :: () -> Int
  length: ->
    throw new Error "The 'length' function has not been implemented"
  
  # elementAt :: Int -> a
  elementAt: (i) ->
    throw new Error "The 'next' function has not been implemented"
  
  # next :: () -> a
  next: -> @elementAt @index++
  
module.exports = PStream