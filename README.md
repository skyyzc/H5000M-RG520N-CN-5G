# H5000M-RG520N-CN-5G

Hiveton H5000M（Quectel RG520N-CN）的 ImmortalWrt 25.12 快照固件云编译项目。源码固定为 [immortalwrt/immortalwrt](https://github.com/immortalwrt/immortalwrt) `master`，无需本地编译环境。

> 固件刷写可能导致设备变砖。首次请使用有线连接，备份配置和原厂分区，并确保已掌握 UART/恢复方案。本项目不会把 `inputs/` 内的原厂固件或设备清单推送到 GitHub。

## 编译

手动：进入仓库 **Actions → WRT-BUILD → Run workflow**，选择 `H5000M-qmodem-next` 或 `H5000M-qmodem`。两个名称为了保留指定的操作流程，当前都使用同一个 `a10463981/modem-5g`套件，不会混装 QModem。

自动：`Auto-Clean` 每天北京时间 05:00 运行，完成后触发 `MTK-AUTO`。两个配置分别发布到以配置名开头的 Release，默认保留每个配置最新的 Release。

Actions 启用工具链、下载目录和 2 GiB ccache 缓存，并在编译前清理 hosted runner 中与固件无关的大型预装 SDK。首次冷编译仍可能耗时数小时。编译失败时会保持并行重试，并在 Actions 注解中显示首个包级错误。

首次冷编译如果无法在 GitHub 时限内完成，先手动运行 `WRT-WARM`。该工作流仅构建工具链，并在 240 分钟安全上限后清理临时目标产物、保存增量缓存；如未完成可再运行一次续编。预热成功后再运行 `WRT-BUILD`。

## 预装内容

- RG520N-CN：`a10463981/modem-5g`，QMI，VID:PID `2c7c:0801`
- H5000M 风扇管理和网络模式切换
- iStore `luci-app-store` 与 Design 主题（iStoreOS 风格）
- HomeProxy、PassWall2、UPnP、定时重启、WOL Ultra、GecoOS AC、EasyTier
- FullCone NAT、AdGuard Home，以及在线固件升级

`modem-5g` 会替换 `usb-modeswitch` 的 USB 模式文件，所以配置中显式禁用了 `usb-modeswitch`。它的独立管理界面使用 8080 端口且上游默认无认证：请勿将该端口暴露到 WAN。

## 在线升级

构建时会把当前 GitHub 仓库、配置名、源码分支和 Release 标签写入 `/etc/online-upgrade-device`。LuCI **系统 → 在线升级** 会只查找同一配置的最新 `squashfs-sysupgrade.bin`，下载前依据 Release 资产信息匹配。默认直连 GitHub，不使用第三方下载代理。

## 依据与已知风险

- 实机清单：`mediatek/filogic`、`hiveton,h5000m`、USB RG520N-CN `2c7c:0801`，当前使用 QMI。
- ImmortalWrt `master` 已原生包含 H5000M 设备定义和 sysupgrade 路径。
- `modem-5g` 上游说明主要实测 RM520N-GL；RG520N-CN 与本机 VID:PID 命中其逻辑，但仍必须以首次真机回归确认拨号、上下电、热插拔和升级。
- iStore 官方仅保证 arm64/x86_64 商店本体可集成，商店内每个后装应用仍可能受 25.12 依赖差异影响。

## 主要上游

- [ImmortalWrt](https://github.com/immortalwrt/immortalwrt)
- [H5000M-CI-Qmodem](https://github.com/LianXia233/H5000M-CI-Qmodem)
- [OpenWRT-CI](https://github.com/VIKINGYFY/OpenWRT-CI)
- [modem-5g](https://github.com/a10463981/modem-5g)
- [H5000M fancontrol](https://github.com/FAN789/luci-app-h5000m-fancontrol)
- [H5000M netmode](https://github.com/LianXia233/luci-app-h5000m-netmode)
- [iStore](https://github.com/linkease/istore)
