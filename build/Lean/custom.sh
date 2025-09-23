
#!/bin/bash

# 安装额外依赖软件包
# sudo -E apt-get -y install rename

# 更新feeds文件
# sed -i 's@#src-git helloworld@src-git helloworld@g' feeds.conf.default # 启用helloworld
# sed -i 's@src-git luci@# src-git luci@g' feeds.conf.default # 禁用18.06Luci
# sed -i 's@## src-git luci@src-git luci@g' feeds.conf.default # 启用23.05Luci
# sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
# sed -i '2i src-git small https://github.com/kenzok8/small' feeds.conf.default
sed -i '$a src-git smpackage https://github.com/kenzok8/small-package' feeds.conf.default
cat feeds.conf.default

# 添加第三方软件包
# git clone https://github.com/kenzok8/openwrt-packages.git package/kenzok8

# 更新并安装源
#./scripts/feeds clean
./scripts/feeds update -a && ./scripts/feeds install -a -f

# 删除部分默认包
rm -rf feeds/smpackage/{base-files,dnsmasq,firewall*,fullconenat,libnftnl,nftables,ppp,opkg,ucl,upx,vsftpd*,miniupnpd-iptables,wireless-regdb}
rm -rf feeds/luci/applications/luci-app-qbittorrent
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
sed -i "s/LEDE /WangYu build $(TZ=UTC-8 date "+%Y.%m.%d") @ LEDE /g" $ZZZ              # 增加自己个性名称
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

# LuCI主题:
cat >> .config <<EOF
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-theme-edge=n
EOF

