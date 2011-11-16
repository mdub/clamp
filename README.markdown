Clamp
=====

"Clamp" is a minimal framework for command-line utilities.  

It handles boring stuff like parsing the command-line, and generating help, so you can get on with making your command actually do stuff.

Not another one!
----------------

Yeah, sorry.  There are a bunch of existing command-line parsing libraries out there, and Clamp draws inspiration from a variety of sources, including [Thor], [optparse], and [Clip].  In the end, though, I wanted a slightly rounder wheel.

[optparse]: http://ruby-doc.org/stdlib/libdoc/optparse/rdoc/index.html
[Thor]: http://github.com/wycats/thor
[Clip]: http://clip.rubyforge.org/

Quick Start
-----------

Clamp models a command as a Ruby class; a subclass of `Clamp::Command`.  They look something like this:

    class SpeakCommand < Clamp::Command

      option "--loud", :flag, "say it loud"
      option ["-n", "--iterations"], "N", "say it N times", :default => 1 do |s|
        Integer(s)
      end

      parameter "WORDS ...", "the thing to say", :attribute_name => :words

      def execute
        the_truth = words.join(" ")
        the_truth.upcase! if loud?
        iterations.times do
          puts the_truth
        end
      end

    end

Calling `run` on a command class creates an instance of it, then invokes it using command-line arguments (from ARGV, by default).

    SpeakCommand.run

Class-level methods like `option` and `parameter` declare attributes (in a similar way to `attr_accessor`), and arrange for them to be populated automatically based on command-line arguments.  They are also used to generate `help` documentation.  

Declaring options
-----------------

Options are declared using the `option` method.  The three required arguments are:

  1. the option switch (or switches),
  2. an option argument name
  3. a short description

For example:

    option "--flavour", "FLAVOUR", "ice-cream flavour"

It works a little like `attr_accessor`, defining reader and writer methods on the command class.  The attribute name is derived from the switch (in this case, "`flavour`").  When you pass options to your command, Clamp will populate the attributes, which are then available for use in your `#execute` method.

    def execute
      puts "You chose #{flavour}.  Excellent choice!"
    end

If you don't like the inferred attribute name, you can override it:

    option "--type", "TYPE", "type of widget", :attribute_name => :widget_type
                                               # to avoid clobbering Object#type

### Short/long option switches

The first argument to `option` can be an array, rather than a single string, in which case all the switches are treated as aliases:

    option ["-s", "--subject"], "SUBJECT", "email subject line"

### Flag options

Some options are just boolean flags.  Pass "`:flag`" as the second parameter to tell Clamp not to expect an option argument:

    option "--verbose", :flag, "be chatty"

For flag options, Clamp appends "`?`" to the generated reader method; ie. you get a method called "`#verbose?`", rather than just "`#verbose`".

Negatable flags are easy to generate, too: 

    option "--[no-]force", :flag, "be forceful (or not)"

Clamp will handle both "`--force`" and "`--no-force`" options, setting the value of "`#force?`" appropriately.

Declaring parameters
--------------------

Positional parameters can be declared using `parameter`, specifying

  1. the parameter name, and
  2. a short description

For example:

    parameter "SRC", "source file"

Like options, parameters are implemented as attributes of the command, with the default attribute name derived from the parameter name (in this case, "`src`"). By convention, parameter names are specified in uppercase, to make them obvious in usage help.

### Optional parameters

Wrapping a parameter name in square brackets indicates that it's optional, e.g.

    parameter "[TARGET_DIR]", "target directory"

### Greedy parameters

Three dots at the end of a parameter name makes it "greedy" - it will consume all remaining command-line arguments.  For example:

    parameter "FILE ...", "input files"

The suffix "`_list`" is appended to the default attribute name for greedy parameters; in this case, an attribute called "`file_list`" would be generated.

Parsing and validation of options and parameters
------------------------------------------------

When you `#run` a command, it will first attempt to `#parse` command-line arguments, and map them onto the declared options and parameters, before invoking your `#execute` method.

Clamp will verify that all required (ie. non-optional) parameters are present, and signal a error if they aren't.

### Validation block

Both `option` and `parameter` accept an optional block.  If present, the block will be 
called with the raw string option argument, and is expected to coerce it to 
the correct type, e.g.

    option "--port", "PORT", "port to listen on" do |s|
      Integer(s)
    end

If the block raises an ArgumentError, Clamp will catch it, and report that the value was bad:

    !!!plain
    ERROR: option '--port': invalid value for Integer: "blah"

### Advanced option/parameter handling

While Clamp provides an attribute-writer method for each declared option or parameter, you always have the option of overriding it to provide custom argument-handling logic, e.g.

    parameter "SERVER", "location of server"
    
    def server=(server)
      @server_address, @server_port = server.split(":")
    end

### Default values

Default values can be specified for options:

    option "--flavour", "FLAVOUR", "ice-cream flavour", :default => "chocolate"

and also for optional parameters

    parameter "[HOST]", "server host", :default => "localhost"

For more advanced cases, you can also specify default values by defining a method called "`default_#{attribute_name}`":

    option "--http-port", "PORT", "web-server port", :default => 9000

    option "--admin-port", "PORT", "admin port"

    def default_admin_port
       http_port + 1
    end

Declaring Subcommands
---------------------

Subcommand support helps you wrap a number of related commands into a single script (ala tools like "`git`").  Clamp will inspect the first command-line argument (after options are parsed), and delegate to the named subcommand.

Unsuprisingly, subcommands are declared using the `subcommand` method. e.g.

    class MainCommand < Clamp::Command

      subcommand "init", "Initialize the repository" do

        def execute
          # ...
        end

      end
      
    end

Clamp generates an anonymous subclass of the current class, to represent the subcommand.  Alternatively, you can provide an explicit subcommand class:
    
    class MainCommand < Clamp::Command

      subcommand "init", "Initialize the repository", InitCommand
      
    end

    class InitCommand < Clamp::Command

      def execute
        # ...
      end

    end

### Default subcommand

You can set a default subcommand, at the class level, as follows:

    class MainCommand < Clamp::Command

      self.default_subcommand = "status"
      
      subcommand "status", "Display current status" do

        def execute
          # ...
        end

      end
      
    end

Then, if when no SUBCOMMAND argument is provided, the default will be selected.

### Subcommand options and parameters

Options are inheritable, so any options declared for a command are supported for it's sub-classes (e.g. those created using `subcommand`).  Parameters, on the other hand, are not inherited - each subcommand must declare it's own parameter list.

Note that, if a subcommand accepts options, they must be specified on the command-line _after_ the subcommand name.  

Getting help
------------

All Clamp commands support a "`--help`" option, which outputs brief usage documentation, based on those seemingly useless extra parameters that you had to pass to `option` and `parameter`.

    $ speak --help
    Usage:
        speak [OPTIONS] WORDS ...

    Arguments:
        WORDS ...                     the thing to say

    Options:
        --loud                        say it loud
        -n, --iterations N            say it N times (default: 1)
        -h, --help                    print help

License
-------

Copyright (C) 2011 [Mike Williams](mailto:mdub@dogbiscuit.org)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to
deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Contributing to Clamp
---------------------

Source-code for Clamp is [on Github](https://github.com/mdub/clamp).  
