#!/bin/bash
# SPDX-License-Identifier: MIT
set -euo pipefail

clone_package() {
	local name="$1" repo="$2" branch="$3" mode="${4:-name}"
	local checkout="${repo#*/}"
	rm -rf "$name" "$checkout"
	git clone --depth=1 --single-branch --branch "$branch" "https://github.com/$repo.git" "$checkout"
	case "$mode" in
		name)
			if [ "$checkout" != "$name" ]; then
				mv "$checkout" "$name"
			fi
			;;
		pkg)
			local source
			source="$(find "$checkout" -mindepth 1 -maxdepth 4 -type d -name "$name" -print -quit)"
			[ -n "$source" ] || { echo "package not found: $name in $repo" >&2; exit 1; }
			mv "$source" "$name"
			rm -rf "$checkout"
			;;
		*) echo "invalid package mode: $mode" >&2; exit 1 ;;
	esac
}

# H5000M / RG520N-CN 专用组件
clone_package "luci-app-modemserver" "a10463981/modem-5g" "master"
clone_package "luci-app-h5000m-fancontrol" "FAN789/luci-app-h5000m-fancontrol" "main"
clone_package "luci-app-h5000m-netmode" "LianXia233/luci-app-h5000m-netmode" "main"

# iStoreOS 风格与商店。iStore 必须保留完整仓库目录，
# 否则 luci-app-store 的 luci-lib-taskd/taskd 依赖不会进入构建系统。
clone_package "luci-theme-design" "0x676e67/luci-theme-design" "main"
# ImmortalWrt master 已使用 APK 打包器。上游主题的版本号
# 5.8.0-20240106 会被 APK 判定为非法 package version；保留版本语义，
# 仅把日期前的连字符规范化为点号。
THEME_MAKEFILE="luci-theme-design/Makefile"
sed -i -E 's/^(PKG_VERSION:=[0-9][0-9A-Za-z.+~]*)-([0-9]{8})$/\1.\2/' "$THEME_MAKEFILE"
if grep -qE '^PKG_VERSION:=.*-[0-9]{8}$' "$THEME_MAKEFILE"; then
	echo "unsupported luci-theme-design version format" >&2
	exit 1
fi
clone_package "istore" "linkease/istore" "main"

# 用户指定的第三方功能
clone_package "luci-app-passwall2" "Openwrt-Passwall/openwrt-passwall2" "main" "pkg"
clone_package "luci-app-easytier" "EasyTier/luci-app-easytier" "main"
# 该聚合仓库提供 gecoosac 与 wolultra 等包。
clone_package "viking" "VIKINGYFY/packages" "main"

clone_package "luci-app-online-upgrade" "gooyjq/luci-app-online-upgrade" "main"

if [ -f "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh" ]; then
	source "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh"
fi
