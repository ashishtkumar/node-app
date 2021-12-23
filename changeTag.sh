#!/bin/bash
sed -i "s/tagVersion/$1/g" pods.yml > node-app-pod.yml
