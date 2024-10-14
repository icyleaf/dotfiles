ONLY_LINK_FILES="${ONLY_LINK_FILES:-"false"}"

show_help() {
  cat <<EOF
Usage: $0 [options]
icyleaf's dotfiles installer.
Options:
 -h, --help             Show this message and exit.
 --only-link-files      Only execute link files (default value: ${ONLY_LINK_FILES}).
EOF
}

while (( $# )); do
  case "$1" in
    -h | --help) show_help; exit;;
    --only-link-files) ONLY_LINK_FILES=1;;
    --) ;;
    *) echo "Unexpected argument: $1. Use --help for usage information."; exit 1;;
  esac
  shift
done
