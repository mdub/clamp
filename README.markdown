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
      option "--iterations", "N", "say it N times"

      argument "WORDS ...", "the thing to say"

      def iterations
        @iterations ||= 1         # provide a default
      end
      
      def execute

        signal_usage_error "I have nothing to say" if arguments.empty?
        the_truth = arguments.join(" ")
        the_truth.upcase! if loud?

        iterations.times do
          puts the_truth
        end

      end

    end

Class-level methods are available to declare command-line options, and document usage.  

The command is invoked by instantiating the command-class, and asking it to run:

    SpeakCommand.new("speak").run(ARGV)

or, more succintly:

    SpeakCommand.run
