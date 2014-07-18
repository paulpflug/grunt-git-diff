chai = require "chai"
chai.should()

lib = require "../src/lib/gitdiff-lib"
parseJade = lib.test.parseJade
getTagFromJadeString = lib.test.getTagFromJadeString
options = lib.getOptions()
blockhunk = """
            p.
              test
              test
            """
envblockhunk = "  test\n  test\n  test"
                
pipedhunk = """
            p
              | test
              | test
            """
simplehunk = """
            p test
            p test
            p test
            """
hunk = (line,envhunk) ->
  if line instanceof Array
    line = line.join("\n")
  envhunk = simplehunk if not envhunk
  str = envhunk+"\n"+line+"\n"+envhunk
  return str.split("\n")
tagjoin = (tag) ->
  return tag.join(" ")
describe "Jade tag extractor", ->
  it "should work with a simple tag", ->
    tag = ["h3", "test"]
    result = getTagFromJadeString(tagjoin(tag))
    result[0].should.equal tag[0]
    result[1].should.equal tag[1]
  it "should work without content", ->
    tag = "h3"
    result = getTagFromJadeString(tag)
    result[0].should.equal tag
    result[1].should.equal ""
  it "should work with a div", ->
    tag = ["#test", "test"]
    result = getTagFromJadeString(tagjoin(tag))
    result[0].should.equal tag[0]
    result[1].should.equal tag[1]
    tag = [".test", "test"]
    result = getTagFromJadeString(tagjoin(tag))
    result[0].should.equal tag[0]
    result[1].should.equal tag[1]
  it "should work with a class", ->
    tag = ["h3.test", "test"]
    result = getTagFromJadeString(tagjoin(tag))
    result[0].should.equal tag[0]
    result[1].should.equal tag[1]
  it "should work with a simple attribute", ->
    tag = ["h3(attribute)", "test"]
    result = getTagFromJadeString(tagjoin(tag))
    result[0].should.equal tag[0]
    result[1].should.equal tag[1]
  it "should work with a complex attribute", ->
    tag = ["h3(style='color: red')", "test"]
    result = getTagFromJadeString(tagjoin(tag))
    result[0].should.equal tag[0]
    result[1].should.equal tag[1]

describe "Jade parsing", ->
  it "should work with changing a line", ->
    environment = ""
    line =  ["-h3 old line","+h3 new line"]
    parsed = parseJade(hunk(line),environment,options)
    tag0 = getTagFromJadeString(line[0].substr(1))
    tag1 = getTagFromJadeString(line[1].substr(1))
    parsed[3].should.equal tag0[0]+" #["+ options.prependminus+tag0[1]+"]"
    parsed[4].should.equal tag1[0]+" #["+ options.prependplus+tag1[1]+"]"
  it "should work with changing a line in a block", ->
    environment = ""
    line =  ["-  old line","+  new line"]
    parsed = parseJade(hunk(line,blockhunk),environment,options)
    parsed[3].should.equal "  #["+options.prependminus+line[0].substr(3)+"]"
    parsed[4].should.equal "  #["+options.prependplus+line[1].substr(3)+"]"
  it "should work with changing an inline string in a block", ->
    environment = ""
    line =  ["-  #[span old line]","+  #[span new line]"]
    parsed = parseJade(hunk(line,blockhunk),environment,options)
    parsed[3].should.equal "  #["+options.prependminus+line[0].substr(3)+"]"
    parsed[4].should.equal "  #["+options.prependplus+line[1].substr(3)+"]"
  it "should work with changing a line within a block environment", ->
    environment = "p."
    line =  ["-  h3 old line","+  h3 new line"]
    parsed = parseJade(hunk(line,envblockhunk),environment,options)
    parsed[3].should.equal "  #[" + options.prependminus+line[0].substr(3)+"]"
    parsed[4].should.equal "  #[" + options.prependplus+line[1].substr(3)+"]"
  it "should work with changing a line in a piped block", ->
    environment = ""
    line =  ["-  | old line","+  | new line"]
    parsed = parseJade(hunk(line,pipedhunk),environment,options)
    parsed[3].should.equal "  | #["+options.prependminus+line[0].substr(5)+"]"
    parsed[4].should.equal "  | #["+options.prependplus+line[1].substr(5)+"]"
  it "should work with changing an inline string in a piped block", ->
    environment = ""
    line =  ["-  | #[span old line]","+  | #[span old line]"]
    parsed = parseJade(hunk(line,pipedhunk),environment,options)
    parsed[3].should.equal "  | #["+options.prependminus+line[0].substr(5)+"]"
    parsed[4].should.equal "  | #["+options.prependplus+line[1].substr(5)+"]"
  it "should work with changing a nested line", ->
    environment = ""
    line =  ["-  h3 old line","+  h3 new line"]
    parsed = parseJade(hunk(line),environment,options)
    tag0 = getTagFromJadeString(line[0].substr(1))
    tag1 = getTagFromJadeString(line[1].substr(1))
    parsed[3].should.equal "  "+ tag0[0]+" #["+ options.prependminus+tag0[1]+"]"
    parsed[4].should.equal "  "+ tag1[0]+" #["+ options.prependplus+tag1[1]+"]"
  
  it "should work with changing several lines", ->
    environment = ""
    line =  ["-h3 old line","-p test","+h3 new line","+p test2"]
    parsed = parseJade(hunk(line),environment,options)
    tag0 = getTagFromJadeString(line[0].substr(1))
    tag1 = getTagFromJadeString(line[1].substr(1))
    tag2 = getTagFromJadeString(line[2].substr(1))
    tag3 = getTagFromJadeString(line[3].substr(1))
    parsed[3].should.equal tag0[0]+" #["+ options.prependminus+tag0[1]+"]"
    parsed[4].should.equal tag1[0]+" #["+ options.prependminus+tag1[1]+"]"
    parsed[5].should.equal tag2[0]+" #["+ options.prependplus+tag2[1]+"]"
    parsed[6].should.equal tag3[0]+" #["+ options.prependplus+tag3[1]+"]"

  it "should work with a new block", ->
    environment = ""
    line =  ["+p.","+  test"]
    parsed = parseJade(hunk(line),environment,options)
    parsed[3].should.equal line[0].substr(1)
    parsed[4].should.equal "  #["+options.prependplus+line[1].substr(3)+"]"

  it "should ignore keywords", ->
    environment = ""
    line =  ["+html","+  head","+  body"]
    parsed = parseJade(hunk(line),environment,options)
    parsed[3].should.equal line[0].substr(1)
    parsed[4].should.equal line[1].substr(1)
    parsed[5].should.equal line[2].substr(1)

