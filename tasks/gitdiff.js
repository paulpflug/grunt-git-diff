(function() {
  var lib, _;

  _ = require("lodash");

  lib = require("./lib/gitdiff-lib");

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
      return git.diff("", function(err, content) {
        var contents, filename, foundfiles, index;
        if (err) {
          grunt.fail.warn("\n\ngit diff failed\n" + err + "\n\n");
          done();
          return;
        }
        contents = content.split("\n");
        index = 0;
        foundfiles = [];
        while (index > -1) {
          filename = contents[index];
          contents.splice(0, index + 1);
          index = _.findIndex(contents, function(str) {
            return str.search(/diff --git/) > -1;
          });
          self.files.forEach(function(array) {
            return array.src.forEach(function(file) {
              var data, env, hunk, hunkindex, length, newdata;
              if (filename.indexOf(file) > -1) {
                grunt.log.ok("found change in " + file);
                foundfiles.push(file);
                data = grunt.file.read(file).split("\n");
                hunkindex = 3;
                while (hunkindex !== -1 && (hunkindex < index || index === -1)) {
                  hunk = contents[hunkindex].match(hunkregex);
                  contents.splice(0, hunkindex + 1);
                  index = index - hunkindex - 1;
                  hunkindex = _.findIndex(contents, function(str) {
                    return str.search(hunkregex) > -1;
                  });
                  length = hunkindex;
                  if (index > -1 && (length === -1 || index < hunkindex)) {
                    length = index;
                  }
                  if (length === -1) {
                    length = contents.length;
                  }
                  env = "";
                  if (hunk[5]) {
                    env = hunk[5].trim();
                  }
                  newdata = options.cb(contents.slice(0, length), env, options).join("\n");
                  data.splice(+hunk[3] - 1, hunk[2], newdata);
                }
                return grunt.file.write(array.dest, data.join("\n"));
              }
            });
          });
        }
        self.files.forEach(function(array) {
          return array.src.forEach(function(file) {
            if (foundfiles.indexOf(file) === -1) {
              return grunt.file.copy(file, array.dest);
            }
          });
        });
        return done();
      });
    });
  };

}).call(this);
