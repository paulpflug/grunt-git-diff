(function() {
  var byline, lib, _;

  _ = require("lodash");

  lib = require("./lib/gitdiff-lib");

  byline = require("byline");

  module.exports = function(grunt, simpleGit) {
    if (!simpleGit) {
      simpleGit = require("simple-git");
    }
    return grunt.registerMultiTask("gitdiff", "Extracts the git diff", function() {
      var done, git, hunkregex, options, self;
      options = this.options();
      options = lib.getOptions(options);
      hunkregex = new RegExp(options.hunkregex);
      self = this;
      done = self.async();
      git = simpleGit();
      return git.outputHandler(function(command, stdout, stderr) {
        var current, finish, finished, foundfiles, stream;
        stderr.on("data", function(data) {
          var err;
          err = data.toString('utf-8');
          if (err) {
            grunt.fail.warn("\n\ngit diff failed\n" + err + "\n\n");
            return done();
          }
        });
        foundfiles = [];
        current = {
          file: void 0,
          dest: void 0,
          changes: [],
          process: function() {
            var data, env, hunk, hunkindex, length, newdata;
            if (this.file && this.dest) {
              data = grunt.file.read(this.file).split("\n");
              hunkindex = 3;
              while (hunkindex !== -1) {
                hunk = this.changes[hunkindex].match(hunkregex);
                this.changes.splice(0, hunkindex + 1);
                hunkindex = _.findIndex(this.changes, function(str) {
                  return str.search(hunkregex) > -1;
                });
                length = hunkindex;
                if (length === -1) {
                  length = this.changes.length;
                }
                env = "";
                if (hunk[5]) {
                  env = hunk[5].trim();
                }
                newdata = options.cb(this.changes.slice(0, length), env, options).join("\n");
                data.splice(+hunk[3] - 1, hunk[2], newdata);
              }
              return grunt.file.write(this.dest, data.join("\n"));
            }
          }
        };
        stream = byline(stdout, {
          encoding: 'utf8'
        });
        stream.on("data", function(line) {
          if (line.search(/diff --git/) > -1) {
            current.process();
            current.file = void 0;
            self.files.forEach(function(array) {
              return array.src.forEach(function(file) {
                if (line.indexOf(file) > -1) {
                  grunt.log.ok("found change in " + file);
                  current.file = file;
                  current.dest = array.dest;
                  return foundfiles.push(file);
                }
              });
            });
            return current.changes = [];
          } else if (current.file) {
            if (line.charCodeAt(0) === 32 && options.trimFirstWhitespace) {
              return current.changes.push(line.substr(1));
            } else {
              return current.changes.push(line);
            }
          }
        });
        finished = false;
        finish = function() {
          if (!finished) {
            current.process();
            self.files.forEach(function(array) {
              return array.src.forEach(function(file) {
                if (foundfiles.indexOf(file) === -1) {
                  grunt.log.ok("copying " + file);
                  return grunt.file.copy(file, array.dest);
                }
              });
            });
            done();
          }
          return finish = true;
        };
        stdout.on("end", finish);
        return stdout.on("close", finish);
      }).diff("");
    });
  };

}).call(this);
