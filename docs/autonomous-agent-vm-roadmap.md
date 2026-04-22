# Autonomous Agent VM Sandbox - Implementation Roadmap

## Project Overview

Create an isolated VM environment where Claude Code can operate autonomously (`--dangerously-accept-permissions`) to develop, test, and deploy homelab infrastructure through Nix configurations. The VM serves as a safe sandbox for infrastructure experimentation without risk to the broader network.

## Phase 1: Git Branch & Foundation Setup

### 1.1 Branch Management
- [ ] Create new branch `agent-sandbox` from current `nix` branch
- [ ] Document branching strategy for agent development vs main homelab configs
- [ ] Set up merge strategy back to main branches

### 1.2 VM Configuration Design
- [ ] Create `hosts/agent/` directory structure
- [ ] Define VM resource requirements (CPU, RAM, storage)
- [ ] Plan network isolation strategy (separate VLAN or bridge)
- [ ] Design data persistence strategy for agent work

## Phase 2: Core VM Infrastructure

### 2.1 Base VM Configuration
```
hosts/agent/
├── default.nix          # Main system config
├── hardware-configuration.nix
├── networking.nix       # Isolated network config
├── ssh.nix             # SSH hardening for agent access
├── agent-tools.nix     # Agent-specific tooling
└── image.nix           # Proxmox VMA image config
```

**Key Requirements:**
- [ ] Extend `hosts/server/default.nix` base configuration
- [ ] Configure qemuGuest for Proxmox integration
- [ ] Set up isolated networking (dedicated bridge/VLAN)
- [ ] Configure persistent storage for agent workspace
- [ ] Enable container runtime (Docker/Podman) for service testing

### 2.2 Security & Isolation
- [ ] Configure restrictive firewall (outbound only to necessary services)
- [ ] Set up network namespace isolation for container testing
- [ ] Configure resource limits (CPU, memory, disk I/O)
- [ ] Implement storage quotas for workspace areas
- [ ] Set up monitoring for resource usage and network activity

## Phase 3: Terminal Environment & Tools

### 3.1 Core Terminal Configuration
- [ ] Configure `terminalman` Home Manager profile as base
- [ ] Add development tools: `git`, `nixfmt`, `jq`, `curl`, `wget`
- [ ] Include container tools: `docker-compose`, `podman-compose`
- [ ] Add network debugging: `netcat`, `nmap`, `dig`

### 3.2 Tmux Configuration
- [ ] Enable tmux with standard configuration
- [ ] Configure tmux-sessionizer for project navigation
- [ ] Set up tmux-resurrect for session persistence
- [ ] Create agent-specific session templates
- [ ] Configure automatic session restoration on login

**Tmux Session Structure:**
```
agent-work/           # Main development session
├── homelab          # Infrastructure development
├── testing          # Local testing environment  
├── deployment       # VM/container deployment
└── monitoring       # System monitoring
```

### 3.3 SSH Access Configuration
- [ ] Generate dedicated SSH keys for agent VM
- [ ] Configure SSH hardening (key-only auth, rate limiting)
- [ ] Set up SSH agent forwarding for git operations
- [ ] Configure authorized_keys for secure access
- [ ] Test SSH connectivity and key management

## Phase 4: Claude Code Integration

### 4.1 Claude Code Installation & Configuration
- [ ] Install Claude Code in VM environment
- [ ] Configure Claude Code authentication
- [ ] Set up workspace directories and permissions
- [ ] Configure git integration with proper credentials
- [ ] Test basic Claude Code functionality

### 4.2 Agent-Specific Skills Configuration
```
homeModules/claude/
├── agent-skills/
│   ├── homelab-architect.md      # Infrastructure design patterns
│   ├── nix-testing.md            # Local testing workflows  
│   ├── container-management.md   # OCI container patterns
│   ├── vm-deployment.md          # Proxmox deployment automation
│   └── security-audit.md         # Security validation patterns
├── agent-prompts/
│   ├── system-prompt.md          # Core agent behavior
│   ├── safety-guidelines.md      # Operational boundaries
│   └── project-context.md        # Homelab architecture context
└── agent-tools/
    ├── deployment-scripts/       # Automated deployment tools
    ├── testing-frameworks/       # Validation and testing
    └── monitoring-setup/         # Service monitoring configs
```

