#!/usr/bin/env bash

command grep -hoE "https?://[^ ,()'\"]+" -- *.log | \
sed -E "s;^https:;http:;g" | \
sed -E "s;/$;;g" | \
sort | \
uniq
