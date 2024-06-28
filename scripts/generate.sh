#!/usr/bin/env bash

find bips -maxdepth 1 -type f -name 'bip*.mediawiki' \
    | cargo run -- generate
find mints -maxdepth 1 -type f -name 'mint*.md' \
    | cargo run -- generate
