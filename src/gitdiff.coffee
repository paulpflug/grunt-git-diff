_ = require "lodash"
lib = require "./lib/gitdiff-lib"

module.exports = (grunt, simpleGit) ->
  simpleGit = require "simple-git" if not simpleGit
  grunt.registerMultiTask "gitdiff", "Extracts the git diff" , () ->
    options = this.options()
    options = lib.getOptions(options)
    hunkregex = new RegExp(options.hunkregex)
    self = this
    done = self.async()
    git = simpleGit()
    git.diff "",(err,content) ->    
      if err 
        grunt.fail.warn("\n\ngit diff failed\n"+err+"\n\n")
        done()
        return
      contents = content.split("\n")      
      index = 0
      foundfiles = []
      while index > -1
        filename = contents[index]
        contents.splice(0,index+1)
        index = _.findIndex(contents, (str) ->
          str.search(/diff --git/) > -1
          )       
        self.files.forEach (array) ->          
          array.src.forEach (file) ->
            if filename.indexOf(file) > -1
              grunt.log.ok "found change in "+file
              foundfiles.push(file)
              data = grunt.file.read(file).split("\n")
              hunkindex = 3
              while hunkindex != -1 && (hunkindex < index || index == -1)
                hunk = contents[hunkindex].match(hunkregex)
                contents.splice(0,hunkindex+1)

                index = index - hunkindex - 1
                hunkindex = _.findIndex(contents, (str) ->
                  str.search(hunkregex) > -1
                  )             
                length = hunkindex
                if index > -1 && (length == -1 || index < hunkindex)
                  length = index
                if length == -1
                  length = contents.length
                env = ""
                if hunk[5] 
                  env = hunk[5].trim()
                newdata = options.cb(contents.slice(0,length),env,options).join("\n")
                data.splice(+(hunk[3])-1,hunk[2],newdata)
              grunt.file.write(array.dest,data.join("\n"))
      self.files.forEach (array) -> 
        array.src.forEach (file) ->
          if foundfiles.indexOf(file) == -1
            grunt.file.copy(file,array.dest)
      done()
    
