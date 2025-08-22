
#!/bin/bash

# 安装额外依赖软件包
# sudo -E apt-get -y install rename

# 更新feeds文件
# sed -i 's@#src-git helloworld@src-git helloworld@g' feeds.conf.default # 启用helloworld
# sed -i 's@src-git luci@# src-git luci@g' feeds.conf.default # 禁用18.06Luci
# sed -i 's@## src-git luci@src-git luci@g' feeds.conf.default # 启用23.05Luci
cat feeds.conf.default

# 添加第三方软件包
git clone https://github.com/kenzok8/openwrt-packages.git package/kenzok8

# 更新并安装源
#./scripts/feeds clean
./scripts/feeds update -a && ./scripts/feeds install -a -f

# 删除部分默认包
rm -rf feeds/luci/applications/luci-app-qbittorrent
rm -rf feeds/luci/applications/luci-app-openclash
rm -rf feeds/luci/themes/luci-theme-argon

# 自定义定制选项
NET="package/base-files/luci2/bin/config_generate"
ZZZ="package/lean/default-settings/files/zzz-default-settings"
# 读取内核版本
KERNEL_PATCHVER=$(cat target/linux/mediatek/Makefile|grep KERNEL_PATCHVER | sed 's/^.\{17\}//g')
KERNEL_TESTING_PATCHVER=$(cat target/linux/mediatek/Makefile|grep KERNEL_TESTING_PATCHVER | sed 's/^.\{25\}//g')
#if [[ $KERNEL_TESTING_PATCHVER > $KERNEL_PATCHVER ]]; then
#  sed -i "s/$KERNEL_PATCHVER/$KERNEL_TESTING_PATCHVER/g" target/linux/mediatek/Makefile        # 修改内核版本为最新
#  echo "内核版本已更新为 $KERNEL_TESTING_PATCHVER"
#else
# echo "内核版本不需要更新"
#fi

#
#sed -i 's#192.168.1.1#10.0.0.1#g' $NET                                                    # 定制默认IP
# sed -i 's#LEDE#OpenWrt-jdcloud#g' $NET                                                     # 修改默认名称为OpenWrt-jdcloud
sed -i 's@.*CYXluq4wUazHjmCDBCqXF*@#&@g' $ZZZ                                             # 取消系统默认密码
sed -i "s/LEDE /ONE build $(TZ=UTC-8 date "+%Y.%m.%d") @ LEDE /g" $ZZZ              # 增加自己个性名称
echo "uci set luci.main.mediaurlbase=/luci-static/argon" >> $ZZZ                      # 设置默认主题(如果编译可会自动修改默认主题的，有可能会失效)

# ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●● #

