# Shell completion generation for Clamp

## Context

Issue #45 requests shell autocompletion support. We'll add completion
generation directly to Clamp, covering bash, zsh, and fish.

## Approach

**Static script generation** via class-level introspection. Clamp command
trees are fully defined at class-load time, so we can walk the tree of
options, subcommands, and their metadata to generate shell-specific
completion scripts.

**Opt-in require**: `require "clamp/completion"` adds a `generate_completion`
class method to `Clamp::Command`. Not loaded by default.

**API**:
```ruby
require "clamp/completion"
script = MyCommand.generate_completion(:bash, "myapp")
# Returns a string containing a shell completion script
```

## Files to create

| File | Purpose |
|------|---------|
| `lib/clamp/completion.rb` | Entry point, shared utilities, patches Command |
| `lib/clamp/completion/bash_generator.rb` | Bash completion generator |
| `lib/clamp/completion/zsh_generator.rb` | Zsh completion generator |
| `lib/clamp/completion/fish_generator.rb` | Fish completion generator |
| `spec/clamp/completion_spec.rb` | Tests for all generators |

No existing files modified.

## Shared utilities (`lib/clamp/completion.rb`)

- `function_name(parts)` — sanitise command path into a valid shell
  identifier (join with `_`, replace non-alphanumeric with `_`)
- `expanded_switches(option)` — expand `--[no-]foo` into
  `["--foo", "--no-foo"]` (reimplements the private `recognised_switches`
  logic from `Option::Definition`)
- `visible_options(command_class)` — `recognised_options.reject(&:hidden?)`
- `subcommand_names(command_class)` — all names including aliases

The `generate` method dispatches to the appropriate generator class.
Reopens `Clamp::Command` to add `generate_completion(shell, executable_name)`.

## Shell generators

### Bash (`bash_generator.rb`)

Generates a `complete -F _<name> <name>` script with:

1. A main function that walks `COMP_WORDS` to determine the current
   subcommand path
2. A `case` statement mapping each subcommand path to its available
   options + subcommand names
3. A helper function that knows which options require arguments, used to
   skip option values when walking the word list
4. Fallback for `_init_completion` (for systems without bash-completion)

### Zsh (`zsh_generator.rb`)

Generates a `#compdef` script with:

1. A function per command node
2. Each function uses `_arguments -C` with option specs and subcommand
   dispatch
3. Subcommands listed via `_describe`
4. `case $state` dispatches to sub-functions

### Fish (`fish_generator.rb`)

Generates a series of `complete -c <name>` registrations using fish
builtins `__fish_use_subcommand` and `__fish_seen_subcommand_from`.

## What gets completed

- Option switches (short and long, including `--[no-]` expansions)
- Subcommand names (including aliases)
- `--help` / `-h` (from the implicit help option)

## What's excluded

- Hidden options (consistent with help output)
- Parameter values (no way to know valid values statically)

## Test fixture

A command class with:
- Options: flag (`-v`/`--verbose`) and valued (`--format FORMAT`)
- Hidden option (`--secret`)
- Subcommands with aliases (`remote`, `status`)
- Nested subcommands (`remote add`, `remote remove`/`rm`)
- Inherited options (from parent class)

Assertions per shell:
- Non-empty string output
- Contains expected option switches
- Contains subcommand names and aliases
- Excludes hidden options
- Includes subcommand-specific options
- Syntax validation: `bash -n` / `zsh -n` / `fish --no-execute`

## Increments

1. Scaffolding + fish generator
2. Bash generator
3. Zsh generator
4. Polish + edge cases

## Key source files

- `lib/clamp/option/definition.rb` — `switches`, `flag?`, `hidden?`, `type`
- `lib/clamp/option/declaration.rb` — `recognised_options`
- `lib/clamp/subcommand/definition.rb` — `names`, `description`
- `lib/clamp/subcommand/declaration.rb` — `recognised_subcommands`, `has_subcommands?`
- `lib/clamp/help.rb` — pattern for filtering hidden items (line 103)
