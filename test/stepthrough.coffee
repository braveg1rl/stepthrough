require("mocha-as-promised")()

assert = require "assert"
faithful = require "faithful"

stepthrough = require "../"

testValues =
  author: "Meryn Stol"
  date: new Date
  location: "The Hague"
  subject: "Testing memo behavior"
  testNumber: 123
  signature: "Signed by HyperTrust Secure Message Verification Service. Really. Trust us."
  body: "Message authoring outsourced to Mechanicul Turk. Laziness is a virtue."

describe "stepthrough", ->
  describe "when I don't provide any functions", ->
    it "returns a promise for an empty object", ->
      stepthrough([]).then (memo) -> assert.deepEqual memo, {}
  describe "when I provide an initial value for the memo", ->
    it "returns an object that is exactly this object", ->
      theMemo = abc:"def"
      stepthrough(theMemo,[]).then (memo) -> assert.equal memo, theMemo
  describe "when I provide some functions that set some values", ->
    it "makes them available to the next function", ->
      stepthrough [
        ->
          @location = testValues.location
          @subject = testValues.subject
        (memo) ->
          assert.equal @location, testValues.location
          assert.equal memo.subject, testValues.subject
        ]
    it "immediately makes this value available", ->
      stepthrough [
        ->
          @location = testValues.location
          @subject = testValues.subject
        ->
          @date = faithful.return testValues.date
          @author = testValues.author
          @testNumber = faithful.return testValues.testNumber
        ->
          @body = faithful.return testValues.body
          @signature = faithful.return testValues.signature
        (memo) ->
          assert.deepEqual memo, testValues
          assert.deepEqual @, testValues
          assert.equal @location, testValues.location
          assert.equal @subject, testValues.subject
          assert.equal @body, testValues.body
          assert.equal @signature, testValues.signature
        ]
  describe "when one of the provided functions returns a failed promise", ->
    it "fails with the rejection reason", ->
      stepthrough([
        -> @location = testValues.location
        -> @subject = testValues.subject
        -> @date = faithful.return testValues.date  
        -> @author = testValues.author  
        -> @testNumber = faithful.return testValues.testNumber
        -> @body = faithful.fail new Error "no body today"
        -> @signature = faithful.return testValues.signature
      ]).then null, (err) -> 
        assert.equal err.toString(), "Error: no body today"
  describe "when one of the provided functions throws an error", ->
    it "fails with the error thrown", ->
      stepthrough([
        -> @location = testValues.location
        -> @subject = testValues.subject
        -> @date = faithful.return testValues.date  
        -> @author = testValues.author  
        -> @testNumber = faithful.return testValues.testNumber
        -> throw new Error "no body today"
        -> @signature = faithful.return testValues.signature
      ]).then null, (err) -> 
        assert.equal err.toString(), "Error: no body today"
    it "calls the error callback with memo as context, plus error thrown and memo as arguments", ->
      cbCalled = false
      errorCallback = (err, memo) -> 
        cbCalled = true
        assert.equal @, memo
        assert.equal @location, testValues.location
        assert.equal @date, testValues.date
        assert.equal @signature, undefined
        assert.equal err.toString(), "Error: no body today"
      stepthrough([
        -> @location = testValues.location
        -> @subject = testValues.subject
        -> @date = faithful.return testValues.date
        -> @author = testValues.author  
        -> @testNumber = faithful.return testValues.testNumber
        -> throw new Error "no body today"
        -> @signature = faithful.return testValues.signature
      ],errorCallback).then -> assert cbCalled