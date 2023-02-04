exit_script() {
    SIGNAL=$1
    echo "Caught $SIGNAL! Unmounting ${DEST}..."
    umount -l ${DEST}
    webdavfs=$(ps -o pid= -o comm= | grep mount.webdavfs | sed -E 's/\s*(\d+)\s+.*/\1/g')
    if [ -n "$webdavfs" ]; then
        echo "转发 $SIGNAL 去 $webdavfs"
        while $(kill -$SIGNAL $webdavfs 2> /dev/null); do
            sleep 1
        done
    fi
    trap - $SIGNAL # clear the trap
    exit $?
}

trap "exit_script INT" INT
trap "exit_script TERM" TERM
