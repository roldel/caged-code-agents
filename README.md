# caged-code-agents

Containerized, throwaway sandboxes for running terminal coding agents in
isolation. Each agent — Claude Code, Codex CLI, and Grok Build — runs in its
own minimal Debian image with only the tools it needs. A single directory,
wired in through a Docker bind mount, is all the agent can touch on the host —
it works directly on your real project files while everything else stays
sandboxed.