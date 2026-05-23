# Homelab NixOS and Proxmox Architecture Assessment

## Overview

This report assesses the current flake-based dotfiles repository as an infrastructure-as-code control plane for NixOS desktops, Home Manager profiles, Proxmox VMs, and Proxmox LXC containers. It documents the observed repository architecture, upstream project implications, tradeoffs, target architecture, migration phases, Proxmox-specific improvements, and actionable restructuring recommendations.

## Assessment Scope

### Repository sources reviewed

| Area | Files reviewed | Assessment focus |
|---|---|---|
| Flake entry point | `flake.nix` | Inputs, helper functions, exported NixOS and Home Manager configurations |
| Base VM modules | `hosts/server/default.nix`, `hosts/server/networking.nix` | Proxmox VM baseline, network defaults, QEMU guest integration |
| Minimal Proxmox base | `hosts/proxmox-base/default.nix`, `hosts/proxmox-base/networking.nix` | Lightweight boot-first VM foundation |
| LXC foundation | `hosts/lxc-base/default.nix` | Container baseline, systemd/networking assumptions, privileged LXC posture |
| Service hosts | `hosts/media/default.nix`, `hosts/nas/default.nix` | Host-to-service-module composition and deployment-specific overrides |
| Service modules | `systemModules/media.nix`, `systemModules/nas.nix`, `systemModules/*` listing | Reusable `homelab.*` option model and service packaging pattern |
| Existing docs | `README.md`, `docs/plans/homelab-roadmap.md`, `docs/architecture/systemmodules-architecture.md` | Stated design intent, roadmap, current deployment decisions |

### External sources referenced

| Source | URL | Relevance |
|---|---|---|
| Nix flakes manual | https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake | Flake input/output structure and reproducible evaluation model |
| NixOS module system | https://nixos.org/manual/nixos/stable/#sec-writing-modules | Option declarations, `mkOption`, `mkEnableOption`, and module composition |
| NixOS containers | https://nixos.org/manual/nixos/stable/#ch-containers | Container-related NixOS behavior and isolation tradeoffs |
| Home Manager manual | https://nix-community.github.io/home-manager/ | Home Manager profile structure and flake integration |
| sops-nix | https://github.com/Mic92/sops-nix | Secret material integration for NixOS and Home Manager |
| Stylix | https://github.com/nix-community/stylix | Declarative theming input used by desktop and HM outputs |
| nvf | https://github.com/NotAShelf/nvf | Neovim framework input used by Home Manager outputs |
| Proxmox VE administration guide | https://pve.proxmox.com/pve-docs/pve-admin-guide.html | VM/LXC, storage, network, backup, and cluster operations |
| Proxmox PCI passthrough wiki | https://pve.proxmox.com/wiki/PCI_Passthrough | GPU passthrough design constraints for media, AI, and gaming VMs |
| Proxmox cloud-init support | https://pve.proxmox.com/wiki/Cloud-Init_Support | Template-driven provisioning and first-boot metadata |
| Prometheus node exporter | https://github.com/prometheus/node_exporter | Baseline host metrics pattern already enabled in base modules |

## Current Architecture

### Flake topology

`flake.nix` uses a single top-level flake to expose both `nixosConfigurations` and `homeConfigurations`. The main inputs are `nixpkgs`, `nixos-hardware`, `home-manager`, `stylix`, `nvf`, and `sops-nix`. This is an appropriate foundation for a personal homelab because it keeps desktop, server, and user-environment drift visible in one dependency graph.

The flake currently defines two helper patterns:

```nix
mkNixosSystem = { hostname, modules ? [ ], userSettings ? baseUserSettings }: ...
mkHomeConfiguration = system: userSettings: modules: ...
```

These helpers reduce repetition, but the NixOS helper only accepts `hostname`, `modules`, and `userSettings`. It does not yet encode host class, deployment type, hardware profile, network role, or Proxmox metadata. As a result, those concerns are repeated across host modules and comments.

