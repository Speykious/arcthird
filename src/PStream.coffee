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
  next: ->
    return if @index < @length()
    then @elementAt @index++
    else null
  
  # nexts :: Int -> [a]
  nexts: (n) ->
    start = @index
    nels = []
    while @index - start < n and @index < @length()
      nels.push @next()
    return nels

  
module.exports = PStream
