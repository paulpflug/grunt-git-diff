chai = require "chai"
chai.should()

gitdiff = require "../src/gitdiff"
lib = require "../src/lib/gitdiff-lib"
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
  options: () -> return {}
  async: () ->
    return @done
  constructor: (files,mockupfiles) ->
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
      _results = str2
    copy: (str1,str2) ->
      _copydest = str2
class simpleGit
  mockobj = {
    cb: undefined
    diff: (str,cb) ->
      this.cb = cb
  }
  mockobj: mockobj
  mock: () ->
    return mockobj

describe "Grunt task", ->
  file = "filename"
  unchangedFile = "someotherfile"
  unchangedFileDestination = "someotherfileDestination"
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
  gruntfiles = [{src:[file],dest:""}]
  unchangedgruntfiles = [{src:[unchangedFile],dest:unchangedFileDestination}]
  it "should work with the mockups", () ->
    git = new simpleGit()  
    grunt = new gruntMock(gruntfiles,mockupfiles)
    gitdiff(grunt,git.mock)
    grunt.task.should.be.a("function")
    grunt.task.call(grunt)
    git.mockobj.cb.should.be.a("function")
  it "should return on git error", () ->
    git = new simpleGit()  
    grunt = new gruntMock(gruntfiles,mockupfiles)
    gitdiff(grunt,git.mock)
    grunt.task.call(grunt)
    git.mockobj.cb("err")
    grunt.doneCalled().should.be.true
  it "should copy over unchanged files", () ->
    git = new simpleGit()  
    grunt = new gruntMock(unchangedgruntfiles,mockupfiles)
    gitdiff(grunt,git.mock)
    grunt.task.call(grunt)
    git.mockobj.cb(false,diff)
    grunt.copydest().should.equal(unchangedFileDestination)
  it "should produce the right results", () ->
    git = new simpleGit()  
    grunt = new gruntMock(gruntfiles,mockupfiles)
    gitdiff(grunt,git.mock)
    grunt.task.call(grunt)
    git.mockobj.cb(false,diff+hunk)
    results = grunt.results()
    parsed = lib.test.parseJade(hunk.split("\n"),"",lib.getOptions())
    grunt.results().should.equal(parsed.join("\n"))