### Host classes

| Host class | Current paths | Strengths | Main gaps |
|---|---|---|---|
| Desktop | `hosts/gaia/` | Uses `nixos-hardware`, Stylix, Home Manager profiles | Separate from homelab concerns, which is good; should remain isolated |
| Generic Proxmox VM | `hosts/server/` | QEMU guest agent, SSH, Nix settings, common packages | Includes broad defaults and passwordless sudo; no explicit role metadata |
| Minimal Proxmox base | `hosts/proxmox-base/` | Boot-first baseline, node exporter, firewall | Overlaps with `hosts/server/`; state version differs from server base |
| LXC base | `hosts/lxc-base/` | Container-specific boot/network assumptions, smaller package set | Requires privileged container assumptions; root filesystem labeling may not match Proxmox LXC reality |
| Service VMs | `hosts/media/`, `hosts/nas/`, `hosts/git/`, etc. | Clear service ownership and module imports | Some operational placeholders remain in live config |
| Service LXCs | `hosts/lxc-*` | Resource-efficient deployment path | Needs stronger Proxmox template and backup workflow documentation |
| Agent/build infrastructure | `hosts/agent/`, `hosts/agent-minimal/`, `hosts/nixos-builder/` | Recognizes autonomous build/deploy needs | Should be security-zoned and separated from general service hosts |

### Service module model

`systemModules/` is already moving in the right direction. Existing documentation in `docs/architecture/systemmodules-architecture.md` defines a consistent module pattern with:

- `homelab.<service>.enable`
- `deploymentType = "vm" | "container" | "hybrid"`
- `resourceProfile = "minimal" | "standard" | "high"`
- centralized package selection in `systemModules/packages.nix`
- host files that mainly set deployment-specific values

This model is more maintainable than service-specific monoliths. It should become the primary service abstraction.

### Proxmox deployment posture

The repository supports both VM and LXC futures. `docs/plans/homelab-roadmap.md` correctly identifies that the current Dell node is resource constrained and that LXCs are a practical near-term optimization. It also correctly reserves VMs for GPU passthrough, untrusted workloads, gaming, and autonomous agent isolation. Source note: this aligns with the Proxmox VE administration guide's VM/LXC distinction and the Proxmox PCI passthrough guidance for direct device assignment.

The strongest current operational risk is that Proxmox inventory state is split across comments, roadmap tables, host names, and placeholder IPs. The repository has `docs/architecture/infrastructure-registry.md`, but the flake does not consume a canonical machine inventory.

## Upstream and Tooling Findings

### NixOS module system fit

The NixOS module system is well aligned with this repository. The current `homelab.*` options should be expanded rather than replaced. The upstream module model supports typed options, defaults, assertions, warnings, and conditional config. Those features are suitable for preventing common homelab mistakes before deployment.

Recommended additions:

```nix
assertions = [
  {
    assertion = cfg.storage.nasAddress != "10.0.0.TBD";
    message = "homelab.media.storage.nasAddress must be set before enabling media storage.";
  }
];

warnings = lib.optionals cfg.downloadClients.qbittorrent.vpnKillSwitch [
  "qBittorrent VPN kill switch is enabled; verify WireGuard credentials exist in sops-nix."
];
```

Use assertions for unsafe placeholders and warnings for non-fatal operational reminders.

### Flake fit

The flake model is appropriate, but the output shape should become more data-driven. Today each host is hand-written in `flake.nix`. This is readable at small scale but becomes fragile as VM, LXC, builder, and GPU nodes grow.

A target pattern is a host inventory that drives `nixosConfigurations` generation. The inventory can remain Nix-native to avoid introducing YAML parsing complexity.

```nix
# hosts/inventory.nix
{
  media = {
    class = "vm";
    base = ./server;
    modules = [ ./media ../systemModules/media.nix ];
    # Allocate the VMID from docs/architecture/infrastructure-registry.md before provisioning.
    # Do not reuse existing IDs such as homeassistant's VMID 103.
    proxmox = { vmid = "TBD"; cores = 4; memoryMb = 8192; gpu = "gtx1080ti"; };
  };
}
```

