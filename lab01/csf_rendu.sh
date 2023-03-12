#!/bin/bash

PROJECT_DIR_BASILE=basile
PROJECT_DIR_JEREMY=jeremy
PROJECT_DIR_KRISTINA=kristina
REPORT_FILE=rapport.pdf
ARCHIVE=rendu.tar.gz

if [ ! -d "$PROJECT_DIR_BASILE" ]
then
    echo "Could not find $PROJECT_DIR_BASILE directory in $(pwd)" >&2
    exit 1
fi

if [ ! -d "$PROJECT_DIR_JEREMY" ]
then
    echo "Could not find $PROJECT_DIR_JEREMY directory in $(pwd)" >&2
    exit 1
fi

if [ ! -d "$PROJECT_DIR_KRISTINA" ]
then
    echo "Could not find $PROJECT_DIR_KRISTINA directory in $(pwd)" >&2
    exit 1
fi

if [ ! -f "$REPORT_FILE" ]
then
    echo "Could not find project file : $REPORT_FILE" >&2
    exit 1
fi

echo "The following files are archived in $ARCHIVE : "
tar --exclude='rendu.tar.gz' --exclude='*.o' --exclude='comp' --exclude='sim' --exclude='synth' -czvf $ARCHIVE $PROJECT_DIR_BASILE $PROJECT_DIR_JEREMY $PROJECT_DIR_KRISTINA $REPORT_FILE
