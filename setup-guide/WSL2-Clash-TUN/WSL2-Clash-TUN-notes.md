# WSL2 + Clash Verge Rev (TUN) — DNS & Connectivity Investigation Notes

> Date: 2026-08-07 · Host: Windows 10 (19045) · WSL2: Debian (NAT mode, default shell zsh)
> Clash Verge Rev: TUN mode ON (`Mihomo-Miku`, 198.18.0.1/30, `stack: system`, `strict-route: true`, `dns-hijack: any:53`) + system proxy ON
> Effective Clash DNS: **redir-host** (forced by global extend script `Script.js`; verified in `clash-verge-check.yaml` — note: on-disk `config.yaml` is often **stale**, judge by `clash-verge-check.yaml` instead)

---

## 1. Why WSL2 DNS bypassed mihomo (the "dns-hijack any:53" question)

- `dns-hijack` only intercepts packets **traversing the TUN adapter**. It is NOT a bind on Windows port 53.
- WSL2 (Win10 NAT mode) sends DNS to `172.22.80.1:53` — the host's own vEthernet (WSL) IP.
- That packet is **local delivery**: WinNAT (`svchost.exe` / SharedAccess, which owns UDP `0.0.0.0:53`) answers it and forwards upstream to the host's LAN DNS (`192.168.1.39`). It never enters the host routing table → never reaches the TUN device → `dns-hijack` never sees it.
- Therefore `fake-ip` vs `redir-host` was irrelevant to WSL2's resolution.

### Evidence
- `netstat -ano -p udp`: `UDP 0.0.0.0:53` → PID 5792 = `svchost.exe` (SharedAccess/WinNAT), NOT mihomo (PID 7488).
- mihomo's DNS listener = `0.0.0.0:1053` (from the subscription profile's `dns.listen`).
- From WSL2: UDP to `172.22.80.1:1053` timed out (Windows Firewall blocks inbound UDP from the WSL subnet; **TCP 1053 works**).

## 2. What strict-route changed

- strict-route adds firewall/routing rules that force WSL2-subnet traffic into the TUN.
- Verified: WSL2 → `198.18.0.2:53` (TUN peer) started answering (was: timeout). Core log showed WSL2 connections: `[TCP] 198.18.0.1:... --> www.gstatic.com:443 match RuleSet(Google) using ...`.
- BUT the old gateway path became a **race** (WinNAT local delivery vs TUN redirect) → symptoms:
  - A-record queries: sometimes slow (0–4s)
  - AAAA queries: **often hang** → glibc `getaddrinfo(AF_UNSPEC)` (curl default) stalls 5–12s → intermittent "connectivity" failures
  - `curl -4` works · `getent ahostsv4` works · `getent ahosts` / default curl hang
- `198.18.0.2:53` answered A and AAAA-NODATA **instantly and reliably** in all tests (mihomo `ipv6: false` → NODATA for AAAA).

## 3. Notes on dual-stack (IPv6) in WSL2

- WSL2 has **no global IPv6** in NAT mode (`ip -6 addr`: only link-local `fe80::` + loopback `::1`).
- Dual-stack DNS (A + AAAA queries) is glibc's default via `getaddrinfo()`, regardless of actual IPv6 connectivity. Windows does the same quietly.
- Disabling IPv6 in WSL2 (`sysctl net.ipv6.conf.all.disable_ipv6=1`) does **NOT** stop AAAA queries and can break tools binding `::`/`::1` — not recommended.

## 4. Is 172.22.80.1 a fixed address? — No

- `172.22.80.1` = gateway of the WSL virtual switch, **dynamically allocated by WinNAT** from the private pool (172.16.0.0/12, carved into /20s). WSL2's own IP (e.g. 172.22.89.242/20) comes from WSL DHCP in the same subnet.
- Usually stable across reboots, but **can change** after Windows updates, `wsl --shutdown` + NAT recreation, winsock reset, switch conflicts, Docker Desktop reinstall, etc.
- Evidence of dynamic allocation: three NAT'd Hyper-V switches on this machine: `vEthernet (WSL)` = 172.22.80.1/20, `vEthernet (Default Switch)` = 172.22.240.1/20, `vEthernet (WiFi)` = 172.26.64.1/20.

## 5. Config files involved (wsl.conf / resolv.conf)