### Home Manager fit

The Home Manager side is structured and documented. The option-based profile model in `home/options.nix` and `home/profiles/` should remain separate from system service concerns. Avoid leaking homelab service roles into Home Manager profiles except for operator workstations and agent users.

### sops-nix fit

`sops-nix` is the correct upstream tool for this repository because secrets can be declared in system modules and materialized with correct ownership at activation time. The current architecture should make every service secret path part of the service module option surface. Avoid service host files that directly know the internal secret layout unless the secret is truly host-specific.

### Proxmox fit

Proxmox is a good target for this architecture, but it should be treated as a substrate with explicit constraints:

- VMs are the right target for GPU passthrough, different kernels, agent sandboxing, and gaming. Source note: Proxmox documents PCI passthrough as VM-oriented direct device assignment.
- LXCs are the right target for lightweight trusted services, monitoring, Git, and simple web stacks when the shared-kernel security model is acceptable. Source note: Proxmox and NixOS container documentation both treat containers as distinct from full virtual machines.
- Storage and network topology must be modeled explicitly because they affect service correctness more than package configuration does.
- VM IDs, VLANs, bridges, and PCI devices should be canonical data, not comments.

## Key Findings

### Strengths

| Finding | Evidence | Impact |
|---|---|---|
| Unified flake control plane | `flake.nix` exports NixOS and HM configs | One repo can manage desktop, servers, and profiles |
| Clear service module direction | `systemModules/media.nix`, `docs/architecture/systemmodules-architecture.md` | Reusable service patterns reduce duplication |
| Proxmox-specific bases exist | `hosts/server/`, `hosts/proxmox-base/`, `hosts/lxc-base/` | VM and LXC targets are acknowledged |
| Operational docs are extensive | `docs/plans/homelab-roadmap.md`, service setup docs | Good continuity for future deployments |
| Resource-aware planning exists | Dell vs gaming PC node plans in roadmap | Good basis for phased migration |
| Monitoring baseline appears early | node exporter in `hosts/proxmox-base/default.nix` and LXC base ports | Enables fleet observability |

### Risks and gaps

| Risk | Evidence | Consequence | Recommendation |
|---|---|---|---|
| Placeholder values can evaluate | `10.0.0.TBD` in `hosts/media/default.nix`, `hosts/nas/default.nix`, `systemModules/media.nix` | Broken mounts or firewall rules may reach deployment | Add assertions for enabled services with placeholder IPs |
| Base module duplication | `hosts/server/default.nix` and `hosts/proxmox-base/default.nix` overlap | Divergent state versions, packages, firewall posture | Merge into layered base modules |
| Inventory is not canonical | VM IDs and resources appear in docs/comments | Accidental ID reuse or incorrect Proxmox sizing | Create `hosts/inventory.nix` and generate configs/docs from it over time |
| Passwordless sudo is broad | VM and LXC bases set `security.sudo.wheelNeedsPassword = false` | Compromise of one user gives root immediately | Restrict by host class; keep only where explicitly justified |
| Firewall mixes declarative and imperative rules | `networking.firewall.extraCommands` uses raw iptables | Rules can be non-idempotent or backend-sensitive | Prefer nftables/firewall interfaces or dedicated network ACL model |
| LXC assumptions need verification | `hosts/lxc-base/default.nix` configures root filesystem and special filesystems | Proxmox LXC boot/import may differ from VM-style assumptions | Maintain tested LXC template build and restore procedure |
| Secrets rollout is partial | Roadmap marks `sops-nix` partial | Services may require manual credentials | Make secret requirements explicit in each module |
| GPU passthrough is comment-driven | `hosts/media/default.nix` contains Proxmox setup comments | Drift between Proxmox host and Nix config | Track GPU inventory and passthrough assignments in a registry |

