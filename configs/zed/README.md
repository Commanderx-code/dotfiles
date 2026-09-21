# Zed setup

Zed 1.20.2 is configured for the local Rust, JavaScript/TypeScript, Python, Nix, and shell projects. The system package manager owns Zed; Home Manager owns the supporting tools. Your existing Catppuccin Mocha / One Light theme and font sizes are preserved.

## Start working

Open a project folder with `zeditor /path/to/project`. Trust your own project when Zed asks, so language servers and tasks can run. Restart Zed once after this setup to pick up the final extension additions.

| Action | Shortcut |
| --- | --- |
| Start a Codex conversation | Ctrl+Alt+A |
| Choose a build, test, or terminal task | Ctrl+Alt+T |
| Command palette | Ctrl+Shift+P |
| Find a file | Ctrl+P |
| Project search | Ctrl+Shift+F |
| Go to definition | F12 |
| Rename symbol | F2 |
| Format document | Shift+Alt+F |
| Diagnostics | Ctrl+Shift+M |
| Git panel | Ctrl+Shift+G |
| Debug panel | Ctrl+Shift+D |

## Code assistance

- Rust: rust-analyzer, Clippy checks, formatting, navigation, and type hints. Rust/Cargo/Clippy/rustfmt were already installed.
- JavaScript, TypeScript, and React: vtsls, project-aware navigation and completion, and Zed's Prettier integration. Project formatting settings still apply.
- Python: basedpyright completion/type analysis and Ruff diagnostics/formatting. Select the project's interpreter using Zed's toolchain selector. Install project dependencies, including pytest when needed, in that project's environment.
- Nix: nil completion/navigation and nixfmt formatting.
- Bash: bash-language-server, ShellCheck, and shfmt. Fish: highlighting, fish_indent formatting, and a syntax-check task.
- JSON/CSS/YAML: language servers. TOML: TOML grammar plus the Tombi language-server extension. Dockerfile, HTML, and Make extensions are enabled.

Formatting runs on save, except for Markdown, where existing line breaks and significant trailing spaces are preserved. Tasks save edited buffers before running. Normal editor saves remain manual. The integrated terminal uses Fish; tabs display file icons, Git status, and errors.

Zed's debugger panel is available. Language-specific debug adapters are downloaded on first use; application launch arguments and project dependencies belong in each project's debug configuration. Debugger sessions were not exercised during this setup.

## Codex

Press **Ctrl+Alt+A**, or choose **Codex** from the Agent Panel's new-thread menu. Codex is configured through Zed's ACP registry with normal Agent permissions. Choose its model in the Codex conversation. The adapter successfully used the existing ChatGPT login and returned a real test response.

Codex also has a terminal task for the familiar CLI experience. If the login expires, run `codex login` in the terminal. Credentials are not copied into these dotfiles.

Only Codex was selected for AI. Zed-hosted AI, inline AI predictions, and other paid providers are not configured. Language-server completion remains enabled. The native Zed inline assistant has separate provider requirements; the Codex conversation is the configured AI entry point.

See [Zed external agents](https://zed.dev/docs/ai/external-agents) and [OpenAI authentication](https://learn.chatgpt.com/docs/auth).

## Maintenance and restore

Editable settings, keybindings, and tasks are in `configs/zed/` in the dotfiles repository. Home Manager links them into `~/.config/zed/`; changes made in Zed also update these repository files. Review changes before committing them, and keep API keys out of settings.

The supporting packages are declared in `home-manager/modules/zed.nix`. Apply package changes with `hm-rebuild`. Newly created Nix module files must be tracked by Git for normal flake evaluation; the setup's files have been staged but not committed.

The previous Zed settings are preserved at `~/.config/zed/settings.json.before-zed-20260921`. To restore their contents while retaining the Home Manager link, copy that backup over `configs/zed/settings.json` in the dotfiles repository.

## Verification

The repository checks and Home Manager build passed. The final package set was activated successfully. Language-server protocol startup checks covered Rust, Python, Ruff, Nix, Bash, JavaScript/TypeScript, JSON, CSS, YAML, and TOML tooling. Zed was observed running Rust, TypeScript, and JSON servers in command-center. Codex ACP authentication and a real prompt/response were verified separately from the Zed UI.
