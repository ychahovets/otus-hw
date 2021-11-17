#!/bin/bash
WORD=$1
LOG=$2
DATE=$(date)
if grep $WORD $LOG &>/dev/null; then
    logger "$DATE: keyword found!"
else
    exit 0
fi