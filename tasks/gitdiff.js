(function() {
  var simpleGit, _;

  _ = require("lodash");

  simpleGit = require("simple-git");

  module.exports = function(grunt) {
    return grunt.registerMultiTask("gitdiff", "Extracts the git diff", function() {
      var done, git, options, self;
      options = this.options();
      _.defaults(options, {
        hunkregex: /@@ \-(\d+),(\d+) \+(\d+),(\d+) @@/,
        prependplus: "<span style='color:blue'>",
        prependminus: "<span style='color:red'>",
        append: "</span>",
        cb: function(string, prepend, append) {
          return prepend + string + append;
        }
      });
      self = this;
      done = self.async();
      git = simpleGit();
      git.diff("", function(err, content) {
        var contents, filename, foundfiles, index;
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
              var data, dataindex, hunk, hunkindex, j, length;
              if (filename.indexOf(file) > -1) {
                console.log("found change in " + file);
                foundfiles.push(file);
                data = grunt.file.read(file).split("\n");
                hunkindex = 3;
                while (hunkindex !== -1 && (hunkindex < index || index === -1)) {
                  hunk = contents[hunkindex].match(options.hunkregex);
                  contents.splice(0, hunkindex + 1);
                  index = index - hunkindex - 1;
                  hunkindex = _.findIndex(contents, function(str) {
                    return str.search(options.hunkregex) > -1;
                  });
                  length = hunkindex;
                  if (index > -1 && (length === -1 || index < hunkindex)) {
                    length = index;
                  }
                  if (length === -1) {
                    length = contents.length;
                  }
                  dataindex = +hunk[3] - 1;
                  j = 0;
                  while (j < length) {
                    switch (contents[j][0]) {
                      case "-":
                        data.splice(dataindex + j, 0, options.cb(contents[j].substr(1), options.prependminus, options.append));
                        break;
                      case "+":
                        data.splice(dataindex + j, 1, options.cb(contents[j].substr(1), options.prependplus, options.append));
                    }
                    j++;
                  }
                }
                return grunt.file.write(array.dest, data.join("\n"));
              }
            });
          });
        }
        self.files.forEach(function(array) {
          return array.src.forEach(function(file) {
            if (foundfiles.indexOf(file) === -1) {
              console.log(file);
              return grunt.file.copy(file, array.dest);
            }
          });
        });
        return done();
      });
      return options = this.options();
    });
  };

}).call(this);
