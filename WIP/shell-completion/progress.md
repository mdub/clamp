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
