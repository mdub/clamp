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

Clamp models a command as a Ruby class, and command invocations as instances of that class.

"Command classes" are subclasses of `Clamp::Command`.  They look like this:

    class InstallCommand < Clamp::Command
    
      option "--force", :flag, ""
        
      def execute
        # do something
      end
        
    end

Class-level methods are available to declare command-line options, and document usage.  

Clamp commands are invoked like so:

    InstallCommand.run

This will instantiate a new `InstallCommand`, handle command-line args, and finally call the  `#execute` method to do the real work.
