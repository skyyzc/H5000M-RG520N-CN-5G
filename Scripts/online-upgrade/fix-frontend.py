#!/usr/bin/env python3
"""fix-frontend.py - 修复 luci-app-online-upgrade 前端 JS
将硬编码默认值替换为从 UCI 读取实际配置，并支持全字段保存。
"""

import sys, re

def fix_js(js_path):
    with open(js_path, 'r', encoding='utf-8') as f:
        js = f.read()

    # 1) 替换 Release 地址硬编码 → 加载中占位
    js = js.replace(
        "value: 'https://github.com/gooyjq/ImmortalWrt-Builder/releases/tag/Autobuild-x86-64'",
        "value: '加载中...'"
    )

    # 2) 移除 repo/tag/pattern 的 readonly 限制，清空硬编码值
    js = js.replace(
        "value: 'gooyjq/ImmortalWrt-Builder', readonly: 'readonly'",
        "value: ''"
    )
    js = js.replace(
        "value: 'Autobuild-x86-64', readonly: 'readonly'",
        "value: ''"
    )
    js = js.replace(
        "value: 'auto（自动检测）', readonly: 'readonly'",
        "value: ''"
    )

    # 3) 扩展 saveCfg 函数
    old_save = """		function saveCfg() {
			var g = function(id) { return (document.getElementById(id) || {}).value || ''; };
			var cmd = "uci set online-upgrade.settings.repo='" + g('cfg-repo').replace(/'/g,"'\\\\''") + "' && uci set online-upgrade.settings.tag='" + g('cfg-tag').replace(/'/g,"'\\\\''") + "' && uci commit online-upgrade";
			fs.exec('/bin/sh', ['-c', cmd]).then(function() {
				ui.addNotification(null, E('p', '配置已保存'), 'info');
			});
		}"""

    new_save = """		function saveCfg() {
			var g = function(id) { return (document.getElementById(id) || {}).value || ''; };
			var esc = function(s) { return s.replace(/'/g, "'\\\\''"); };
			var cmd = "uci set online-upgrade.settings.repo='" + esc(g('cfg-repo')) + "'";
			cmd += " && uci set online-upgrade.settings.tag='" + esc(g('cfg-tag')) + "'";
			cmd += " && uci set online-upgrade.settings.firmware_pattern='" + esc(g('cfg-pattern')) + "'";
			cmd += " && uci set online-upgrade.settings.proxy='" + esc(g('cfg-proxy')) + "'";
			cmd += " && uci commit online-upgrade";
			fs.exec('/bin/sh', ['-c', cmd]).then(function() {
				ui.addNotification(null, E('p', '配置已保存'), 'info');
			});
		}"""

    if old_save in js:
        js = js.replace(old_save, new_save)
    else:
        print("WARNING: saveCfg pattern not matched, skipping replacement", file=sys.stderr)

    # 4) 在 "// 读取当前版本和备份状态" 之前注入 UCI 加载逻辑
    uci_load = """		// 读取 UCI 配置填充表单
		setTimeout(function() {
			fs.exec('/bin/sh', ['-c', 'uci -q get online-upgrade.settings.repo && echo "|||" && uci -q get online-upgrade.settings.tag && echo "|||" && uci -q get online-upgrade.settings.firmware_pattern && echo "|||" && uci -q get online-upgrade.settings.proxy']).then(function(r) {
				var parts = (r.stdout || '').trim().split('|||');
				var repo = (parts[0] || '').trim();
				var tag = (parts[1] || '').trim();
				var pattern = (parts[2] || '').trim();
				var proxy = (parts[3] || '').trim();
				if (repo) {
					var repoEl = document.getElementById('cfg-repo'); if (repoEl) repoEl.value = repo;
					var urlEl = document.getElementById('cfg-url');
					if (urlEl) urlEl.value = 'https://github.com/' + repo + (tag ? '/releases/tag/' + tag : '');
				}
				if (tag) { var tagEl = document.getElementById('cfg-tag'); if (tagEl) tagEl.value = tag; }
				var patternEl = document.getElementById('cfg-pattern');
				if (patternEl) patternEl.value = pattern || 'auto（自动检测）';
				if (proxy) { var proxyEl = document.getElementById('cfg-proxy'); if (proxyEl) proxyEl.value = proxy; }
			});
		}, 50);

"""

    marker = "\t\t// 读取当前版本和备份状态"
    if marker in js:
        js = js.replace(marker, uci_load + marker)
    else:
        print("WARNING: version-load marker not found, skipping UCI load injection", file=sys.stderr)

    with open(js_path, 'w', encoding='utf-8') as f:
        f.write(js)

    print(f"online-upgrade: frontend JS patched ({js_path})")


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("usage: fix-frontend.py <online-upgrade.js>", file=sys.stderr)
        sys.exit(1)
    fix_js(sys.argv[1])
