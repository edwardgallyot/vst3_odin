#!/bin/zsh

function build_example() {
    EXAMPLE_NAME="$1"

    echo "\nbuilding $EXAMPLE_NAME.vst3\n"

    cd "example/$EXAMPLE_NAME"
    echo Building
    odin build . -build-mode:dll -debug -file  -no-entry-point -min-link-libs -no-threaded-checker

    echo Post Build Started.
        if [ -d "$EXAMPLE_NAME.vst3" ]; then 
            echo Cleaning Bundle
            rm -rf "$EXAMPLE_NAME.vst3"
        fi
        
        if [ -e "$EXAMPLE_NAME.so" ]; then 
            echo Copying Lib to Bundle
            mkdir -p "$EXAMPLE_NAME.vst3/Contents/x86_64-linux"
            cp "$EXAMPLE_NAME.so" "$EXAMPLE_NAME.vst3/Contents/x86_64-linux/$EXAMPLE_NAME.so"
        fi

        if [ ! -d $HOME/.vst3 ]; then
            mkdir $HOME/.vst3
        fi

        if [ -d "$EXAMPLE_NAME.vst3" ]; then 
            echo Copying Bundle to System Folders 
            cp -r "$EXAMPLE_NAME.vst3" $HOME/.vst3
        fi
    echo Post Build Completed.

    cd -
}

# Uncomment these to build them:
build_example "tone_generator"
# build_example "gain_no_gui"
# build_example "gain"
