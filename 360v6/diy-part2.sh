#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

#git clone https://github.com/kiddin9/luci-theme-edge package/luci-theme-edge
#git clone https://github.com/1wrt/luci-app-ikoolproxy.git package/luci-app-ikoolproxy
#rm -rf package/lean/luci-theme-argon
#git clone https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
#git clone https://github.com/TorBoxCode/luci-app-tencentddns package/luci-app-tencentddns
#git clone https://github.com/vernesong/OpenClash.git package/luci-app-openclash
