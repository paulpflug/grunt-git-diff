chai = require "chai"
chai.should()

gitdiff = require "../src/gitdiff"
lib = require "../src/lib/gitdiff-lib"
readable = require('stream').Readable;
class stdmock extends readable
  constructor: (opts) ->
    readable.call(this,opts)
  _read: () ->

file = "filename"
unchangedFile = "someotherfile"
unchangedFileDestination = "someotherfileDestination"
unchangedgruntfiles = [{src:[unchangedFile],dest:unchangedFileDestination}]
filecontent = """
p.
  test
  test
  test
  test
  test
  test
"""
diff = """
diff --git filename
index
--- filename
+++ filename
@@ -1,7 +1,7 @@\n
"""
hunk = """
p.
  test
  test
-  test
+  test2
  test
  test
  test
"""
mockupfiles = {}
mockupfiles[file] = filecontent
gruntfiles = [{src:[file],dest:file}]
class gruntMock 
  _doneCalled = false
  done: () ->
    _doneCalled = true
  doneCalled: () ->
    return _doneCalled
  _mockupfiles = undefined
  _failwarn = ""
  _results = ""
  _copydest = ""
  copydest: () -> return _copydest
  results: () -> return _results
  options: () -> return _options
  _options = {}
  async: () ->
    return @done
  constructor: (files,mockupfiles,options,done) ->
    if done
      _options = options
    else
      done = options
    @done = done
    @files = files
    _mockupfiles = mockupfiles
    @mockupfiles = mockupfiles
  registerMultiTask: (str1,str2,cb) ->
    @task = cb
  log:
    write: (str) ->
    ok: (str) ->
  fail:
    warn: (str) ->
      _failwarn = str
  file:
    read: (file) ->
      return _mockupfiles[file]
    write: (str1,str2) ->
      console.log "write"
      _results = str2
    copy: (str1,str2) ->
      _copydest = str2
class simpleGit
  mockobj = {
    cb: undefined
    outputcb: undefined
    diff: (str,cb) ->
      this.cb = cb
    outputHandler: (outputcb) ->
      this.outputcb = outputcb
      return this
  }
  mockobj: mockobj
  mock: () ->
    return mockobj

describe "Grunt task", ->

  it "should work with the mockups", () ->
    git = new simpleGit()  
    grunt = new gruntMock(gruntfiles,mockupfiles)
    gitdiff(grunt,git.mock)
    grunt.task.should.be.a("function")
    grunt.task.call(grunt)
    git.mockobj.outputcb.should.be.a("function")
  it "should return on git error", (done) ->
    d = done
    stdout = new stdmock()
    stderr = new stdmock()
    git = new simpleGit()  
    grunt = new gruntMock gruntfiles,mockupfiles, () ->
      true.should.be.true
      d()
    gitdiff(grunt,git.mock)
    grunt.task.call(grunt)
    git.mockobj.outputcb("",stdout,stderr)
    stderr.push("err")
  it "should copy over unchanged files", (done) ->
    d = done
    stdout = new stdmock()
    stderr = new stdmock()
    git = new simpleGit()  
    grunt = new gruntMock unchangedgruntfiles,mockupfiles, () ->
      grunt.copydest().should.equal(unchangedFileDestination)
      d()
    gitdiff(grunt,git.mock)
    grunt.task.call(grunt)
    git.mockobj.outputcb("",stdout,stderr)
    stdout.push(diff+hunk)
    stdout.emit "close"
  it "should produce the right results", (done) ->
    d = done
    stdout = new stdmock()
    stderr = new stdmock()
    git = new simpleGit()  
    grunt = new gruntMock gruntfiles,mockupfiles,{trimFirstWhitespace:false}, () ->
      results = grunt.results()

      parsed = lib.test.parseJade(hunk.split("\n"),"",lib.getOptions())
      grunt.results().should.equal(parsed.join("\n"))
      d()
    gitdiff(grunt,git.mock)
    grunt.task.call(grunt)
    git.mockobj.outputcb("",stdout,stderr)
    stdout.push(diff+hunk)
    stdout.push(null)