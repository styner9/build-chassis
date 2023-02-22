#!/usr/bin/env bash
git checkout master && \
git pull && \
git describe --abbrev=0 | xargs git -c advice.detachedHead=false checkout