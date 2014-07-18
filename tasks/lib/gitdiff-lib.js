(function() {
  var getTagFromJadeString, options, parseJade, _;

  _ = require("lodash");

  getTagFromJadeString = function(string) {
    var inBracket, inString, j, started, tag;
    j = 0;
    tag = "";
    started = false;
    inBracket = false;
    inString = false;
    while (j < string.length) {
      if (string[j].search(/\S/) > -1 || inString) {
        tag = tag + string[j];
        started = true;
      }
      if (!inString && string[j].search(/(["'])/) > -1) {
        inString = string[j].match(/(["'])/)[0];
      } else if (inString && string[j].search(inString) > -1) {
        inString = false;
      }
      if (!inBracket && !inString && string[j].search(/\(/) > -1) {
        inBracket = true;
      } else if (inBracket && string[j].search(/\)/) > -1) {
        inBracket = false;
      }
      if (started && !inBracket && !inString && string[j].search(/\s/) > -1) {
        break;
      }
      j++;
    }
    if (j + 1 >= string.length) {
      string = "";
    } else {
      string = string.substr(j + 1);
    }
    return [tag, string];
  };

  parseJade = function(hunk, environment, options) {
    var empty, env, envadv, environments, j, k, keyword, keywords, lastws, prepend, str, string, tag, whitespace, ws, _i, _len;
    keywords = ["html", "head", "meta", "link", "body", "include", "doctype", "//", "\\-", "mixin", "\\+", "img", "figure", "blockquote"];
    empty = /^[\s]*$/;
    env = /\w+\.$/;
    envadv = /^\w+\.$/;
    environments = [];
    if (environment) {
      environments.push(environment);
    }
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
        if (whitespace === 0) {
          environments = [];
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
          if (str.substr(whitespace).search(envadv) !== -1) {
            keyword = true;
          }
          if (!keyword) {
            ws = str.substr(0, whitespace);
            string = str.substr(whitespace);
            if (string.search("Jeder Teilnehmer muss sich sicher authentifizieren und") > -1) {
              console.log(environments);
              console.log(hunk);
            }
            if (string[0] === "|") {
              str = ws + "| #[" + prepend + string.substr(2) + "]";
            } else if (environments.length > 0 && environments[environments.length - 1].search(env) !== -1) {
              str = ws + "#[" + prepend + string + "]";
            } else {
              tag = getTagFromJadeString(string);
              str = ws + tag[0];
              if (tag[1]) {
                str = str + " #[" + prepend + tag[1] + "]";
              }
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
  };

  options = {
    options: {
      hunkregex: /@@ \-(\d+),(\d+) \+(\d+),(\d+) @@([\s\S]*)/,
      parser: "jade",
      trimFirstWhitespace: true
    },
    jade: {
      options: {
        prependplus: "span(style='color:blue') ",
        prependminus: "span(style='color:red') ",
        cb: parseJade
      }
    }
  };

  module.exports = {
    getOptions: function(setOptions) {
      if (!setOptions) {
        setOptions = {};
      }
      _.defaults(setOptions, options.options);
      _.defaults(setOptions, options[setOptions.parser].options);
      return setOptions;
    },
    test: {
      getTagFromJadeString: getTagFromJadeString,
      parseJade: parseJade
    }
  };

}).call(this);