### Default WSL behavior
- `/etc/resolv.conf` is auto-generated at every WSL boot → `nameserver <current gateway>` (e.g. 172.22.80.1).
- Control it via `/etc/wsl.conf`:
  ```ini
  [network]
  generateResolvConf = false   # stops auto-generation; you manage resolv.conf yourself
  ```

### glibc resolver options (in resolv.conf)
```
options timeout:1 attempts:1   # per-nameserver timeout/retries — bounds fallback delay to ~1s
nameserver 198.18.0.2          # TUN peer → dns-hijack → mihomo (redir-host). Exists only while TUN is up.
nameserver 172.22.80.1         # fallback: WinNAT → LAN DNS (works when Clash/TUN is off)
```

### Attempted fix (APPLIED then REVERTED — see §6)
```ini
# /etc/wsl.conf
[network]
generateResolvConf = false
```
```
# /etc/resolv.conf
options timeout:1 attempts:1
nameserver 198.18.0.2
nameserver 172.22.80.1
```
Results while active:
- TUN on: dual-stack resolution instant (0.01s), all curls/git/npm/mise/uv OK.
- TUN off simulated (unreachable primary): fallback ~1.2s (bounded by `timeout:1`; on this network the router replies ICMP unreachable fast, so even without options it was ~1.3s).

### Why the user rejected it
- Hardcoding `198.18.0.2` only works while TUN is up; fallback `172.22.80.1` can go stale if WinNAT re-allocates the WSL subnet; TUN-off adds ~1s per query. The concern was robustness when Clash is disabled/quit.

## 6. Current state (reverted)

- `/etc/wsl.conf` — **removed** → `generateResolvConf` back to default (system regenerates resolv.conf on next boot).
- `/etc/resolv.conf` — restored to WSL auto-generated default (`nameserver 172.22.80.1`).

## 7. Re-apply instructions (if ever wanted)

```bash
# as root (no password needed): wsl -d Debian -u root
cat > /etc/wsl.conf <<'EOF'
[network]
generateResolvConf = false
EOF

cat > /etc/resolv.conf <<'EOF'
options timeout:1 attempts:1
nameserver 198.18.0.2
nameserver 172.22.80.1
EOF
```
To revert again: `rm /etc/wsl.conf && wsl --shutdown` (WSL regenerates resolv.conf on boot).

Optional self-healing variant (keeps fallback pointing at the live gateway):
```ini
# /etc/wsl.conf
[boot]
command = /usr/local/bin/wsl-fix-resolv.sh
```
```sh
#!/bin/sh
GW=$(ip route show default | awk '{print $3}')
[ -n "$GW" ] || GW=172.22.80.1
printf 'options timeout:1 attempts:1\nnameserver 198.18.0.2\nnameserver %s\n' "$GW" > /etc/resolv.conf
```

## 8. Useful diagnostics (remembered for next time)

```bash
# Run WSL commands with the DEFAULT shell (zsh), login+interactive:
wsl -d Debian -- zsh -lic 'command'

# Effective Clash config (NOT config.yaml — it can be stale):
%APPDATA%\io.github.clash-verge-rev.clash-verge-rev\clash-verge-check.yaml
# Core log:
%APPDATA%\io.github.clash-verge-rev.clash-verge-rev\logs\service\service_latest.log

# DNS probes (A vs AAAA, gateway vs TUN peer) — use a small python UDP script
# (python3 available in WSL; nslookup/dig are NOT installed)

# Raw DNS path checks from WSL2:
#   UDP 172.22.80.1:53  → WinNAT relay (intermittent with strict-route on)
#   UDP 198.18.0.2:53   → TUN hijack → mihomo (reliable when TUN on)
#   UDP/TCP 172.22.80.1:1053 → mihomo DNS listener (UDP blocked by firewall; TCP OK)
```

## 9. Other findings from the same session (not networking)

- **PATH**: `mise activate` is wired into `.zshrc` (zsh) only — bash login shells lack the shims. Use zsh.
- **Proxy node flakiness**: core log showed `188.253.115.19 ... wsarecv: An existing connection was forcibly closed` — node-side drops affecting Windows too (not WSL2-specific). Registry via proxy ~1.3–2.5s (TLS ~0.9s); mise's 3s npm resolution timeout occasionally trips a WARN.
- **WSL2 → Windows `localhost` relay was broken** (refused for all ports) — use the host IP `172.22.80.1` instead; Windows → WSL2 localhost works.
- `ping` in WSL2 needs `cap_net_raw` (root or sysctl `net.ipv4.ping_group_range`) — unrelated to Clash.