### 4.3 Curated Skill Set
**Essential Skills:**
- [ ] `nix-flake` - Flake development and management
- [ ] `nix-homelab` - Proxmox/VM deployment patterns
- [ ] `nix-lang` - Nix expression development
- [ ] `nix-debug` - Build error resolution
- [ ] Custom `homelab-architect` - Infrastructure design patterns
- [ ] Custom `vm-deployment` - Automated VM provisioning
- [ ] Custom `container-management` - OCI service management

## Phase 5: Safety & Operational Boundaries

### 5.1 Agent Safety Configuration
- [ ] Define operational boundaries in agent prompts
- [ ] Configure network access restrictions
- [ ] Set up resource monitoring and alerting
- [ ] Implement automatic rollback mechanisms
- [ ] Create emergency shutdown procedures

### 5.2 Workspace Isolation
```
/home/agent/
├── workspace/          # Agent development area
│   ├── homelab/       # Infrastructure projects
│   ├── testing/       # Local test environments
│   └── deployments/   # Deployment configurations
├── templates/         # Reusable configuration templates
├── scripts/           # Automation scripts
└── logs/             # Agent operation logs
```

### 5.3 Network Isolation Strategy
- [ ] Configure dedicated VLAN for agent VM
- [ ] Set up firewall rules for limited outbound access
- [ ] Allow access to: GitHub, Nix cache, Proxmox API, internal services
- [ ] Block access to: Production networks, sensitive internal services
- [ ] Monitor and log all network activity

## Phase 6: Testing & Validation Framework

### 6.1 Local Testing Environment
- [ ] Set up nested virtualization for VM testing
- [ ] Configure local container registry for image testing
- [ ] Create test data sets and scenarios
- [ ] Implement automated validation scripts
- [ ] Set up CI/CD pipeline for agent configurations

### 6.2 Deployment Testing Pipeline
```
Development Flow:
1. Agent develops Nix configuration
2. Local build and syntax validation
3. Test deployment in nested VM/container
4. Security and resource validation
5. Deployment to staging Proxmox VM
6. Production deployment (manual approval)
```

### 6.3 Validation Checklist
- [ ] Nix expression syntax validation (`nixfmt`, `nix flake check`)
- [ ] Build validation (`nix build --dry-run`)
- [ ] Security audit (firewall rules, service exposure)
- [ ] Resource usage validation (CPU, memory, storage)
- [ ] Network connectivity testing
- [ ] Service functionality verification

## Phase 7: Agent Prompts & Documentation

### 7.1 System Prompt Development
**Core Agent Behavior:**
- [ ] Define role as homelab infrastructure architect
- [ ] Establish safety protocols and operational boundaries
- [ ] Configure autonomous decision-making guidelines
- [ ] Set up escalation procedures for complex decisions
- [ ] Define success metrics and validation criteria

### 7.2 Project Context Documentation
- [ ] Document current homelab architecture
- [ ] Catalog existing services and their requirements
- [ ] Define infrastructure patterns and conventions
- [ ] Create service deployment templates
- [ ] Document security and networking requirements

### 7.3 Skills Documentation
- [ ] Create detailed skill descriptions and use cases
- [ ] Document workflow patterns for common tasks
- [ ] Establish code quality and security standards
- [ ] Create troubleshooting and debugging guides
- [ ] Set up knowledge base for common patterns

## Phase 8: Deployment & Operations

### 8.1 Initial VM Deployment
- [ ] Build VMA image with agent configuration
- [ ] Deploy to Proxmox with appropriate resources
- [ ] Configure networking and security
- [ ] Validate all tools and services are functional
- [ ] Test SSH access and Claude Code operation

### 8.2 Agent Initialization
- [ ] Start Claude Code with agent-specific configuration
- [ ] Load curated skills and project context
- [ ] Validate autonomous operation capabilities
- [ ] Test sample infrastructure development workflow
- [ ] Monitor initial agent behavior and resource usage

### 8.3 Operational Monitoring
- [ ] Set up logging and monitoring for agent activities
- [ ] Configure alerts for resource usage and errors
- [ ] Implement periodic health checks
- [ ] Create backup and recovery procedures
- [ ] Document operational procedures and troubleshooting

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

## Next Steps

1. **Immediate**: Set up git branch and basic VM configuration
2. **Week 1**: Complete Phase 1-3 (foundation, infrastructure, tools)
3. **Week 2**: Complete Phase 4-5 (Claude Code integration, safety)
4. **Week 3**: Complete Phase 6-7 (testing, prompts, documentation)  
5. **Week 4**: Complete Phase 8-9 (deployment, operations, iteration)

This roadmap provides a comprehensive foundation for building a safe, effective autonomous agent environment for homelab infrastructure development.