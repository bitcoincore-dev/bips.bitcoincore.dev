#!/usr/bin/env bash

./scripts/bips.sh
./scripts/tailwind.sh
./scripts/static.sh
./scripts/generate.sh

cd web && zola build && cd ..
pagefind --site web/public
