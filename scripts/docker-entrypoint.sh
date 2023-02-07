#! /usr/bin/env sh

# 在容器中挂载webdav目录
DEST=${WEBDRIVE_MOUNT:-/mnt/webdrive}

# 检查变量和默认值
if [ -z "${WEBDRIVE_URL}" ]; then
    echo "没有指定URL!"
    exit
fi
if [ -z "${WEBDRIVE_USERNAME}" ]; then
    echo "没有指定用户名！"
fi
if [ -z "${WEBDRIVE_PASSWORD}" ]; then
    echo "没有指定密码！"
fi

# 如果目标目录不存在，请创建目标目录。
if [ ! -d $DEST ]; then
    mkdir -p $DEST
fi

# 处理所有权问题
if [ $OWNER -gt 0 ]; then
    adduser webdrive -u $OWNER -D -G users
    chown webdrive $DEST
fi

# 挂载并验证是否存在某些内容
mount -t webdavfs -ousername=$WEBDRIVE_USERNAME,password=$WEBDRIVE_PASSWORD,rwdirops,maxconns=65535,uid=$OWNER,gid=$OGID,mode=755 $WEBDRIVE_URL $DEST
nsenter -t $(pgrep tini) -m -- mount --verbose --make-shared $DEST

# 检测挂载成功。执行成功后执行该命令。
if [ -n "$(ls -1A $DEST)" ]; then
    echo "安装 $WEBDRIVE_URL 到 $DEST"
    exec "$@"
else
    echo "没有发现$DEST！"
fi
