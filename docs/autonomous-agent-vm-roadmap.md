# Autonomous Agent VM Sandbox - Implementation Roadmap

## Project Status: PHASE 8 - DEPLOYMENT READY ✅

**Last Updated**: April 22, 2026

## Project Overview

Create an isolated VM environment where Claude Code can operate autonomously (`--dangerously-accept-permissions`) to develop, test, and deploy homelab infrastructure through Nix configurations. The VM serves as a safe sandbox for infrastructure experimentation without risk to the broader network.

## Implementation Summary

**✅ COMPLETED**: Phases 1-7 (Foundation through Documentation)  
**🚀 IN PROGRESS**: Phase 8 (Production Deployment Ready)  
**📋 PLANNED**: Phase 9 (Iteration & Improvement)

## Phase 1: Git Branch & Foundation Setup ✅ COMPLETED

### 1.1 Branch Management
- [x] Create new branch `llama-vm` from current `nix` branch ✅
- [x] Document branching strategy for agent development vs main homelab configs ✅
- [x] Set up merge strategy back to main branches ✅

### 1.2 VM Configuration Design
- [x] Create `hosts/agent/` directory structure ✅
- [x] Define VM resource requirements (4 CPU cores, 8GB RAM, 40GB storage) ✅
- [x] Plan network isolation strategy (isolated network bridge) ✅
- [x] Design data persistence strategy for agent work ✅

## Phase 2: Core VM Infrastructure ✅ COMPLETED

### 2.1 Base VM Configuration ✅
```
hosts/agent/
├── default.nix          # Main system config ✅
├── hardware-configuration.nix ✅
├── networking.nix       # Isolated network config ✅
├── ssh.nix             # SSH hardening for agent access ✅
├── agent-tools.nix     # Agent-specific tooling ✅
└── image.nix           # Proxmox VMA image config ✅
```

**Key Requirements:**
- [x] Extend `hosts/server/default.nix` base configuration ✅
- [x] Configure qemuGuest for Proxmox integration ✅
- [x] Set up isolated networking (dedicated bridge/VLAN) ✅
- [x] Configure persistent storage for agent workspace ✅
- [x] Enable container runtime (Docker) for service testing ✅

### 2.2 Security & Isolation ✅
- [x] Configure restrictive firewall (outbound only to necessary services) ✅
- [x] Set up network namespace isolation for container testing ✅
- [x] Configure resource limits (CPU, memory, disk I/O) ✅
- [x] Implement storage quotas for workspace areas ✅
- [x] Set up monitoring for resource usage and network activity ✅

## Phase 3: Terminal Environment & Tools ✅ COMPLETED

### 3.1 Core Terminal Configuration ✅
- [x] Configure `terminalman` Home Manager profile as base ✅
- [x] Add development tools: `git`, `nixfmt`, `jq`, `curl`, `wget` ✅
- [x] Include container tools: `docker-compose` ✅
- [x] Add network debugging: `netcat`, `nmap`, `dig` ✅

### 3.2 Tmux Configuration ✅
- [x] Enable tmux with standard configuration ✅
- [x] Configure tmux-sessionizer for project navigation ✅
- [x] Set up tmux-resurrect for session persistence ✅
- [x] Create agent-specific session templates ✅
- [x] Configure automatic session restoration on login ✅

**Tmux Session Structure:** ✅
```
/home/agent/workspace/
├── homelab/         # Infrastructure development ✅
├── testing/         # Local testing environment ✅
└── deployments/     # VM/container deployment ✅
```

### 3.3 SSH Access Configuration ✅
- [x] Generate dedicated SSH keys for agent VM ✅
- [x] Configure SSH hardening (key-only auth, rate limiting) ✅
- [x] Set up SSH agent forwarding for git operations ✅
- [x] Configure authorized_keys for secure access ✅
- [x] Test SSH connectivity and key management ✅

## Phase 4: Claude Code Integration ✅ COMPLETED

### 4.1 Claude Code Installation & Configuration ✅
- [x] Install Claude Code in VM environment (v2.1.92) ✅
- [x] Configure Claude Code authentication ✅
- [x] Set up workspace directories and permissions ✅
- [x] Configure git integration with proper credentials ✅
- [x] Test basic Claude Code functionality ✅

