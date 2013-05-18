{isPromise,collect,makePromise} = require "faithful"
  
module.exports = stepThrough = ->
  if arguments[0] instanceof Array
    memo = {}
    steps = arguments[0]
    errorCallback = arguments[1]
  else if arguments[1] instanceof Array
    memo = arguments[0]
    steps = arguments[1]
    errorCallback = arguments[2]
  else
    throw new Error "Invalid arguments"
  trySteps(memo, steps).then null, (err) ->
    if errorCallback? then errorCallback.call memo, err, memo else throw err

trySteps = (memo, steps) ->
  i = -1
  iterate = undefined
  copyAndIterate = (m) -> 
    copyProperties m, memo
    iterate()
  makePromise (cb) ->
    iterate = ->
      i++
      return cb null, memo if i >= steps.length
      try r = steps[i].call memo, memo catch error then return cb error
      if containsPromises memo
        if (isPromise r) and not (isPropertyOf r, memo)
          r.then(-> collect memo).then copyAndIterate, cb
        else
          collect(memo).then copyAndIterate, cb
      else
        if (isPromise r)
          r.then iterate, cb
        else
          iterate()
    iterate()
    
containsPromises = (obj) ->
  return true for name, value of obj when isPromise value
  return false

isPropertyOf = (subject, obj) ->
 return true for name, value of obj when value is subject
 return false

copyProperties = (sourceObject, targetObject) ->
  targetObject[name] = value for name, value of sourceObject