## Recommended Target Architecture

### Architecture principles

1. Keep the flake as the single source of evaluation.
2. Make service modules reusable and option-driven.
3. Separate host class concerns from service concerns.
4. Treat Proxmox inventory as structured data.
5. Prefer assertions over documentation-only warnings for unsafe deployment states.
6. Keep secrets declarative and encrypted; never encode decrypted values or provider tokens in host modules.
7. Use LXCs for trusted lightweight services and VMs for isolation, GPU, kernel, and agent workloads.

### Proposed directory structure

```text
hosts/
├── inventory.nix                  # Canonical host, VMID, node, network, resource metadata
├── profiles/
│   ├── nixos-vm-base.nix           # Shared VM baseline
│   ├── proxmox-vm.nix              # QEMU guest, bootloader, Proxmox-specific defaults
│   ├── proxmox-lxc.nix             # Container defaults
│   ├── monitoring-client.nix       # Node exporter and scrape labels
│   └── hardened-ssh.nix            # Common SSH policy
├── gaia/
├── services/
│   ├── media.nix                   # Host-level service composition
│   ├── nas.nix
│   └── monitor.nix
└── images/
    ├── proxmox-vm-template.nix
    └── proxmox-lxc-template.nix

systemModules/
├── services/
│   ├── media.nix
│   ├── nas.nix
│   ├── forgejo.nix
│   └── monitoring.nix
├── profiles/
│   ├── oci-container.nix
│   └── reverse-proxy.nix
└── packages.nix
```

This structure separates reusable service modules from deployable host profiles. It also makes `hosts/` about machines and `systemModules/` about capabilities.

### Target host generation model

Keep generated logic simple and inspectable:

```nix
let
  inventory = import ./hosts/inventory.nix;
  mkHost = name: host: nixpkgs.lib.nixosSystem {
    system = host.system or "x86_64-linux";
    modules = host.modules;
    specialArgs = {
      inherit userSettings;
      systemSettings = systemSettings // { hostname = name; };
      hostMeta = host;
    };
  };
in {
  nixosConfigurations = nixpkgs.lib.mapAttrs mkHost inventory;
}
```

Do not over-abstract immediately. Start by moving metadata into inventory while keeping module lists explicit.

### Target Proxmox metadata model

```nix
{
  media = {
    class = "vm";
    proxmox = {
      node = "gaming-pc";
      # Allocate from docs/architecture/infrastructure-registry.md; 103 is already reserved for homeassistant.
      vmid = "TBD";
      cores = 4;
      memoryMb = 8192;
      disks = [ { storage = "local-zfs"; sizeGb = 80; } ];
      # Select the VLAN from the planned roles in docs/architecture/infrastructure-registry.md.
      network = { bridge = "vmbr0"; vlan = "TBD"; mac = null; };
      pci = [ "gpu-transcode-1080ti" ];
      backup = { enabled = true; mode = "snapshot"; schedule = "daily"; };
    };
  };
}
```

The immediate goal is not full Proxmox API automation. The immediate goal is preventing inventory drift and making documentation generateable.

## Tradeoff Analysis

### VM vs LXC

| Criterion | VM | LXC | Recommendation |
|---|---|---|---|
| Kernel isolation | Strong | Shared host kernel | Use VM for untrusted or experimental services |
| Resource overhead | Higher | Lower | Use LXC on the Dell node for trusted services |
| GPU passthrough | Strong for exclusive PCI assignment | Possible for shared device access but less isolated | Use VM for gaming, AI, and primary media transcoding; source: Proxmox PCI passthrough guidance |
| Backup portability | Full disk image, heavier | Smaller container backup | Use LXC for simple web services and monitoring; source: Proxmox VE backup model |
| NixOS compatibility | Straightforward | Works best with privileged containers and tested templates | Keep LXC base minimal and documented; source: NixOS container behavior and current `hosts/lxc-base/default.nix` assumptions |
| Security boundary | Stronger | Weaker | Do not place autonomous agents or internet-risk workloads in privileged LXC |