### 4.2 Agent-Specific Skills Configuration ✅
```
homeModules/claude-agent.nix     # Declarative Claude Code setup ✅
├── skills/                      # Agent-specific skills ✅
│   ├── homelab-architect.md     # Infrastructure design patterns ✅
│   ├── vm-deployment.md         # Proxmox deployment automation ✅
│   └── container-management.md  # OCI container patterns ✅
├── settings.json               # Autonomous permissions config ✅
└── shell integration           # Workspace aliases ✅
```

### 4.3 Curated Skill Set ✅
**Essential Skills:**
- [x] `nix-flake` - Flake development and management ✅
- [x] `nix-homelab` - Proxmox/VM deployment patterns ✅
- [x] `nix-lang` - Nix expression development ✅
- [x] `nix-debug` - Build error resolution ✅
- [x] Custom `homelab-architect` - Infrastructure design patterns ✅
- [x] Custom `vm-deployment` - Automated VM provisioning ✅
- [x] Custom `container-management` - OCI service management ✅

## Phase 5: Safety & Operational Boundaries ✅ COMPLETED

### 5.1 Agent Safety Configuration ✅
- [x] Define operational boundaries in agent settings ✅
- [x] Configure network access restrictions ✅
- [x] Set up resource monitoring and alerting ✅
- [x] Implement automatic rollback mechanisms ✅
- [x] Create emergency shutdown procedures ✅

### 5.2 Workspace Isolation ✅
```
/home/agent/
├── workspace/          # Agent development area ✅
│   ├── homelab/       # Infrastructure projects ✅
│   ├── testing/       # Local test environments ✅
│   └── deployments/   # Deployment configurations ✅
├── .claude/           # Claude Code configuration ✅
└── logs/             # Agent operation logs ✅
```

### 5.3 Network Isolation Strategy ✅
- [x] Configure dedicated bridge network for agent VM ✅
- [x] Set up firewall rules for limited outbound access ✅
- [x] Allow access to: GitHub, Nix cache, essential services ✅
- [x] Block access to: Production networks, unauthorized services ✅
- [x] Monitor and log all network activity ✅

## Phase 6: Testing & Validation Framework ✅ COMPLETED

### 6.1 Local Testing Environment ✅
- [x] Set up QEMU virtualization for VM testing ✅
- [x] Configure Docker for container testing ✅
- [x] Create comprehensive validation scripts ✅
- [x] Implement automated testing workflow ✅
- [x] Set up validation pipeline for agent configurations ✅

### 6.2 Deployment Testing Pipeline ✅
```
Development Flow: ✅
1. Agent develops Nix configuration ✅
2. Local build and syntax validation ✅
3. Test deployment in QEMU VM ✅
4. Security and resource validation ✅
5. Ready for staging Proxmox deployment ✅
6. Production deployment (manual approval) 🚀
```

### 6.3 Validation Checklist ✅
- [x] Nix expression syntax validation (`nixfmt`, `nix flake check`) ✅
- [x] Build validation (`nix build --dry-run`) ✅
- [x] Security audit (firewall rules, service exposure) ✅
- [x] Resource usage validation (CPU, memory, storage) ✅
- [x] Network connectivity testing ✅
- [x] Service functionality verification ✅

## Phase 7: Agent Prompts & Documentation ✅ COMPLETED

### 7.1 System Prompt Development ✅
**Core Agent Behavior:**
- [x] Define role as homelab infrastructure architect ✅
- [x] Establish safety protocols and operational boundaries ✅
- [x] Configure autonomous decision-making guidelines ✅
- [x] Set up escalation procedures for complex decisions ✅
- [x] Define success metrics and validation criteria ✅

### 7.2 Project Context Documentation ✅
- [x] Document current homelab architecture ✅
- [x] Catalog existing services and their requirements ✅
- [x] Define infrastructure patterns and conventions ✅
- [x] Create service deployment templates ✅
- [x] Document security and networking requirements ✅

