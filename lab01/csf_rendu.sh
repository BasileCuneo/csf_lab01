#!/bin/bash

PROJECT_DIR=code
REPORT_FILE=rapport.pdf
ARCHIVE=rendu.tar.gz

if [ ! -d "$PROJECT_DIR" ]
then
    echo "Could not find $PROJECT_DIR directory in $(pwd)" >&2
    exit 1
fi


if [ ! -f "$REPORT_FILE" ]
then
    echo "Could not find project file : $REPORT_FILE" >&2
    exit 1
fi

echo "The following files are archived in $ARCHIVE : "
tar --exclude='rendu.tar.gz' --exclude='*.o' --exclude='comp' --exclude='sim' --exclude='synth' -czvf $ARCHIVE $PROJECT_DIR $REPORT_FILE
