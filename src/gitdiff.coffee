_ = require "lodash"
lib = require "./lib/gitdiff-lib"
byline = require "byline"
module.exports = (grunt, simpleGit) ->
  simpleGit = require "simple-git" if not simpleGit
  grunt.registerMultiTask "gitdiff", "Extracts the git diff" , () ->
    options = this.options()
    options = lib.getOptions(options)
    hunkregex = new RegExp(options.hunkregex)
    self = this
    done = self.async()
    git = simpleGit()
    git.outputHandler (command,stdout,stderr) ->
      stderr.on "data", (data) ->
        err = data.toString('utf-8')
        if err 
          grunt.fail.warn("\n\ngit diff failed\n"+err+"\n\n")
          done()
      foundfiles = []
      current = {
        file: undefined
        dest: undefined
        changes: []
        process: () ->
          if this.file and this.dest
            data = grunt.file.read(this.file).split("\n")
            hunkindex = 3
            while hunkindex != -1
              hunk = this.changes[hunkindex].match(hunkregex)
              this.changes.splice(0,hunkindex+1)
              hunkindex = _.findIndex(this.changes, (str) ->
                str.search(hunkregex) > -1
                )             
              length = hunkindex
              if length == -1
                length = this.changes.length
              env = ""
              if hunk[5] 
                env = hunk[5].trim()
              newdata = options.cb(this.changes.slice(0,length),env,options).join("\n")
              data.splice(+(hunk[3])-1,hunk[2],newdata)
            grunt.file.write(this.dest,data.join("\n"))
      }
      stream = byline(stdout,{encoding:'utf8'})
      stream.on "data", (line) ->
        if line.search(/diff --git/) > -1
          current.process()
          current.file = undefined
          self.files.forEach (array) ->          
            array.src.forEach (file) ->
              if line.indexOf(file) > -1
                grunt.log.ok "found change in "+file
                current.file = file
                current.dest = array.dest
                foundfiles.push(file)
          current.changes = []
        else if current.file
          if line.charCodeAt(0) == 32 and options.trimFirstWhitespace
            current.changes.push(line.substr(1))
          else
            current.changes.push(line)
      finished = false
      finish = () ->
        if not finished
          current.process()
          self.files.forEach (array) -> 
            array.src.forEach (file) ->
              if foundfiles.indexOf(file) == -1
                grunt.log.ok "copying "+file
                grunt.file.copy(file,array.dest)
          done()
        finish = true
      stdout.on "end", finish
      stdout.on "close" , finish
    .diff ""