### Monolithic host files vs option-driven service modules

| Approach | Benefits | Costs | Determination |
|---|---|---|---|
| Large host files | Easy to read for one host | Duplication, inconsistent defaults, hard to test | Avoid for reusable services |
| Service modules with options | Typed config, reusable, testable, composable | More upfront design | Preferred default |
| Fully generated modules | Consistent at scale | Can become opaque | Use only for inventory glue, not service logic |

### Raw Proxmox commands vs declarative inventory

| Approach | Benefits | Costs | Determination |
|---|---|---|---|
| Comments with `qm set` | Fast and practical | Drifts from actual state | Keep as examples only |
| Structured inventory | Reviewable and searchable | Requires maintenance discipline | Adopt now |
| Full Proxmox API automation | Repeatable provisioning | More credentials and failure modes | Later phase after inventory stabilizes |

### NFS vs bind mounts for service storage

| Storage pattern | Benefits | Costs | Recommended use |
|---|---|---|---|
| NFS from NAS VM | Works across VM/LXC boundaries, clear ownership | Network dependency, mount failure modes | Media libraries, backups, shared archives |
| Proxmox bind mounts to LXC | Efficient, simple for same node | Less portable, host-coupled | Lightweight LXC services on one node |
| VM virtual disks | Strong isolation, easy snapshots | Harder sharing, capacity planning | Databases, stateful service roots |
| Object/cloud backup via rclone | Offsite durability | Credential management, bandwidth | Secondary backup tier only |

## Concrete Proxmox Improvements

### 1. Establish canonical VMID and CTID ranges

Use non-overlapping ranges and record them in `docs/architecture/infrastructure-registry.md` and later `hosts/inventory.nix`. The registry is the current authority: deployed and planned CT IDs already use `201-207`, so the table below aligns with that state rather than introducing a competing range. Any future renumbering, such as moving LXCs to `300-399`, should be documented as a migration proposal before use.

| Range | Purpose | Examples |
|---|---|---|
| 100-149 | VM services and templates currently tracked in the registry | matrix, homeassistant, fitness, monitor, git, llama, vpn |
| 150-199 | Future VM expansion | media, nvr, gaming, additional GPU workloads |
| 200 | Existing infrastructure VM and reserved exception | nixos-builder |
| 201-207 | Current LXC CT IDs tracked or planned in the registry | lxc-nas, lxc-homeassistant, lxc-matrix, lxc-git, lxc-monitor |
| 208-299 | Future LXC CT expansion | Allocate only after `docs/architecture/infrastructure-registry.md` is updated |
| 300-399 | Future migration proposal only | Do not allocate until `docs/architecture/infrastructure-registry.md` is updated |

### 2. Standardize Proxmox network bridges and VLANs

The current configs primarily assume the active flat `10.0.0.0/24` network and DHCP. The future VLAN table below is synchronized with `docs/architecture/infrastructure-registry.md`; do not create a second VLAN plan in this assessment. Additional segmentation, such as separate Storage, DMZ, or VPN VLANs, is a future proposed registry change and requires an update to `docs/architecture/infrastructure-registry.md` before use.

| VLAN | Purpose | Example CIDR | Notes |
|---|---|---|---|
| 1 | Management | `10.0.0.0/24` | Full access to all VLANs; current active network |
| 10 | IoT | `10.0.10.0/24` | Restricted devices; NVR access only and limited internet access |
| 20 | Services | `10.0.20.0/24` | Inter-service communication and internet access |
| 30 | Guest | `10.0.30.0/24` | Internet-only guest access with no homelab access |

Prefer static DHCP reservations in the router for initial migration. Later, encode static addresses per host if router dependence becomes a problem.

### 3. Convert placeholder deployment values into assertions

Examples to protect:

- `homelab.media.storage.nasAddress = "10.0.0.TBD"`
- NAS NFS exports containing `10.0.0.TBD`
- GPU PCI IDs in comments
- VPN kill switch enabled without WireGuard secrets
- ACME enabled without DNS names and email configured

### 4. Create a Proxmox template workflow

Document and standardize two image paths:

| Template | Repository output | Use |
|---|---|---|
| Minimal VM template | `nixos-rebuild build-image --image-variant proxmox --flake .#initialProxmoxVMA` | New VM bootstrapping; this is the concrete command from `docs/architecture/infrastructure-registry.md` |
| LXC tarball | `nixosConfigurations.initialLXC.config.system.build.tarball` | New NixOS LXC containers |

The template workflow should include:

1. Build artifact from flake.
2. Upload to Proxmox storage.
3. Create VM or CT with reserved ID.
4. Attach network with VLAN tag.
5. Boot with DHCP reservation.
6. Run first `nixos-rebuild --target-host` from builder.
7. Confirm node exporter appears in Prometheus.
8. Add backup job.

### 5. Improve backup policy

| Workload | Proxmox backup | Application backup | Notes |
|---|---|---|---|
| Forgejo | Daily snapshot | Dump repositories and DB | Test restore monthly |
| Matrix | Daily snapshot | PostgreSQL dump and media backup | Coordinate with service stop or DB-native backup |
| NAS | Snapshot metadata only | Borg/rclone for payload | Avoid treating one local disk as backup |
| Monitoring | Weekly snapshot | Export Grafana dashboards | Metrics can have shorter retention |
| Agent sandbox | Snapshot before experiments | No long-term state unless promoted | Reset frequently |
| Gaming | Manual snapshots | Save data separately | Large disk; avoid excessive backup churn |

### 6. Add Proxmox host hardening checklist

Track outside-Nix settings that cannot be fully expressed inside guest NixOS:

- IOMMU enabled in firmware.
- Proxmox kernel command line includes correct Intel/AMD IOMMU flags.
- PCI devices have stable IDs and vfio binding where needed.
- Proxmox root login policy and SSH keys are reviewed.
- Backup storage target is not on the same failure domain as primary disks.
- Proxmox firewall is enabled at datacenter/node level when VLAN migration starts.
- UPS shutdown behavior is defined for the Dell laptop and future gaming PC node.

## Practical Repository Restructuring Suggestions

### Phase the restructuring

Do not perform a large rename-only refactor before the services are stable. Use additive changes first.

#### Step 1: Add inventory without changing behavior

Create `hosts/inventory.nix` with metadata copied from docs and comments. Do not generate `flake.nix` from it yet. Use it as a review target.

#### Step 2: Add assertions to current modules

Protect known placeholders in `systemModules/media.nix`, `systemModules/nas.nix`, WireGuard/Tailscale modules, and any ACME-enabled service modules.

#### Step 3: Consolidate base profiles

Refactor overlapping base logic into layers:

```text
hosts/profiles/common-nixos.nix
hosts/profiles/proxmox-vm.nix
hosts/profiles/proxmox-lxc.nix
hosts/profiles/monitoring-client.nix
hosts/profiles/operator-access.nix
```

Then make `hosts/server/default.nix` and `hosts/proxmox-base/default.nix` compatibility wrappers until all hosts migrate.

#### Step 4: Move service host files into a service namespace

Current paths are acceptable, but a future layout can distinguish machines from service compositions:

```text
hosts/services/media.nix
hosts/services/nas.nix
hosts/services/monitor.nix
```

This is optional. The higher-value change is inventory plus assertions.

#### Step 5: Generate registry documentation

Once inventory exists, generate or manually sync a table in `docs/architecture/infrastructure-registry.md`. Until automation exists, add a rule that every VM/CT change updates both the host config and registry.

### Suggested module quality gates

Every `systemModules/<service>.nix` should have:

