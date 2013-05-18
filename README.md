# Stepthrough [![Build Status](https://travis-ci.org/meryn/stepthrough.png?branch=master)](https://travis-ci.org/meryn/stepthrough) [![Dependency Status](https://david-dm.org/meryn/stepthrough.png)](https://david-dm.org/meryn/stepthrough)

Write super-clean async code with promises.

## Summary

Promises work great to reduce "right-ward drift" as seen with code using regular node-style callbacks. It also eases error handling, relieving you from the necessity to check for errors after each asynchronous step.

However, I found code that goes further than merely processing return values in a chain (comparable to chaining synchronous function calls) still too noisy, and writing too cumbersome.

With Stepthrough, you can use fulfilled promises in later steps without having to call `then`, and with access to more than one "return value" without explicitly specifying variables in an outer scope up-front.

When using CoffeeScript, the resulting code looks very close to regular synchronous code blocks.

### Code example

In this example, we attempt to build some kind of email message piece by piece before sending it.

```coffee
stepthrough = require "stepthrough"

sendMail = ->
  stepthrough [
    -> @name = "Meryn Stol" # real
    -> @email = "merynstol@gmail.com" # real
    -> @subject = consoleAPI.askForLine "Message subject" # promise
    -> @body = consoleAPI.askForText "Message body" # promise
    -> @location = locationAPI.guessFriendlyName() # promise
    -> @blurp = "\n\nWritten in #{@location}" # real
    -> @body = @body + @blurp
    -> @signature = signatureAPI.signMessage @name, @email, @subject, @body
    -> @mailResult = mailAPI.send @name, @email, @subject, @body + @signature
    -> console.log "Successfully sent your message '#{@subject}' at #{@mailResult.getFriendlyTime()}."
  ]
```

## How Stepthrough works

In short, `stepthrough` steps through an array of step functions. It returns a promise which is fulfilled when all steps are completed.

A step function can get and set properties on a provided memo object. This memo object essentially takes over the role of what normally be the local function scope in typical synchronous code.

After a step function has returned, Stepthrough will do the following:

1. It inspects the current properties of the memo object. If some of these properties are promises, Stepthrough will wait until they are fullfilled.
2. If the step function returns a promise, then Stepthrough will also wait until this promise is fulfilled before continuing with the next step.

What happens next depends on whether the promises are fulfilled:

* If all promises (those set on the memo object, and the one returned, if any) are fulfilled, the memo object gets updated with the fulfiflled values and the next step function is called. If this step was the last step, then the promise returned by `stepthrough` is fulfilled.
* If any of the promises are rejected, then the step is considered to have failed, and Stepthrough won't execute any of the following steps. The promise returned by `stepthrough` is then rejected, unless a special error handler is specified.

### How it's better

1. No need to define var's up-front in an outer function context. You can set any value you want.
2. No need to think about whether the value you set is a real value or rather a promise for a value. Functions that return a promise appear in the code without any added noise, and are included without any extra effort.
3. No need to assign any fulfilled value (normally passsed to of callback to `then`) to a variable in the outer function context. This will save you one line of code for any value of promise you need to have available further down in the chain.

## Usage

```javascript
stepthrough(steps)
```

You simply call `stepthrough` with an array containing any number of functions. These functions are called in turn with the value of `memo` as both the function context (`this`) and the first argument for the function.

### Providing an initial value for the memo object

```javascript
stepthrough(initialMemo, steps)
```

Optionally, you may provide a memo object as first argument. This object will be used as the initial value for the memo object. The properties of this object will be modified. The object reference stays the same. Calling `stepthrough(steps)` is the same as calling `stepthrough({}, steps)`

### Providing an error handler

```javascript
errorHandler = function(err, memo) { 
  console.log(this) // prints final value of the memo object
  console.log(memo) // idem
  throw err 
}
stepthrough(memo, steps, errorCallback)
```

Additionally, you may provide an error handler function as last argument. This error handler has access to the final version of the memo object. This is useful when you want to do any cleanup, for example closing file-descriptors or rolling back a transaction. Essentially, this function as the `catch` clause of a `try...catch` block.

If the error handler does not throw an error, the promise returned by `stepthrough` will be fulfilled anyway.

## Credits

The initial structure of this module was generated by [Jumpstart](https://github.com/meryn/jumpstart), using the [Jumpstart Black Coffee](https://github.com/meryn/jumpstart-black-coffee) template.

## License

stepthrough is released under the [MIT License](http://opensource.org/licenses/MIT).  
Copyright (c) 2013 Meryn Stol  