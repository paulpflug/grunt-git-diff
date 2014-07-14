# grunt-git-diff

"Grunt Task that uses the git diff information to modify the content of files",
  
A simple [Grunt][grunt] multitask that uses git diff information to modify the content of files.

Used in [paged-media-boilerplate][paged-media-boilerplate].

## Table of Contents

<!-- toc -->
* [Getting Started](#getting-started)
  * [Use it with grunt](#use-it-with-grunt)
* [Documentation](#documentation)
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
# Note, that the index 2 is the number of overwritten lines
# index 3 is the linenumber where to overwrite, and index 5 is the current 
# environment, important for jade parsing
hunkregex: /@@ \-(\d+),(\d+) \+(\d+),(\d+) @@ ([\s\S]+)/

# string which is prepended if a line is added
prependplus: "span(style='color:red') "

# string which is prepended if a line is deleted
prependminus: "span(style='color:red') " 

# function which is used to calculate the new strings based on the hunk
# corresponding prepend / append strings
cb = (hunk, environment, options) ->
  # default is to parse jade
```

### Example with jade
First append this to your css:
```css
span.strongred, span.strongred * {color:red !important;}
span.strongblue, span.strongblue * {color:blue !important;}
```

This is how the task could look like, which creates a jade diff:
```coffee
gitdiff:
  options:
    prependplus: "span.strongred " 
    prependminus:"span.strongblue "
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
 - *v0.0.5*: Bugfix
 - *v0.0.4*: major rework
 - *v0.0.3*: Bugfix
 - *v0.0.2*: Updated dependencies
 - *v0.0.1*: First Release

## License
Copyright (c) 2014 Paul Pflugradt
Licensed under the MIT license.