# 常用软件包:
cat >> .config <<EOF
##---------下面配置可自行修改-------------
## 外部软件源插件
# CONFIG_PACKAGE_luci-app-oaf is not set
CONFIG_PACKAGE_luci-app-argon-config=y
# CONFIG_PACKAGE_luci-app-design-config is not set
CONFIG_PACKAGE_luci-app-lucky=y
CONFIG_PACKAGE_luci-app-mosdns=y
CONFIG_PACKAGE_luci-app-ikoolproxy=y
CONFIG_PACKAGE_luci-app-quickstart=y
CONFIG_PACKAGE_luci-app-store=y
CONFIG_PACKAGE_luci-i18n-quickstart-zh-cn=y
CONFIG_PACKAGE_quickstart=y
## koolproxy支持
CONFIG_PACKAGE_iptables-mod-nat-extra=y
CONFIG_PACKAGE_kmod-ipt-extra=y
CONFIG_PACKAGE_diffutils=y
CONFIG_PACKAGE_openssl-util=y
CONFIG_PACKAGE_dnsmasq-full=y
CONFIG_PACKAGE_ca-bundle=y
CONFIG_PACKAGE_ca-certificates=y
CONFIG_PACKAGE_libustream-openssl=y
CONFIG_PACKAGE_lua-openssl=y
## 默认feeds可选插件
CONFIG_PACKAGE_luci-app-autoupdate=y
CONFIG_PACKAGE_luci-app-dockerman=y
CONFIG_PACKAGE_luci-app-ttyd=y
CONFIG_PACKAGE_luci-app-homeproxy=y
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_luci-app-ddns=y
CONFIG_PACKAGE_ddns-scripts=y
CONFIG_PACKAGE_ddns-scripts_aliyun=y
CONFIG_PACKAGE_ddns-scripts-cloudflare=y
CONFIG_PACKAGE_ddns-scripts-cnkuai=y
CONFIG_PACKAGE_ddns-scripts-digitalocean=y
# CONFIG_PACKAGE_ddns-scripts-dnspod is not set
# CONFIG_PACKAGE_ddns-scripts-dnspod-com is not set
CONFIG_PACKAGE_ddns-scripts-freedns=y
CONFIG_PACKAGE_ddns-scripts-gandi=y
CONFIG_PACKAGE_ddns-scripts-godaddy=y
CONFIG_PACKAGE_ddns-scripts-noip=y
CONFIG_PACKAGE_ddns-scripts-nsupdate=y
CONFIG_PACKAGE_ddns-scripts-route53=y
CONFIG_PACKAGE_luci-app-arpbind=y
CONFIG_PACKAGE_luci-app-wechatpush=y
CONFIG_PACKAGE_luci-app-wol=y
CONFIG_PACKAGE_luci-app-vlmcsd=y
CONFIG_PACKAGE_luci-app-eqos=y
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-app-samba4=y
CONFIG_PACKAGE_luci-app-vsftpd=y
CONFIG_PACKAGE_luci-app-zerotier=y
CONFIG_PACKAGE_luci-app-openvpn-server=y
CONFIG_PACKAGE_luci-app-ipsec-vpnserver-manyusers=y
CONFIG_PACKAGE_tailscale=y
CONFIG_PACKAGE_luci-proto-wireguard=y
CONFIG_PACKAGE_qrencode=y
CONFIG_PACKAGE_coremark=y
CONFIG_PACKAGE_autocore=y
CONFIG_PACKAGE_iperf3=y
CONFIG_PACKAGE_vim=y
CONFIG_PACKAGE_nano=y
CONFIG_PACKAGE_zsh=y
CONFIG_PACKAGE_gdisk=y
CONFIG_PACKAGE_sgdisk=y
CONFIG_PACKAGE_kmod-fuse=y
CONFIG_PACKAGE_kmod-dm=y
CONFIG_PACKAGE_kmod-br-netfilter=y
CONFIG_PACKAGE_kmod-ikconfig=y
CONFIG_PACKAGE_kmod-nf-ipvs=y
CONFIG_PACKAGE_kmod-veth=y
## 针对eMMC加的一些文件系统和工具
CONFIG_PACKAGE_automount=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-f2fs=y
CONFIG_PACKAGE_e2fsprogs=y
CONFIG_PACKAGE_f2fs-tools=y
CONFIG_PACKAGE_lsblk=y
CONFIG_PACKAGE_mmc-utils=y
## 内存压缩
CONFIG_PACKAGE_zram-swap=y
## 其他
# CONFIG_PKG_FORTIFY_SOURCE_1 is not set
CONFIG_PKG_FORTIFY_SOURCE_2=y
CONFIG_PACKAGE_blkid=y
CONFIG_PACKAGE_blockd=y
CONFIG_PACKAGE_ca-certificates=y
CONFIG_PACKAGE_ethtool=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_ip-bridge=y
CONFIG_PACKAGE_ip6tables-extra=y
CONFIG_PACKAGE_ip6tables-mod-nat=y
CONFIG_PACKAGE_ipset=y
CONFIG_PACKAGE_iptables-mod-conntrack-extra=y
CONFIG_PACKAGE_iptables-mod-extra=y
CONFIG_PACKAGE_iptables-mod-filter=y
CONFIG_PACKAGE_iptables-mod-hashlimit=y
CONFIG_PACKAGE_iptables-mod-iface=y
CONFIG_PACKAGE_iptables-mod-ipmark=y
CONFIG_PACKAGE_iptables-mod-ipopt=y
CONFIG_PACKAGE_iptables-mod-iprange=y
CONFIG_PACKAGE_iptables-mod-ipv4options=y
CONFIG_PACKAGE_iptables-mod-nat-extra=y
CONFIG_PACKAGE_iptables-mod-proto=y
CONFIG_PACKAGE_iptables-mod-tee=y
CONFIG_PACKAGE_iptables-mod-tproxy=y
CONFIG_PACKAGE_iptables-mod-u32=y
CONFIG_PACKAGE_iw=y
CONFIG_PACKAGE_iwinfo=y
CONFIG_PACKAGE_kmod-ata-core=y
CONFIG_PACKAGE_kmod-ebtables=y
CONFIG_PACKAGE_kmod-ebtables-ipv4=y
CONFIG_PACKAGE_kmod-ebtables-ipv6=y
CONFIG_PACKAGE_kmod-fs-autofs4=y
CONFIG_PACKAGE_kmod-fs-vfat=y
CONFIG_PACKAGE_kmod-ifb=y
CONFIG_PACKAGE_kmod-inet-diag=y
CONFIG_PACKAGE_kmod-ip6tables-extra=y
CONFIG_PACKAGE_kmod-ipt-compat-xtables=y
CONFIG_PACKAGE_kmod-ipt-conntrack-extra=y
CONFIG_PACKAGE_kmod-ipt-extra=y
CONFIG_PACKAGE_kmod-ipt-filter=y
CONFIG_PACKAGE_kmod-ipt-hashlimit=y
CONFIG_PACKAGE_kmod-ipt-iface=y
CONFIG_PACKAGE_kmod-ipt-ipmark=y
CONFIG_PACKAGE_kmod-ipt-ipopt=y
CONFIG_PACKAGE_kmod-ipt-iprange=y
CONFIG_PACKAGE_kmod-ipt-ipv4options=y
CONFIG_PACKAGE_kmod-ipt-nat-extra=y
CONFIG_PACKAGE_kmod-ipt-offload=y
CONFIG_PACKAGE_kmod-ipt-proto=y
CONFIG_PACKAGE_kmod-ipt-raw6=y
CONFIG_PACKAGE_kmod-ipt-tee=y
CONFIG_PACKAGE_kmod-ipt-tproxy=y
CONFIG_PACKAGE_kmod-ipt-u32=y
CONFIG_PACKAGE_kmod-nf-flow=y
CONFIG_PACKAGE_kmod-nls-base=y
CONFIG_PACKAGE_kmod-nls-cp437=y
CONFIG_PACKAGE_kmod-nls-iso8859-1=y
CONFIG_PACKAGE_kmod-nls-utf8=y
CONFIG_PACKAGE_kmod-sched-core=y
CONFIG_PACKAGE_kmod-scsi-core=y
CONFIG_PACKAGE_kmod-tcp-bbr=y
CONFIG_PACKAGE_kmod-tun=y
CONFIG_PACKAGE_libatomic=y
CONFIG_PACKAGE_libblkid=y
CONFIG_PACKAGE_libcap-ng=y
CONFIG_PACKAGE_libcbor=y
CONFIG_PACKAGE_libevdev=y
CONFIG_PACKAGE_libfido2=y
CONFIG_PACKAGE_libipset=y
CONFIG_PACKAGE_libncurses=y
CONFIG_PACKAGE_libnl=y
CONFIG_PACKAGE_libnl-core=y
CONFIG_PACKAGE_libnl-genl=y
CONFIG_PACKAGE_libnl-nf=y
CONFIG_PACKAGE_libnl-route=y
CONFIG_PACKAGE_libopenssl-afalg_sync=y
CONFIG_PACKAGE_libopenssl-devcrypto=y
CONFIG_PACKAGE_libpcap=y
CONFIG_PACKAGE_libstdcpp=y
CONFIG_PACKAGE_libudev-zero=y
CONFIG_PACKAGE_openssh-keygen=y
CONFIG_PACKAGE_openssh-sftp-server=y
CONFIG_PACKAGE_openssl-util=y
CONFIG_PACKAGE_resolveip=y
CONFIG_PACKAGE_tc-tiny=y
CONFIG_PACKAGE_tcpdump=y
CONFIG_PACKAGE_terminfo=y
CONFIG_PACKAGE_wireless-regdb=y
CONFIG_PACKAGE_wireless-tools=y
CONFIG_PACKAGE_docker-compose=y
EOF

# 
# ●●●●●●●●●●●●●●●●●●●●●●●●固件定制部分结束●●●●●●●●●●●●●●●●●●●●●●●● #
# 

sed -i 's/^[ \t]*//g' ./.config

# 返回目录
cd $HOME

# 配置文件创建完成
