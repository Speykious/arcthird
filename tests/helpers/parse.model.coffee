# { inspect } = require "util"
Parser = require "../../src/Parser"

module.exports = (chai, utils) ->
  Assertion = chai.Assertion
  
  Assertion.addMethod "parse", (target) ->
    obj = this._obj
    (new Assertion obj).to.be.an.instanceof Parser
    state = obj.parse target
    this.assert(
      state.isError is false
      "expected parser to parse #{utils.inspect target, false, 4}"
      "expected parser not to parse #{utils.inspect target, false, 4}"
    )
  
  Assertion.addMethod "haveParseError", (target, error) ->
    obj = this._obj
    state = obj.parse target
    this.assert(
      state.error is error
      "expected parser to have error \#{exp}, got \#{act}"
      "expected parser to not have error \#{act}"
      error
      state.error
    )