- `enable` option.
- `deploymentType` option where VM/LXC behavior differs.
- `resourceProfile` option where sizing affects retention or enabled components.
- Explicit port options.
- Firewall behavior controlled by options.
- Secret declarations close to the service that consumes them.
- Assertions for required non-placeholder settings.
- Monitoring toggle and default metrics port if available.
- A short docs reference in `docs/operations/services/<service>-setup.md`.

## Migration Plan

### Phase 0: Stabilize current state

| Task | Output | Risk |
|---|---|---|
| Validate all existing NixOS outputs with dry-run builds | Known evaluation baseline | Low |
| Update `docs/architecture/infrastructure-registry.md` from live Proxmox state | Canonical current inventory | Low |
| Mark placeholders with TODO owner and blocking status | Visible deployment blockers | Low |
| Confirm deployed services and VM IDs | Prevent accidental overwrite | Medium if skipped |

### Phase 1: Safety assertions and inventory

| Task | Output | Risk |
|---|---|---|
| Add `hosts/inventory.nix` metadata only | Structured inventory | Low |
| Add placeholder assertions in service modules | Safer evaluation | Low to medium; may expose known broken configs |
| Add service secret requirement tables to docs | Clear rollout steps | Low |
| Normalize state version policy for new hosts | Fewer accidental version jumps | Low |

### Phase 2: Base profile consolidation

| Task | Output | Risk |
|---|---|---|
| Extract common VM options from `hosts/server/` and `hosts/proxmox-base/` | Less duplication | Medium |
| Keep compatibility imports for old paths | Reduced migration blast radius | Low |
| Standardize SSH, sudo, and firewall defaults by host class | Better security | Medium |
| Add monitoring-client profile | Consistent observability | Low |

### Phase 3: Proxmox operational model

| Task | Output | Risk |
|---|---|---|
| Define VLANs and DHCP reservations | Predictable networking | Medium |
| Create tested VM and LXC template procedures | Repeatable provisioning | Medium |
| Move builder deployments through `nixos-builder` | Laptop-independent builds | Medium |
| Add Proxmox backup schedule matrix | Restore-ready services | Low |

### Phase 4: Service migrations

| Task | Output | Risk |
|---|---|---|
| Move monitoring, Git, Matrix to LXCs on Dell if resource pressure remains | Lower overhead | Medium |
| Keep agent, gaming, AI, GPU media as VMs | Correct isolation/performance | Low |
| Migrate media/NVR/AI to gaming PC node when available | GPU-enabled workloads | High; requires PCI passthrough testing |
| Run restore tests for stateful services | Verified resilience | Medium |

### Phase 5: Optional automation

| Task | Output | Risk |
|---|---|---|
| Generate `nixosConfigurations` from inventory | Less flake repetition | Medium |
| Generate docs tables from inventory | Lower documentation drift | Low |
| Add Proxmox API provisioning scripts | Repeatable VM/CT creation | High; introduces credentials and destructive API capability |
| Add CI-style `nix flake check` or per-host dry-run job on builder | Continuous validation | Medium |

## Final Determinations

### Determination 1: Keep NixOS and Home Manager in one flake

The current unified flake is appropriate. Splitting desktop and homelab into separate flakes would reduce local file size but increase coordination overhead for shared user settings, shared formatter policy, and agent tooling.

### Determination 2: Invest in service modules, not host-specific copies

The `systemModules/` option model is the strongest architectural asset in the repository. Continue building reusable modules and keep host files thin.

### Determination 3: Use LXCs selectively, not universally

LXCs are valuable for the current Dell node, but privileged LXC is not a replacement for VM isolation. Use LXCs for trusted low-risk services. Keep autonomous agents, gaming, AI, and GPU passthrough workloads as VMs.

### Determination 4: Treat Proxmox inventory as infrastructure code

VM IDs, CT IDs, VLANs, Proxmox nodes, storage pools, PCI devices, and backup policy should become structured repository data. This does not require immediate Proxmox API automation.

