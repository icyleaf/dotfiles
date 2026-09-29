# Spaceship prompt styled after the oh-my-posh theme (icyleaf.omp.yaml).
#
# oh-my-posh palette:
#   os #ACB0BE  grey #9F9F9F  blue #3fb2eb  yellow #edce45
#   white #E0DEF4  red #c9303b  orange #F07623  black #262B44
#
# Layout (mirrors oh-my-posh):
#   line 1 (left):  <os icon> <hostname> <path> <git>
#   right:          <docker> <ruby> <node> <go> <python> <time> <exec_time>
#   line 2 (left):  ❯   (green on success, red on failure)

# ---------------------------------------------------------------------------
# Layout
# ---------------------------------------------------------------------------
SPACESHIP_PROMPT_ORDER=(
  os
  host
  dir
  git
  line_sep
  char
)

SPACESHIP_RPROMPT_ORDER=(
  docker_context
  ruby
  node
  golang
  python
  time
  exec_time
)

# ---------------------------------------------------------------------------
# Prompt behaviour
# ---------------------------------------------------------------------------
SPACESHIP_PROMPT_ASYNC=true
SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_PROMPT_SEPARATE_LINE=true
SPACESHIP_PROMPT_DEFAULT_PREFIX=""
SPACESHIP_PROMPT_DEFAULT_SUFFIX=" "
SPACESHIP_RPROMPT_FIRST_PREFIX_SHOW=true

# ---------------------------------------------------------------------------
# os — custom section mirroring oh-my-posh `os` segment (`{{ .Icon }}`)
# ---------------------------------------------------------------------------
spaceship_os() {
  local icon

  case "$(uname -s)" in
    Darwin) icon=$'\uf179' ;; # Apple
    Linux)  icon=$'\uf17c' ;; # Tux
    *)      icon=$'\uf17a' ;; # generic Linux
  esac

  spaceship::section \
    --color '#ACB0BE' \
    --suffix ' ' \
    "$icon"
}

# ---------------------------------------------------------------------------
# host — ` {{ .HostName }}`, grey
# ---------------------------------------------------------------------------
SPACESHIP_HOST_SHOW=always
SPACESHIP_HOST_SHOW_FULL=false
SPACESHIP_HOST_PREFIX=""
SPACESHIP_HOST_SUFFIX=" "
SPACESHIP_HOST_COLOR="#9F9F9F"

# ---------------------------------------------------------------------------
# dir — ` {{ .Path }}`, blue, full path
# ---------------------------------------------------------------------------
SPACESHIP_DIR_PREFIX=""
SPACESHIP_DIR_SUFFIX=" "
SPACESHIP_DIR_COLOR="#3fb2eb"
SPACESHIP_DIR_TRUNC=0
SPACESHIP_DIR_TRUNC_PREFIX=""
SPACESHIP_DIR_TRUNC_REPO=false

# ---------------------------------------------------------------------------
# git — ` {{ .UpstreamIcon }} {{ .HEAD }} ...`, yellow
# ---------------------------------------------------------------------------
SPACESHIP_GIT_PREFIX=""
SPACESHIP_GIT_SUFFIX=" "
SPACESHIP_GIT_SYMBOL=""
SPACESHIP_GIT_BRANCH_PREFIX=$'\uf408 '
SPACESHIP_GIT_BRANCH_SUFFIX=""
SPACESHIP_GIT_BRANCH_COLOR="#edce45"
SPACESHIP_GIT_STATUS_PREFIX=" "
SPACESHIP_GIT_STATUS_SUFFIX=""
SPACESHIP_GIT_STATUS_COLOR="#edce45"
SPACESHIP_GIT_STATUS_UNTRACKED="?"
SPACESHIP_GIT_STATUS_ADDED="+"
SPACESHIP_GIT_STATUS_MODIFIED=$'\uf044 '
SPACESHIP_GIT_STATUS_DELETED="✘"
SPACESHIP_GIT_STATUS_AHEAD="↑"
SPACESHIP_GIT_STATUS_BEHIND="↓"
SPACESHIP_GIT_STATUS_DIVERGED="↕"
SPACESHIP_GIT_STATUS_STASHED="$"

# ---------------------------------------------------------------------------
# char — `❯` green/red, secondary `❯❯ `
# ---------------------------------------------------------------------------
SPACESHIP_CHAR_SYMBOL="❯"
SPACESHIP_CHAR_SYMBOL_ROOT="❯"
SPACESHIP_CHAR_SYMBOL_SUCCESS="❯"
SPACESHIP_CHAR_SYMBOL_FAILURE="❯"
SPACESHIP_CHAR_SYMBOL_SECONDARY="❯❯ "
SPACESHIP_CHAR_SUFFIX=" "
SPACESHIP_CHAR_COLOR_SUCCESS="green"
SPACESHIP_CHAR_COLOR_FAILURE="red"
SPACESHIP_CHAR_COLOR_SECONDARY="magenta"

# ---------------------------------------------------------------------------
# Right prompt — docker, ruby, node, go, python, time, exec_time
# ---------------------------------------------------------------------------
# docker — ` \uf308 {{ .Context }}`, blue
SPACESHIP_DOCKER_CONTEXT_SHOW=true
SPACESHIP_DOCKER_CONTEXT_ASYNC=false
SPACESHIP_DOCKER_COLOR="#3fb2eb"
SPACESHIP_DOCKER_CONTEXT_PREFIX=$'\uf308 '
SPACESHIP_DOCKER_CONTEXT_SUFFIX=" "

# ruby — ` \ue791 {{ .Full }}`, red
SPACESHIP_RUBY_PREFIX=""
SPACESHIP_RUBY_SUFFIX=" "
SPACESHIP_RUBY_SYMBOL=$'\ue791 '
SPACESHIP_RUBY_COLOR="#c9303b"

# node — `\ue718 {{ .Full }}`, green
SPACESHIP_NODE_SHOW=true
SPACESHIP_NODE_PREFIX=""
SPACESHIP_NODE_SUFFIX=" "
SPACESHIP_NODE_SYMBOL=$'\ue718 '
SPACESHIP_NODE_COLOR="green"

# go — `\ue626`, blue
SPACESHIP_GOLANG_PREFIX=""
SPACESHIP_GOLANG_SUFFIX=" "
SPACESHIP_GOLANG_SYMBOL=$'\ue626 '
SPACESHIP_GOLANG_COLOR="#3fb2eb"

# python — `\ue235`, yellow
SPACESHIP_PYTHON_PREFIX=""
SPACESHIP_PYTHON_SUFFIX=" "
SPACESHIP_PYTHON_SYMBOL=$'\ue235 '
SPACESHIP_PYTHON_COLOR="#edce45"

# time — ` HH:MM:SS`, grey
SPACESHIP_TIME_SHOW=true
SPACESHIP_TIME_FORMAT="%D{%T}"
SPACESHIP_TIME_PREFIX=" "
SPACESHIP_TIME_SUFFIX=" "
SPACESHIP_TIME_COLOR="#9F9F9F"

# exec_time — ` {{ .FormattedMs }}`, red, longer than 5s
SPACESHIP_EXEC_TIME_SHOW=true
SPACESHIP_EXEC_TIME_PREFIX=""
SPACESHIP_EXEC_TIME_SUFFIX=" "
SPACESHIP_EXEC_TIME_COLOR="#c9303b"
SPACESHIP_EXEC_TIME_ELAPSED=5
SPACESHIP_EXEC_TIME_PRECISION=1
