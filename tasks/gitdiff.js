(function() {
  var simpleGit, _;

  _ = require("lodash");

  simpleGit = require("simple-git");

  module.exports = function(grunt) {
    return grunt.registerMultiTask("gitdiff", "Extracts the git diff", function() {
      var done, git, hunkregex, options, self;
      options = this.options();
      _.defaults(options, {
        hunkregex: /@@ \-(\d+),(\d+) \+(\d+),(\d+) @@ ([\s\S]+)/,
        prependplus: "span(style='color:red') ",
        prependminus: "span(style='color:red') ",
        cb: function(hunk, environment, options) {
          var empty, env, environments, j, k, keyword, keywords, lastws, prepend, str, string, whitespace, ws, _i, _len;
          keywords = ["html", "head", "meta", "link", "body", "include", "doctype", "//", "\\-", "mixin", "\\+"];
          empty = /\s*\s$/;
          env = /\w+\.$/;
          environments = [environment];
          lastws = -1;
          j = 0;
          while (j < hunk.length) {
            str = hunk[j];
            switch (str[0]) {
              case "-":
                str = str.substr(1);
                prepend = options.prependminus;
                break;
              case "+":
                str = str.substr(1);
                prepend = options.prependplus;
                break;
              default:
                prepend = false;
            }
            if (str.search(empty) === -1) {
              whitespace = str.match(/(^\s+)\S+/);
              if (whitespace) {
                whitespace = whitespace[1].length;
              } else {
                whitespace = 0;
              }
              if (lastws > -1) {
                if (whitespace > lastws) {
                  environments.push(hunk[j - 1]);
                } else if (whitespace < lastws) {
                  environments.pop();
                }
              }
              if (prepend) {
                keyword = false;
                for (_i = 0, _len = keywords.length; _i < _len; _i++) {
                  k = keywords[_i];
                  if (str.search(new RegExp("\s*" + k)) !== -1) {
                    keyword = true;
                    break;
                  }
                }
                if (str.search(env) !== -1) {
                  keyword = true;
                }
                if (!keyword) {
                  ws = str.substr(0, whitespace);
                  string = str.substr(whitespace);
                  if (string[0] === "|") {
                    str = ws + "| #[" + prepend + string.substr(1) + "]";
                  } else if (environments.length > 0 && environments[environments.length - 1].search(env) !== -1) {
                    str = ws + "#[" + prepend + string + "]";
                  } else {
                    str = ws + prepend + "#[" + string + "]";
                  }
                }
              }
              lastws = whitespace;
            }
            if (prepend) {
              hunk[j] = str;
            }
            j++;
          }
          return hunk;
        }
      });
      hunkregex = new RegExp(options.hunkregex);
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
              var data, hunk, hunkindex, length, newdata;
              if (filename.indexOf(file) > -1) {
                console.log("found change in " + file);
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
                  newdata = cb(contents.slice(0, length), hunk[5], options).join("\n");
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
