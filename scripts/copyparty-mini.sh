#!/bin/sh

source ~/.zshenv/init/copyparty-env.sh
source ~/.zshenv/post/mac-mini.sh

copyparty-mini & copyparty-cloudflared
