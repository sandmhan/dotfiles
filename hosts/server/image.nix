{ ... }:
{
  proxmox.qemuConf = {
    cores = 2;
    memory = 4096;
  };

  virtualisation.diskSize = 50 * 1024;
}
