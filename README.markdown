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

      argument "WORDS ...", "the thing to say"
      
      def execute

        signal_usage_error "I have nothing to say" if arguments.empty?
        the_truth = arguments.join(" ")
        the_truth.upcase! if loud?

        iterations.times do
          puts the_truth
        end

      end

    end

Class-level methods (like `option` and `argument`) are available to declare command-line options, and document usage.  

The command can be invoked by instantiating the class, and asking it to run:

    SpeakCommand.new("speak").run(["--loud", "a", "b", "c"])

but it's more typical to use the class-level "`run`" method:

    SpeakCommand.run
    
which takes arguments from `ARGV`, and includes some handy error-handling.

Declaring options
-----------------

Options are declared using the [`option`](../Clamp/Command.option) method.  The three required arguments are:

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

### Flag options

Some options are just boolean flags.  Pass "`:flag`" as the second parameter to tell Clamp not to expect an option argument:

    option "--verbose", :flag, "be chatty"

For flag options, Clamp appends "`?`" to the generated reader method; ie. you get a method called "`verbose?`", rather than just "`verbose`".

Negatable flags are easy to generate, too: 

    option "--[no-]force", :flag, "be forceful (or not)"

Clamp will handle both "`--force`" and "`--no-force`" options, setting the value of "`#force?`" appropriately.

Getting help
------------

All Clamp commands support a "`--help`" option, which outputs brief usage documentation, based on those seemingly useless extra parameters that you had to pass to `option` and `argument`.

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
