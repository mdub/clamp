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

Clamp models a command as a Ruby class; a subclass of {Clamp::Command}.  They look something like this:

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

Calling {Clamp::Command.run `run`} on a command class creates an instance of it, then invokes it using command-line arguments (from ARGV, by default).

    SpeakCommand.run

Class-level methods like `option` and `parameter` declare attributes (in a similar way to `attr_accessor`), and arrange for them to be populated automatically based on command-line arguments.  They are aso used to generate {Clamp::Command#help `help`} documentation.  

Declaring options
-----------------

Options are declared using the {Clamp::Option::Declaration.option `option`} method.  The three required arguments are:

  1. the option switch (or switches),
  2. a short description of the option argument type, and
  3. a description of the option itself

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

For flag options, Clamp appends "`?`" to the generated reader method; ie. you get a method called "`verbose?`", rather than just "`verbose`".

Negatable flags are easy to generate, too: 

    option "--[no-]force", :flag, "be forceful (or not)"

Clamp will handle both "`--force`" and "`--no-force`" options, setting the value of "`#force?`" appropriately.

Declaring parameters
--------------------

Positional parameters can be declared using the {Clamp::Parameter::Declaration.parameter `parameter`} method.

    parameter "SRC", "source file"
    parameter "DIR", "target directory"

Like options, parameters are implemented as attributes of the command.

If parameters are declared, Clamp will verify that all are present.  Otherwise, arguments
that remain after option parsing will be made available using
{Clamp::Command#arguments `#arguments`}.

## Validation and conversion of option arguments and parameters

Both `option` and `parameter` accept an optional block.  If present, the block will be 
called with the raw string option argument, and is expected to coerce that String to 
the correct type, e.g.

    option "--port", "PORT", "port to listen on" do |s|
      Integer(s)
    end

If the block raises an ArgumentError, Clamp will catch it, and report that the value was bad:

    !!!plain
    ERROR: option '--port': invalid value for Integer: "blah"

Sub-commands
------------

The `subcommand` method declares sub-commands:

    class MainCommand < Clamp::Command

      subcommand "init", "Initialize the repository" do

        def execute
          # ...
        end

      end
      
    end

Clamp generates an anonymous sub-class of the current class, to represent the sub-command.  Additional options may be declared within subcommand blocks, but all options declared on the parent class are also accepted.

Alternatively, you can provide an explicit sub-command class, rather than a block:
    
    class MainCommand < Clamp::Command

      subcommand "init", "Initialize the repository", InitCommand
      
    end

    class InitCommand < Clamp::Command

      def execute
        # ...
      end

    end

When a command has sub-commands, Clamp will attempt to delegate to the appropriate
one, based on the first command-line argument (after options are parsed).

If a sub-command accepts options or parameters of it's own, they must be specified after the sub-command name.

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
        -n, --iterations N            say it N times
        --help                        print help

Contributing to Clamp
---------------------

Source-code for Clamp is [on Github](https://github.com/mdub/clamp).  
