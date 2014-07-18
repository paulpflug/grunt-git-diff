
module.exports = (grunt) ->
  
  # Load grunt tasks automatically
  require("load-grunt-tasks") grunt
  require("time-grunt") grunt
  grunt.initConfig
    watch:
      coffee:
        files: ["src/**/*.coffee"]
        tasks: ["newer:coffee","mochaTest"]
      test:
        files: ["test/**/*.coffee"]
        tasks: ["newer:mochaTest"]
    #   copy:
    #     files: ["src/**/*.jade"]
    #     tasks: ['newer:copy']
    # copy:
    #   compile:
    #     files: [
    #       expand: true,
    #       cwd: 'src/',
    #       src: '**/*.jade',
    #       dest: 'tasks/'          
    #     ]
    coffee:
      compile:
        files: [
          expand: true,
          cwd: 'src/',
          src: '**/*.coffee',
          ext: ".js",
          dest: 'tasks/'          
        ]
    clean:
      compile:
        files: [
          dot: true
          src: [
            "tasks/*"
          ]
        ]
    
    concurrent:
      compile:
        tasks: ["coffee"]#,"copy"]
    mochaTest: 
      test: 
        options: 
          reporter: 'spec',
          require: ['coffee-script/register']
        src: ['test/**/*.coffee']

  grunt.registerTask "addTocToReadme", "Adds a ToC to the readme", () ->
    toc = require("marked-toc")
    table = toc.add("README.md")


  grunt.registerTask "default", [
    "clean:compile"
    "concurrent:compile"
    "watch"
  ]