### Determination 5: Assertions are the next highest-value code change

The most practical near-term improvement is adding evaluation-time assertions for placeholders and unsafe combinations. This directly reduces deployment risk without large restructuring.

## Actionable Recommendations

### Immediate actions

1. Create `hosts/inventory.nix` as metadata-only documentation in code.
2. Add assertions for `10.0.0.TBD` and similar placeholders in enabled services.
3. Update `docs/architecture/infrastructure-registry.md` from live Proxmox state before creating new VMs or LXCs.
4. Decide whether `hosts/server/` or `hosts/proxmox-base/` is the preferred VM baseline; document the other as legacy or image-only.
5. Make passwordless sudo an explicit per-host-class option instead of a universal base default.

### Near-term actions

1. Build a tested LXC tarball from `initialLXC` and document the exact Proxmox restore/import command.
2. Add a monitoring-client profile and import it consistently into VM and LXC bases.
3. Replace raw `iptables` `extraCommands` with declarative firewall rules where possible.
4. Add service docs tables that list ports, state directories, secrets, backup method, and restore command.
5. Move Nix builds and deployment orchestration toward `nixos-builder` once it has stable SSH and store capacity.

### Long-term actions

1. Generate `nixosConfigurations` from inventory after metadata stabilizes.
2. Add Proxmox API automation only after backups and inventory are reliable.
3. Implement VLAN segmentation using the planned roles in `docs/architecture/infrastructure-registry.md` and update firewall rules around those roles.
4. Add restore drills as recurring operational tasks.
5. Build a GPU assignment registry before migrating AI, media transcoding, NVR, or gaming workloads to the gaming PC node.

## Examples

### Example inventory entry

```nix
# hosts/inventory.nix
{
  monitor = {
    class = "lxc";
    role = "observability";
    modules = [ ./lxc-monitor ];
    proxmox = {
      node = "dell";
      # lxc-monitor is registered as CT 207 in docs/architecture/infrastructure-registry.md.
      id = 207;
      cores = 1;
      memoryMb = 1024;
      # Use the Mgmt VLAN only after the registry VLAN plan is implemented.
      vlan = 1;
      backup = { enabled = true; schedule = "daily"; };
    };
  };
}
```

### Example placeholder assertion

```nix
{
  assertions = lib.optionals config.homelab.media.enable [
    {
      assertion = config.homelab.media.storage.nasAddress != "10.0.0.TBD";
      message = "Set homelab.media.storage.nasAddress before deploying the media host.";
    }
  ];
}
```

### Example service documentation table

```markdown
| Item | Value |
|---|---|
| Service | Forgejo |
| Host | git or lxc-git |
| Ports | 3000/tcp, 22/tcp if SSH Git is enabled |
| State | /var/lib/forgejo |
| Secrets | forgejo database password, mail credentials |
| Backup | Proxmox snapshot plus database dump |
| Restore test | Quarterly |
```

## References

- Repository flake: `flake.nix`
- VM base: `hosts/server/default.nix`
- Proxmox minimal base: `hosts/proxmox-base/default.nix`
- LXC base: `hosts/lxc-base/default.nix`
- Media host: `hosts/media/default.nix`
- NAS host: `hosts/nas/default.nix`
- Media service module: `systemModules/media.nix`
- Existing architecture guide: `docs/architecture/systemmodules-architecture.md`
- Existing roadmap: `docs/plans/homelab-roadmap.md`
- Nix flakes manual: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake
- NixOS module system: https://nixos.org/manual/nixos/stable/#sec-writing-modules
- Home Manager manual: https://nix-community.github.io/home-manager/
- sops-nix: https://github.com/Mic92/sops-nix
- Proxmox VE administration guide: https://pve.proxmox.com/pve-docs/pve-admin-guide.html
- Proxmox PCI passthrough: https://pve.proxmox.com/wiki/PCI_Passthrough
