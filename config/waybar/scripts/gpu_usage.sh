#!/bin/bash

nvtop -s 2>/dev/null | jq -r '.[0].gpu_util // empty' | tr -d '%'
