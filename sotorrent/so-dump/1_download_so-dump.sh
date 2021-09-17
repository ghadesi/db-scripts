# The env command wrapping
#!/usr/bin/env bash
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
#set -Eeuo pipefail

# POSIX sh and especially bash have a number of settings that can help write safe shell scripts.
# NAME
#    set - allows us to change the values of shell option
# COMMAND-LINE OPTIONS
#    -E
#       Allow error traps on function calls, subshell environment, and command substitutions.
#    -e
#       If a command fails, this switch will make the whole script exit.
#    -u
#       Treat unset variables as an error, and immediately exit.
#    -o option-name
#       pipefail
#         If set, the return value of a pipeline is the value of the last (rightmost) command to 
#         exit with a non-zero status, or zero if all commands in the pipeline exit successfully. 
#         This option is disabled by default.
# 
# Reference:
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
# https://transang.me/best-practice-to-make-a-shell-script/
# https://sipb.mit.edu/doc/safe-shell/

wget -c https://archive.org/download/stackexchange/stackoverflow.com-Badges.7z
wget -c https://archive.org/download/stackexchange/stackoverflow.com-Comments.7z
wget -c https://archive.org/download/stackexchange/stackoverflow.com-PostHistory.7z
wget -c https://archive.org/download/stackexchange/stackoverflow.com-PostLinks.7z
wget -c https://archive.org/download/stackexchange/stackoverflow.com-Posts.7z
wget -c https://archive.org/download/stackexchange/stackoverflow.com-Tags.7z
wget -c https://archive.org/download/stackexchange/stackoverflow.com-Users.7z
wget -c https://archive.org/download/stackexchange/stackoverflow.com-Votes.7z
