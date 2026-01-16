#!/bin/bash
export QT_QPA_PLATFORM=eglfs
export QT_QPA_EGLFS_INTEGRATION=eglfs_kms
export QT_QPA_EGLFS_KMS_ATOMIC=1

cd /home/samna/dev/signage
./build/signage_player
