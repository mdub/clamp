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
