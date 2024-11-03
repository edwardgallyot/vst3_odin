odin build . -build-mode:dll -debug -file  -no-entry-point -min-link-libs -no-threaded-checker

echo Post Build Started.
    if [ -d odin.vst3 ]; then 
        echo Cleaning Bundle
        rm -rf sami.vst3
    fi
    
    if [ -e odin.so ]; then 
        echo Copying Lib to Bundle
        mkdir -p odin.vst3/Contents/x86_64-linux
        cp odin.so odin.vst3/Contents/x86_64-linux/odin.so
    fi

    if [ ! -d $HOME/.vst3 ]; then
        mkdir $HOME/.vst3
    fi

    if [ -d odin.vst3 ]; then 
        echo Copying Bundle to System Folders 
        cp -r odin.vst3 $HOME/.vst3
    fi
echo Post Build Completed.

