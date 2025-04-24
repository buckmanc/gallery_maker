#!/usr/bin/env bash

git status --short | grep -ivP '(\.jpe?g|\.png|\.gif|\.webp)"?$'
