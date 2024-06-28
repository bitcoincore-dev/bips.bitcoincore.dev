#!/usr/bin/env bash

find bips -maxdepth 1 -type f -name 'bip*.mediawiki' \
    | cargo run -- generate
