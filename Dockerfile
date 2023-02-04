##########################################
#         构建可执行二进制文件             #
##########################################
# 指定构建的基础镜像
FROM golang:alpine AS builder

# 作者描述信息
MAINTAINER danxiaonuo
# 时区设置
ARG TZ=Asia/Shanghai
ENV TZ=$TZ
# 语言设置
ARG LANG=C.UTF-8
ENV LANG=$LANG

# GO环境变量
ARG GOPROXY=""
ENV GOPROXY ${GOPROXY}
ARG GO111MODULE=on
ENV GO111MODULE=$GO111MODULE
ARG CGO_ENABLED=1
ENV CGO_ENABLED=$CGO_ENABLED

# 源文件下载路径
ARG DOWNLOAD_SRC=/tmp/src
ENV DOWNLOAD_SRC=$DOWNLOAD_SRC

ARG PKG_DEPS="\
      gcc \
      musl-dev \
      git \
      linux-headers \
      build-base \
      zlib-dev \
      openssl \
      openssl-dev \
      fuse3 \
      tzdata \
      curl \
      wget \
      lsof \
      zip \
      unzip \
      ca-certificates"
ENV PKG_DEPS=$PKG_DEPS

# ***** 安装依赖并构建二进制文件 *****
RUN set -eux && \
   # 修改源地址
   sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
   # 更新源地址并更新系统软件
   apk update && apk upgrade && \
   # 安装依赖包
   apk add --no-cache --clean-protected $PKG_DEPS && \
   rm -rf /var/cache/apk/* && \
   # 更新时区
   ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \
   # 更新时间
   echo ${TZ} > /etc/timezone && \
   # 克隆源码运行安装
   git clone --depth=1 -b master --progress https://github.com/miquels/webdavfs.git /src && \
   cd /src && export COMMIT=$(git rev-parse --short HEAD) && \
   go env -w GO111MODULE=on && \
   go env -w CGO_ENABLED=1 && \
   go env && \
   go mod tidy && \
   go get && go build

##########################################
#         构建基础镜像                    #
##########################################
# 
# 指定创建的基础镜像
FROM alpine AS dist

# 作者描述信息
MAINTAINER danxiaonuo
# 时区设置
ARG TZ=Asia/Shanghai
ENV TZ=$TZ
# 语言设置
ARG LANG=C.UTF-8
ENV LANG=$LANG
# 用户ID
ENV OWNER=0
# 挂载目录
ENV WEBDRIVE_MOUNT=/mnt/webdrive
# URL地址
ENV WEBDRIVE_URL=
# 用户名
ENV WEBDRIVE_USERNAME=
# 密码
ENV WEBDRIVE_PASSWORD=

ARG PKG_DEPS="\
      zsh \
      bash \
      bash-doc \
      bash-completion \
      bind-tools \
      iproute2 \
      ipset \
      git \
      vim \
      tzdata \
      curl \
      wget \
      lsof \
      zip \
      unzip \
      tini \
      fuse3 \
      ca-certificates"
ENV PKG_DEPS=$PKG_DEPS

# ***** 安装依赖 *****
RUN set -eux && \
   # 修改源地址
   sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
   # 更新源地址并更新系统软件
   apk update && apk upgrade && \
   # 安装依赖包
   apk add --no-cache --clean-protected $PKG_DEPS && \
   rm -rf /var/cache/apk/* && \
   # 更新时区
   ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \
   # 更新时间
   echo ${TZ} > /etc/timezone && \
   # 更改为zsh
   sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true && \
   sed -i -e "s/bin\/ash/bin\/zsh/" /etc/passwd && \
   sed -i -e 's/mouse=/mouse-=/g' /usr/share/vim/vim*/defaults.vim && \
   /bin/zsh
   
# 拷贝webdavfs
COPY --from=builder /src/webdavfs /sbin/mount.webdavfs

# 拷贝文件
COPY ["COPY ./scripts/*.sh", "/usr/bin/"]
 
# 授予文件权限
RUN set -eux && \
    chmod a+x /usr/bin/*.sh /sbin/mount.webdavfs
 
# 容器信号处理
STOPSIGNAL SIGQUIT

# ***** 挂载目录 *****
VOLUME ${WEBDRIVE_MOUNT}

# ***** 入口 *****
ENTRYPOINT [ "tini", "-g", "--", "/usr/bin/docker-entrypoint.sh" ]

# ***** 命令 *****
CMD [ "ls.sh" ]
