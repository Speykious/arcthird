isIterable = (o) ->
  # checks for null and undefined
  if o is null or o is undefined then false
  else typeof o[Symbol.iterator] is 'function'

module.exports = {
  isIterable
}