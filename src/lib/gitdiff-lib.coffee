_ = require "lodash"
getTagFromJadeString = (string) ->
  j = 0
  tag = ""
  started = false
  inBracket = false
  inString = false
  while j < string.length
    if string[j].search(/\S/) > -1 or inString
      tag = tag+string[j]
      started = true
    if not inString and string[j].search(/(["'])/) > -1
      inString = string[j].match(/(["'])/)[0]
    else if inString and string[j].search(inString) > -1
      inString = false
    if not inBracket and not inString and string[j].search(/\(/) > -1
      inBracket = true
    else if inBracket and string[j].search(/\)/) > -1
      inBracket = false
    if started and not inBracket and not inString and string[j].search(/\s/) > -1
      break
    j++
  if j+1 >= string.length
    string = ""
  else
    string = string.substr(j+1)
  return [tag,string]
parseJade = (hunk, environment, options) ->
    keywords = ["html","head","meta","link","body","include","doctype", "//","\\-","mixin","\\+","img","figure","blockquote"]
    empty = /\s*\s$/
    env = /\w+\.$/
    environments = []
    environments.push environment if environment
    lastws = -1
    j = 0
    while j < hunk.length
      str = hunk[j]
      switch str[0]
        when "-" 
          str = str.substr(1)   
          prepend = options.prependminus             
        when "+" 
          str = str.substr(1) 
          prepend = options.prependplus
        else
          prepend = false
      if str.search(empty) == -1
        whitespace = str.match(/(^\s+)\S+/)
        if whitespace
          whitespace = whitespace[1].length
        else
          whitespace = 0
        if lastws> -1
          if whitespace > lastws
            environments.push hunk[j-1]
          else if whitespace < lastws
            environments.pop()
        if prepend
          keyword = false
          for k in keywords
            if str.search(new RegExp("\s*"+k)) != -1
              keyword = true
              break;
          if str.search(env) != -1
            keyword = true
          if not keyword
            ws = str.substr(0,whitespace)
            string = str.substr(whitespace)  
            if string[0] == "|"
              str = ws + "| #["+prepend + string.substr(2)+"]"
            else if environments.length > 0 and environments[environments.length-1].search(env) != -1
              str = ws + "#["+prepend + string+"]"
            else
              tag = getTagFromJadeString(string)
              str = ws + tag[0]
              if tag[1]
                str = str + " #["+ prepend + tag[1]+"]"
        lastws = whitespace
      if prepend
        hunk[j] = str
      j++
    return hunk
options = {
  options:
    hunkregex: /@@ \-(\d+),(\d+) \+(\d+),(\d+) @@([\s\S]*)/
    parser: "jade"
  jade:
    options:
      prependplus: "span(style='color:blue') "
      prependminus: "span(style='color:red') " 
      cb: parseJade
}
module.exports = {
  getOptions: (setOptions) ->
    setOptions = {} if not setOptions
    _.defaults(setOptions,options.options)
    _.defaults(setOptions, options[setOptions.parser].options)
    return setOptions
  
  test:
    getTagFromJadeString: getTagFromJadeString
    parseJade: parseJade
}