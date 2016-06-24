#!/bin/bash

ssh -fN quest.ms.mff.cuni.cz -L2244:kontext-dev:22
#sshfs -p2244 -o follow_symlinks localhost:/opt/lindat /tmp/test
#cd ~/sources/lindat-kontext
#git remote add deploy ssh://localhost:2244/opt/lindat/kontext.git
#when finished:
#umount
#fusermount -u /tmp/test
#destroy the tunnel
#ps ax| grep ssh.*2244 | grep -v grep | cut -d" " -f1 | xargs kill
