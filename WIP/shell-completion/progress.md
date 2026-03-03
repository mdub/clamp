# Shell completion — progress notes

## Increment 1: scaffolding + fish generator

- Created shared utilities in `lib/clamp/completion.rb`:
  `expanded_switches`, `visible_options`, `generate` dispatcher,
  and `Clamp::Command.generate_completion` class method.
- Created `lib/clamp/completion/fish_generator.rb`.
- Hit infinite recursion: `subcommand "status", "show status"` (no block)
  reuses the parent class. Fixed by tracking visited classes with a `Set`,
  using immutable copies (`visited | [command_class]`) so branches don't
  interfere.
- Fish condition logic: `__fish_use_subcommand` for top-level,
  `__fish_seen_subcommand_from` chain for nested, with exclusion of child
  subcommand names to scope options to the right level.
- 12 specs passing including fish syntax validation.

## Increment 1b: Completion::Command subcommand

- Added `Clamp::Completion::Command` — a ready-made subcommand class that
  generates completion scripts. Usage:
  ```ruby
  subcommand "completion", "Generate shell completions",
    Clamp::Completion::Command
  ```
  Then: `myapp completion fish`
- Root command class is inferred at runtime via `context[:root_command_class]`.
  `clamp/completion` prepends a module onto `Clamp::Command.run` that stashes
  `self` into context before calling `super`.
- Executable name derived from `invocation_path.split.first`.
- Updated `examples/gitdown` to use the subcommand approach instead of the
  manual `--completion` flag.
- 18 specs, 235 total suite — all passing, rubocop clean.

## Increment 1c: implicit --completion option

- Added `--completion SHELL` as a hidden option on all commands, following
  the `--help` pattern: option raises `Clamp::Completion::Wanted`, caught
  by `.run`.
- Prepends `WithCompletionOption` onto `Clamp::Option::Declaration`, hooking
  into `declare_implicit_help_option` to also declare `--completion`.
- Works on commands without subcommands: `myapp --completion fish`.
- Accepts full shell paths: `myapp --completion /usr/bin/fish`.
- Hidden from help output and from generated completions.
- 25 specs, 242 total suite — all passing, rubocop clean.

## Increment 2: bash generator

- Created `lib/clamp/completion/bash_generator.rb` with:
  - `complete -F _<name> <name>` registration.
  - Main completion function walks `COMP_WORDS` to find current subcommand path
    (using `::` separator, e.g. `"remote::add"`).
  - `case` statement mapping each subcommand path to its options + subcommand names.
  - `__<name>_takes_value` helper function that knows which options require
    arguments, used to skip option values when walking the word list and to
    suppress completions after a valued option.
  - `__<name>_find_subcmd` helper that walks `COMP_WORDS` to determine the
    current subcommand path.
  - Fallback for `_init_completion` (for systems without bash-completion).
- Refactored: extracted `walk_command_tree` and `collect_subcommand_names` into
  the shared `Completion` module. These are generic command-tree walkers reusable
  by all generators.
- Added `CountAsOne: ['array']` to `.rubocop.yml` for `Metrics/ClassLength` —
  array literals containing bash template strings are conceptually one unit.
- 36 specs, 253 total suite — all passing, rubocop clean.