### 7.3 Skills Documentation ✅
- [x] Create detailed skill descriptions and use cases ✅
- [x] Document workflow patterns for common tasks ✅
- [x] Establish code quality and security standards ✅
- [x] Create troubleshooting and debugging guides ✅
- [x] Set up knowledge base for common patterns ✅

## Phase 8: Deployment & Operations 🚀 IN PROGRESS

### 8.1 Initial VM Deployment 🚀 READY FOR PRODUCTION
- [x] Build VMA image with agent configuration ✅
- [x] **Local QEMU testing completed successfully** ✅
- [x] Configure networking and security ✅
- [x] Validate all tools and services are functional ✅
- [x] Test SSH access and Claude Code operation ✅
- [ ] Deploy to Proxmox production environment 🚀
- [ ] Validate production networking and connectivity 🚀

### 8.2 Agent Initialization 🚀 READY
- [x] Claude Code configured with agent-specific settings ✅
- [x] Load curated skills and project context ✅
- [x] Validate autonomous operation capabilities ✅
- [ ] Test sample infrastructure development workflow in production 🚀
- [ ] Monitor initial agent behavior and resource usage 🚀

### 8.3 Operational Monitoring 📋 CONFIGURED
- [x] Set up logging and monitoring for agent activities ✅
- [x] Configure alerts for resource usage and errors ✅
- [x] Implement periodic health checks ✅
- [x] Create backup and recovery procedures ✅
- [x] Document operational procedures and troubleshooting ✅

## Phase 9: Iteration & Improvement

### 9.1 Agent Performance Optimization
- [ ] Monitor agent effectiveness and decision quality
- [ ] Refine prompts and skills based on experience
- [ ] Optimize resource allocation and performance
- [ ] Improve automation and testing workflows
- [ ] Enhanced error handling and recovery

### 9.2 Skills Enhancement
- [ ] Develop additional specialized skills based on usage
- [ ] Improve existing skills with lessons learned
- [ ] Create more sophisticated testing frameworks
- [ ] Enhance deployment automation capabilities
- [ ] Build knowledge base from agent experiences

## Success Metrics

### Technical Metrics
- [ ] Agent can autonomously develop and test Nix configurations
- [ ] Successful deployment of new services without manual intervention
- [ ] Zero security incidents or network breaches
- [ ] 90%+ success rate for automated deployments
- [ ] Resource usage within defined limits

### Operational Metrics
- [ ] Reduced time from concept to deployed service
- [ ] Improved infrastructure consistency and quality
- [ ] Enhanced documentation and knowledge capture
- [ ] Increased experimentation velocity
- [ ] Better testing and validation coverage

## Risk Mitigation

### Security Risks
- **Network breach**: Isolated VLAN with restricted access
- **Resource exhaustion**: Resource limits and monitoring
- **Malicious code execution**: Container isolation and validation
- **Data corruption**: Regular backups and rollback capabilities

### Operational Risks
- **Agent failure**: Monitoring and automatic recovery
- **Configuration drift**: Version control and validation
- **Service disruption**: Staged deployment and rollback
- **Knowledge loss**: Comprehensive documentation and logging

## Implementation Completed ✅

### What's Been Built
1. **Complete VM Infrastructure**: All Nix configurations, security hardening, networking isolation
2. **Declarative Claude Code Integration**: Home Manager-based installation with autonomous permissions
3. **Comprehensive Testing**: Local QEMU validation with full functionality verification
4. **Documentation Suite**: Complete implementation documentation and operational procedures
5. **Deployment Automation**: Production-ready deployment scripts for Proxmox

### Current Status
- **Local Testing**: ✅ PASSED - VM boots, SSH works, Claude Code operational
- **Security**: ✅ VALIDATED - Network isolation, resource limits, permissions configured
- **Documentation**: ✅ COMPLETE - Setup guides, change logs, operational procedures

## Next Steps 🚀

1. **IMMEDIATE**: Production deployment to Proxmox using `./scripts/deploy-agent-vm.sh deploy`
2. **POST-DEPLOYMENT**: Agent initialization and homelab development workflow validation
3. **ONGOING**: Phase 9 iteration and improvement based on operational experience

This roadmap provides a comprehensive foundation for building a safe, effective autonomous agent environment for homelab infrastructure development.