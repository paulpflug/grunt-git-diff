_ = require "lodash"
simpleGit = require "simple-git"
module.exports = (grunt) ->
  grunt.registerMultiTask "gitdiff", "Extracts the git diff" , () ->
    options = this.options()
    _.defaults(options, {
      hunkregex: /@@ \-(\d+),(\d+) \+(\d+),(\d+) @@/
      prependplus: "<span style='color:blue'>" 
      prependminus: "<span style='color:red'>"
      append: "</span>"
      cb: (string, prepend, append) ->
        return prepend+string+append
      })
    self = this
    done = self.async()
    git = simpleGit()
    git.diff "",(err,content) ->      
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
              console.log "found change in "+file
              foundfiles.push(file)
              data = grunt.file.read(file).split("\n")
              hunkindex = 3
              while hunkindex != -1 && (hunkindex < index || index == -1)
                hunk = contents[hunkindex].match(options.hunkregex)
                contents.splice(0,hunkindex+1)

                index = index - hunkindex - 1
                hunkindex = _.findIndex(contents, (str) ->
                  str.search(options.hunkregex) > -1
                  )             
                length = hunkindex
                if index > -1 && (length == -1 || index < hunkindex)
                  length = index
                if length == -1
                  length = contents.length
                dataindex = +(hunk[3])-1
                j = 0
                while j < length
                  switch contents[j][0]
                    when "-" 
                      data.splice(dataindex+j,0,options.cb(contents[j].substr(1),options.prependminus,options.append))                 
                    when "+" 
                      data.splice(dataindex+j,1,options.cb(contents[j].substr(1),options.prependplus,options.append))
                  j++
              grunt.file.write(array.dest,data.join("\n"))
      self.files.forEach (array) -> 
        array.src.forEach (file) ->
          if foundfiles.indexOf(file) == -1
            console.log file
            grunt.file.copy(file,array.dest)
      done()
    options = this.options()
    
