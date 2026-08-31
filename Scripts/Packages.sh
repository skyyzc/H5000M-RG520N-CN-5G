#!/bin/bash
# SPDX-License-Identifier: MIT
set -euo pipefail

clone_package() {
	local name="$1" repo="$2" branch="$3" mode="${4:-name}"
	local checkout="${repo#*/}"
	rm -rf "$name" "$checkout"
	git clone --depth=1 --single-branch --branch "$branch" "https://github.com/$repo.git" "$checkout"
	case "$mode" in
		name) mv "$checkout" "$name" ;;
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

# iStoreOS 风格与商店
clone_package "luci-theme-design" "0x676e67/luci-theme-design" "main"
clone_package "luci-app-store" "linkease/istore" "main" "pkg"

# 用户指定的第三方功能
clone_package "luci-app-passwall2" "Openwrt-Passwall/openwrt-passwall2" "main" "pkg"
clone_package "luci-app-easytier" "EasyTier/luci-app-easytier" "main"
# 该聚合仓库提供 gecoosac 与 wolultra 等包。
clone_package "viking" "VIKINGYFY/packages" "main"

clone_package "luci-app-online-upgrade" "gooyjq/luci-app-online-upgrade" "main"

if [ -f "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh" ]; then
	source "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh"
fi
