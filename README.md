## Idea

Big script would clone whole configuration using git

## Why would that be big?

The idea is that this script would be near perfect in case of attention to details.
It would work as intended for every occasion and every computer with bash/zsh in it.

My configuration can get very messy so that would be big of a deal.
The main point is attention to details - making the config accessible in one
place using symbolic links, saving previous configuration so that it's not
lost after using my script, easy reverting of the result, etc.

## Intended functionality

- check if command present, else ...
- check internet connection
- move current config into temporary directory/files
- keep new config in just one directory
- create symlinks in proper places
- **NO** situations where script fails (unexpectedly)
- CLI script
