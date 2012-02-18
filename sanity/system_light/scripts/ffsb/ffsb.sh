#!/bin/bash

function main ()
{
    cp $BIN_PATH/system_light/profile_everything $THIS_TEST_DIR/profile_everything
    sed -i "s[/mnt/test1[$THIS_TEST_DIR[" profile_everything
    $TOOLDIR/ffsb_run.sh
    if [ "${?}" -eq 0 ]; then
        echo "Removing data"
        rm -rfv data && echo "Removed"
        echo "Removing meta"
        rm -rfv meta && echo "Removed"
        echo "Removing profile_everything"
        rm $FFSB_FILE && echo "Removed"
        return 0;
    else
        return 1;
    fi
}

main "$@"