sed -i 's#localtime  = os.date()#localtime  = os.date("%Y年%m月%d日") .. " " .. translate(os.date("%A")) .. " " .. os.date("%X")#g' package/lean/autocore/files/*/index.htm               # 修改默认时间格式
sed -i 's#%D %V, %C#%D %V, %C Lean_jdcloud#g' package/base-files/files/etc/banner               # 自定义banner显示
# sed -i 's@list listen_https@# list listen_https@g' package/network/services/uhttpd/files/uhttpd.config               # 停止监听443端口
# sed -i 's#option commit_interval 24h#option commit_interval 10m#g' feeds/packages/net/nlbwmon/files/nlbwmon.config               # 修改流量统计写入为10分钟
# sed -i 's#option database_generations 10#option database_generations 3#g' feeds/packages/net/nlbwmon/files/nlbwmon.config               # 修改流量统计数据周期
# sed -i 's#option database_directory /var/lib/nlbwmon#option database_directory /etc/config/nlbwmon_data#g' feeds/packages/net/nlbwmon/files/nlbwmon.config               # 修改流量统计数据存放默认位置
# sed -i 's#interval: 5#interval: 1#g' feeds/luci/applications/luci-app-wrtbwmon/htdocs/luci-static/wrtbwmon/wrtbwmon.js               # wrtbwmon默认刷新时间更改为1秒
# sed -i '/exit 0/i\ethtool -s eth0 speed 10000 duplex full' package/base-files/files//etc/rc.local               # 强制显示2500M和全双工（默认PVE下VirtIO不识别）

# ●●●●●●●●●●●●●●●●●●●●●●●●定制部分●●●●●●●●●●●●●●●●●●●●●●●● #

# ================ 网络设置 =======================================

# 如果有用IPV6的话,可以使用以下命令创建IPV6客户端(LAN口)（去掉全部代码uci前面#号生效）
uci set network.ipv6=interface
uci set network.ipv6.proto='dhcpv6'
uci set network.ipv6.ifname='@lan'
uci set network.ipv6.reqaddress='try'
uci set network.ipv6.reqprefix='auto'
uci set firewall.@zone[0].network='lan ipv6'

uci commit dhcp
uci commit network
uci commit firewall

EOF

# =======================================================

# 检查 OpenClash 是否启用编译
if grep -qE '^(CONFIG_PACKAGE_luci-app-openclash=n|# CONFIG_PACKAGE_luci-app-openclash=)' "${WORKPATH}/$CUSTOM_SH"; then
  # OpenClash 未启用，不执行任何操作
  echo "OpenClash 未启用编译"
  echo 'rm -rf /etc/openclash' >> $ZZZ
else
  # OpenClash 已启用，执行配置
  if grep -q "CONFIG_PACKAGE_luci-app-openclash=y" "${WORKPATH}/$CUSTOM_SH"; then
    # 判断系统架构
    arch=$(uname -m)  # 获取系统架构
    case "$arch" in
      x86_64)
        arch="amd64"
        ;;
      aarch64|arm64)
        arch="arm64"
        ;;
    esac
    # OpenClash Meta 开始配置内核
    echo "正在执行：为OpenClash下载内核"
    mkdir -p $HOME/clash-core
    mkdir -p $HOME/files/etc/openclash/core
    cd $HOME/clash-core
    # 下载Meta内核
    wget -q https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-$arch.tar.gz
    if [[ $? -ne 0 ]];then
      wget -q https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-$arch.tar.gz
    else
      echo "OpenClash Meta内核压缩包下载成功，开始解压文件"
    fi
    tar -zxvf clash-linux-$arch.tar.gz
    if [[ -f "$HOME/clash-core/clash" ]]; then
      mv -f $HOME/clash-core/clash $HOME/files/etc/openclash/core/clash_meta
      chmod +x $HOME/files/etc/openclash/core/clash_meta
      echo "OpenClash Meta内核配置成功"
    else
      echo "OpenClash Meta内核配置失败"
    fi
    rm -rf $HOME/clash-core/clash-linux-$arch.tar.gz
    rm -rf $HOME/clash-core
  fi
fi

# =======================================================

# 修改退出命令到最后
cd $HOME && sed -i '/exit 0/d' $ZZZ && echo "exit 0" >> $ZZZ

# ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●● #


# 创建自定义配置文件

cd $WORKPATH
touch ./.config

#
# ●●●●●●●●●●●●●●●●●●●●●●●●固件定制部分●●●●●●●●●●●●●●●●●●●●●●●●
# 

# 
# 如果不对本区块做出任何编辑, 则生成默认配置固件. 
# 

# 以下为定制化固件选项和说明:
#

#
# 有些插件/选项是默认开启的, 如果想要关闭, 请参照以下示例进行编写:
# 
#          ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#        ■|  # 取消编译VMware镜像:                    |■
#        ■|  cat >> .config <<EOF                   |■
#        ■|  # CONFIG_VMDK_IMAGES is not set        |■
#        ■|  EOF                                    |■
#          ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#

# 
# 以下是一些提前准备好的一些插件选项.
# 直接取消注释相应代码块即可应用. 不要取消注释代码块上的汉字说明.
# 如果不需要代码块里的某一项配置, 只需要删除相应行.
#
# 如果需要其他插件, 请按照示例自行添加.
# 注意, 只需添加依赖链顶端的包. 如果你需要插件 A, 同时 A 依赖 B, 即只需要添加 A.
# 
# 无论你想要对固件进行怎样的定制, 都需要且只需要修改 EOF 回环内的内容.
# 

# 编译百里固件:
cat >> .config <<EOF
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_jdcloud_re-cs-05=y
EOF

# 固件压缩:
cat >> .config <<EOF
CONFIG_TARGET_IMAGES_GZIP=y
EOF

# IPv6支持:
cat >> .config <<EOF
CONFIG_PACKAGE_dnsmasq_full_dhcpv6=y
CONFIG_PACKAGE_ipv6helper=y
EOF

# 多文件系统支持:
# cat >> .config <<EOF
# CONFIG_PACKAGE_kmod-fs-nfs=y
# CONFIG_PACKAGE_kmod-fs-nfs-common=y
# CONFIG_PACKAGE_kmod-fs-nfs-v3=y
# CONFIG_PACKAGE_kmod-fs-nfs-v4=y
# CONFIG_PACKAGE_kmod-fs-ntfs=y
# CONFIG_PACKAGE_kmod-fs-squashfs=y
# EOF

# USB3.0支持:
# cat >> .config <<EOF
# CONFIG_PACKAGE_kmod-usb-ohci=y
# CONFIG_PACKAGE_kmod-usb-ohci-pci=y
# CONFIG_PACKAGE_kmod-usb2=y
# CONFIG_PACKAGE_kmod-usb2-pci=y
# CONFIG_PACKAGE_kmod-usb3=y
# EOF

# 多线多拨:
# cat >> .config <<EOF
# CONFIG_PACKAGE_luci-app-syncdial=y #多拨虚拟WAN
# CONFIG_PACKAGE_luci-app-mwan3=y #MWAN负载均衡
# CONFIG_PACKAGE_luci-app-mwan3helper=n #MWAN3分流助手
# EOF

# 第三方插件选择:
cat >> .config <<EOF
# CONFIG_PACKAGE_luci-app-oaf=y #应用过滤
CONFIG_PACKAGE_luci-app-openclash=y #OpenClash客户端
#CONFIG_PACKAGE_luci-app-nikki=y #nikki 客户端
# CONFIG_PACKAGE_luci-app-serverchan=y #微信推送
# CONFIG_PACKAGE_luci-app-eqos=y #IP限速
# CONFIG_PACKAGE_luci-app-control-weburl=y #网址过滤
# CONFIG_PACKAGE_luci-app-smartdns=y #smartdns服务器
# CONFIG_PACKAGE_luci-app-adguardhome=y #ADguardhome
# CONFIG_PACKAGE_luci-app-argon-config=y #argon主题设置
# CONFIG_PACKAGE_luci-app-autotimeset=y #定时重启系统，网络
# CONFIG_PACKAGE_luci-app-ddnsto=y #小宝开发的DDNS.to内网穿透
# CONFIG_PACKAGE_ddnsto=y #DDNS.to内网穿透软件包
EOF


# Passwall插件:
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-passwall=y
# CONFIG_PACKAGE_luci-app-passwall2=y
# CONFIG_PACKAGE_naiveproxy=y
CONFIG_PACKAGE_chinadns-ng=y
# CONFIG_PACKAGE_brook=y
CONFIG_PACKAGE_trojan-go=y
CONFIG_PACKAGE_xray-plugin=y
CONFIG_PACKAGE_shadowsocks-rust-sslocal=n
EOF

# Turbo ACC 网络加速:
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-turboacc=y
EOF

# 常用LuCI插件:
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-adbyby-plus=n #adbyby去广告
CONFIG_PACKAGE_luci-app-webadmin=n #Web管理页面设置
CONFIG_PACKAGE_luci-app-ddns=n #DDNS服务
CONFIG_DEFAULT_luci-app-vlmcsd=n #KMS激活服务器
CONFIG_PACKAGE_luci-app-filetransfer=y #系统-文件传输
CONFIG_PACKAGE_luci-app-autoreboot=n #定时重启
CONFIG_PACKAGE_luci-app-upnp=n #通用即插即用UPnP(端口自动转发)
CONFIG_PACKAGE_luci-app-arpbind=n #IP/MAC绑定
CONFIG_PACKAGE_luci-app-accesscontrol=n #上网时间控制
CONFIG_PACKAGE_luci-app-wol=n #网络唤醒
CONFIG_PACKAGE_luci-app-nps=n #nps内网穿透
CONFIG_PACKAGE_luci-app-frpc=y #Frp内网穿透
CONFIG_PACKAGE_luci-app-nlbwmon=n #宽带流量监控
CONFIG_PACKAGE_luci-app-wrtbwmon=n #实时流量监测
CONFIG_PACKAGE_luci-app-haproxy-tcp=n #Haproxy负载均衡
CONFIG_PACKAGE_luci-app-diskman=n #磁盘管理磁盘信息
CONFIG_PACKAGE_luci-app-transmission=n #Transmission离线下载
CONFIG_PACKAGE_luci-app-qbittorrent=n #qBittorrent离线下载
CONFIG_PACKAGE_luci-app-amule=n #电驴离线下载
CONFIG_PACKAGE_luci-app-xlnetacc=n #迅雷快鸟
CONFIG_PACKAGE_luci-app-zerotier=n #zerotier内网穿透
CONFIG_PACKAGE_luci-app-hd-idle=n #磁盘休眠
CONFIG_PACKAGE_luci-app-unblockmusic=n #解锁网易云灰色歌曲
CONFIG_PACKAGE_luci-app-airplay2=n #Apple AirPlay2音频接收服务器
CONFIG_PACKAGE_luci-app-music-remote-center=n #PCHiFi数字转盘遥控
CONFIG_PACKAGE_luci-app-usb-printer=n #USB打印机
CONFIG_PACKAGE_luci-app-sqm=n #SQM智能队列管理
CONFIG_PACKAGE_luci-app-dockerman=y #Docker管理
CONFIG_PACKAGE_luci-app-ttyd=n #ttyd
#
# 文件共享相关(禁用):
#
CONFIG_PACKAGE_luci-app-minidlna=n #miniDLNA服务
CONFIG_PACKAGE_luci-app-vsftpd=n #FTP 服务器
CONFIG_PACKAGE_luci-app-samba=n #网络共享
CONFIG_PACKAGE_autosamba=n #网络共享
CONFIG_PACKAGE_samba36-server=n #网络共享
EOF

# LuCI主题:
cat >> .config <<EOF
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-theme-edge=n
EOF

# 常用软件包:
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-argon-config=y
CONFIG_PACKAGE_luci-app-lucky=y
CONFIG_PACKAGE_luci-app-mosdns=y
CONFIG_PACKAGE_luci-app-ikoolproxy=y
CONFIG_PACKAGE_luci-app-quickstart=y
CONFIG_PACKAGE_luci-app-store=y
CONFIG_PACKAGE_luci-i18n-quickstart-zh-cn=y
CONFIG_PACKAGE_quickstart=y
EOF

# 
# ●●●●●●●●●●●●●●●●●●●●●●●●固件定制部分结束●●●●●●●●●●●●●●●●●●●●●●●● #
# 

sed -i 's/^[ \t]*//g' ./.config

# 返回目录
cd $HOME

# 配置文件创建完成
