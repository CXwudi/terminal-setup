# Return success for a live SSH agent, including one with no keys loaded.
_terminal_setup_ssh_agent_available() {
  [[ -n ${SSH_AUTH_SOCK:-} && -S $SSH_AUTH_SOCK ]] || return 1
  if command ssh-add -l >/dev/null 2>&1; then
    return 0
  else
    [[ $? -eq 1 ]]
  fi
}

# Reuse an inherited agent, then a cached agent, before starting a new one.
if ! _terminal_setup_ssh_agent_available; then
  _terminal_setup_agent_env="$HOME/.ssh/ssh-agent"
  [[ -r "$_terminal_setup_agent_env" ]] && source "$_terminal_setup_agent_env" >/dev/null
  if ! _terminal_setup_ssh_agent_available; then
    mkdir -p "$HOME/.ssh"
    (umask 077; command ssh-agent -s > "$_terminal_setup_agent_env")
    source "$_terminal_setup_agent_env" >/dev/null
  fi
  [[ -f "$_terminal_setup_agent_env" ]] && chmod 600 "$_terminal_setup_agent_env"
  unset _terminal_setup_agent_env
fi
unfunction _terminal_setup_ssh_agent_available
