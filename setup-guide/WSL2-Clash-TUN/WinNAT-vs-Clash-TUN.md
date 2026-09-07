# WinNAT vs Clash TUN — 为什么 WSL2 的 DNS 绕过了 mihomo

> Date: 2026-08-08 · Host: Windows 10 (19045) · WSL2: Debian (NAT mode)
> Clash Verge Rev: TUN mode ON (`Mihomo-Miku`, 198.18.0.1/30, `stack: system`, `strict-route: true`, `dns-hijack any:53`)
> 验证配置: 用户自建 `meta_redirect_host.yml`（Trojan to NA 节点）

---

## 1. WinNAT 是什么

**WinNAT**（Windows Network Address Translation）是 Windows 内置组件，为 WSL2 / Hyper-V / Docker Desktop 提供虚拟 NAT 网络。它运行在 `svchost.exe`（`SharedAccess` 服务）里。

在你这台机器上：

- WSL2 vSwitch（`vEthernet (WSL)`，子网 `172.22.80.0/20`）是私有网络；
- WSL2 的 Debian 拿到的地址是 `172.22.89.242/20`；
- WinNAT **拥有网关地址 `172.22.80.1`**（宿主机在该 vSwitch 上的地址），并把 WSL2 的流量 NAT 到真实网络。

## 2. WSL2 默认 DNS 路径

WSL2（NAT 模式）每次启动自动生成 `/etc/resolv.conf` → `nameserver 172.22.80.1`。

关键细节：**WinNAT 在 53 端口上绑定了一个 UDP socket**：

```
UDP 0.0.0.0:53 → svchost.exe (SharedAccess/WinNAT)   ← 已用 netstat 验证
```

该 socket 监听所有接口（包括 WSL vSwitch）。当 WSL2 向 `172.22.80.1:53` 发 DNS 包时，WinNAT 收到后**中继到上游 DNS**（宿主机配置的 DNS），再通过 NAT 把应答回给 WSL2。

## 3. Clash TUN 的工作原理（及其盲区）

Clash TUN 创建虚拟网卡 `Mihomo-Miku`（`198.18.0.1/30`），通过**路由表 + WFP 规则**（strict-route）把流量重定向进 TUN。`dns-hijack any:53` 的含义是：*任何**穿越 TUN 网卡**的 53 端口包*都会被改指向 mihomo 自己的 DNS 引擎。

关键问题：**WSL2 发往 `172.22.80.1:53` 的 DNS 包会穿越 TUN 吗？**

不会。原因分两层：

### 第一层 —— "本地投递" 根本不进入路由/转发路径

包从 WSL vSwitch 到达宿主机后，Windows 先判断目的地：

```
包的目的 IP = 172.22.80.1   ← 是不是宿主机自己拥有的 IP？
                                  │
                    ┌─────────────┴─────────────┐
                    │ 是 → 本地投递 (LOCAL       │ 否 → 转发 (FORWARDING)
                    │      DELIVERY)            │      走路由表 / TUN 重定向
                    │      直接交给拥有该端口的  │
                    │      socket               │
                    └───────────────────────────┘
```

`172.22.80.1` **就是宿主机自己的 IP**（vEthernet (WSL) 网卡）。所以包走**本地投递**路径，直接交给持有 53 端口的 socket —— 也就是 **svchost/WinNAT**，而不是 mihomo。它从头到尾没碰过路由表、没碰过 WFP 重定向规则、没碰过 TUN 网卡。

**Clash TUN / strict-route / dns-hijack 只作用于转发路径。** 本地投递的包根本到不了那里。这也是为什么 `dns-hijack any:53` 帮不上忙：劫持规则只看得见*穿越 TUN* 的包，而这个包从不穿越。

### 第二层 —— 对比：WSL2 → Google:443 确实走 TUN

```
dst = 142.251.150.119     ← 不是宿主机本机 IP
        → 转发路径 → strict-route WFP 规则 → TUN → mihomo → Trojan 节点
```

所以核心日志里能看到 `[TCP] 172.22.89.242:52574 --> www.google.com:443 ... using Selected Proxy[Trojan to NA]` —— 转发流量被捕获了。只有发往**网关的 DNS** 是唯一逃脱的特例。

## 4. 实际发生的事

WSL2 的每个 DNS 查询都进 WinNAT 的 socket → WinNAT 中继到上游。但 WinNAT 的"上游"是它**在 TUN 开启之前**缓存的 DNS —— 也就是局域网 DNS `192.168.1.39`，它能 ping 通，但对 DNS 查询无响应（至少从不回 AAAA）。实测结果：

| 查询 | 路径 | 结果 |
|---|---|---|
| A → `172.22.80.1:53` | WinNAT 中继 | 有时 OK ~90ms（不稳定，偶尔超时） |
| AAAA → `172.22.80.1:53` | WinNAT 中继 | **必然超时** → 双栈解析挂起 10–12s |
| A/AAAA → `198.18.0.2:53`（TUN peer） | TUN → mihomo | **瞬时**（2–3ms），AAAA 返回 NODATA |

另一个证明 mihomo 不在网关路径上的证据：如果 mihomo 在，网关的 AAAA 查询应该毫秒级返回 NODATA（`ipv6: false` 会过滤 AAAA）—— 但它永远挂起。那 90ms 的 A 应答是 WinNAT 中继的结果，不是 mihomo。

## 5. 为什么这是配置问题，而不是机场订阅的锅

- 自建 Trojan 节点工作正常（Windows 和 WSL2 都通过代理端口验证过）。
- WSL2 的 TCP 数据路径工作正常（`curl --resolve` 0.46s，日志确认被 TUN 捕获）。
- **唯一坏掉的是 WSL2 → 网关:53 的 DNS 路径** —— 而这条路径与任何 profile 的 DNS 配置（redir-host / DoH）完全无关，因为 **WinNAT 在 mihomo 看到包之前就把它截走了**。
- 自建配置与机场订阅表现完全一致 → 问题出在**本地设置**（Clash Verge 的 TUN 覆盖 + WSL2 自动生成的 resolv.conf），与两个 profile 都无关。

## 6. 修复方向（一句话）

把 WSL2 的 DNS 指向 **TUN peer `198.18.0.2`** 而不是网关 —— 这个地址只有 TUN 网卡拥有，任何发往它的包**必然**穿越 TUN → mihomo 瞬时应答。

具体方案见桌面根目录的 `WSL2-Clash-TUN-notes.md` 第 7 节（重应用指令 / 自愈脚本）。
