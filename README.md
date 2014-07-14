# grunt-git-diff

"Grunt Task that uses the git diff information to modify the content of files",
  
A simple [Grunt][grunt] multitask that uses git diff information to modify the content of files.

Used in [paged-media-boilerplate][paged-media-boilerplate].

## Table of Contents

<!-- toc -->
* [Getting Started](#getting-started)
  * [Use it with grunt](#use-it-with-grunt)
* [Documentation](#documentation)
  * [Basic example](#basic-example)
  * [Example with jade](#example-with-jade)
* [Release History](#release-history)
* [License](#license)

<!-- toc stop -->
## Getting Started

### Use it with grunt

Install this grunt plugin next to your project's [grunt.js gruntfile][getting_started] with: `npm install grunt-git-diff`

Then add this line to your project's `grunt.js` gruntfile:

```javascript
grunt.loadNpmTasks('grunt-git-diff');
```

[grunt]: https://github.com/cowboy/grunt
[getting_started]: https://github.com/cowboy/grunt/blob/master/docs/getting_started.md
[paged-media-boilerplate]: https://github.com/paulpflug/paged-media-boilerplate

## Documentation

Here the available options with the corresponding defaults:
```coffee
# Regex which is used to get the hunk
hunkregex = /@@ \-(\d+),(\d+) \+(\d+),(\d+) @@/

# string which is prepended if a line is added
prependplus = "<span style='color:blue'>" 

# string which is prepended if a line is deleted
prependminus = "<span style='color:red'>"

# string which is appended
append = "</span>"

# function which is used to calculate the new string based on the old string and the 
# corresponding prepend / append strings
cb = (string, prepend, append) ->
  return prepend+string+append
```

### Basic example 

```coffee
gitdiff:
  options:
    # some options
  compile:
    files: [
      expand: true,
      cwd: "html/",
      src: ["**/*.html"],
      ext: ".html",
      dest: "tmp/"   
    ]
```
This task would take each `html` file in the html directory and check the git diff againt it.
If there is no diff, the file is simply copied over, but if there is one,
each deleted line is encapsulated by a `<span style='color:red'>` tag and each added line by a `<span style='color:blue'>` tag.

### Example with jade
First append this to your css:
```css
span.strongred, span.strongred * {color:red !important;}
span.strongblue, span.strongblue * {color:blue !important;}
```

This is how the task could look like, which creates a jade diff:
```coffee
jade = require("jade")
#
# ... other stuff
#
gitdiff:
  options:
    prependplus: "span.strongred " 
    prependminus:"span.strongblue "
    append: ""
    cb: (string, prepend) ->
      return string if not string
      keywords = [
        "html","head","meta","link","body","include","doctype", "//","\\-","mixin","\\+","\\s$"]
      for k in keywords
        if string.search(new RegExp("\s*"+k)) != -1
          return string
      whitespace = string.match(/(^\s+)\S+/)
      if whitespace
        whitespace = whitespace[1].length
      else
        whitespace = 0
      ws = string.substr(0,whitespace)
      string = string.substr(whitespace)
      try
        jade.compile(string)
        return ws+prepend+"#["+string+"]"
      catch e
        return ws+"#["+prepend+string+"]"
  compile:
    files: [
      expand: true,
      cwd: "jade/",
      src: ["**/*.jade"],
      ext: ".jade",
      dest: "tmp/"   
    ]
```



## Release History
 - *v0.0.1*: First Release

## License
Copyright (c) 2014 Paul Pflugradt
Licensed under the MIT license.
