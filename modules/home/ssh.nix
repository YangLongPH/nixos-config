{ ... }:
let
  psiProdJump = "administrator@10.10.1.119,administrator@10.1.90.241";
  mkPsiProdHost = hostname: ip: {
    host = hostname;
    hostname = ip;
    user = "vgaia";
    proxyJump = psiProdJump;
  };
in
{
  programs.ssh = {
    enable = true;

    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        addKeysToAgent = "1h";

        controlMaster = "auto";
        controlPath = "~/.ssh/control-%r@%h:%p";
        controlPersist = "10m";

        forwardAgent = false;
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
      };

      psi-haproxy = {
        host = "psi-haproxy";
        hostname = "103.139.12.115";
        user = "goline";
      };

      goline-agent01 = {
        host = "goline-agent01";
        hostname = "10.10.3.200";
        user = "goline-agent01";
        extraOptions = {
          RequestTTY = "yes";
          RemoteCommand = "zsh -l";
        };
      };

      github = {
        host = "github.com";
        hostname = "ssh.github.com";
        user = "git";
        port = 443;
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };

      github-goline = {
        host = "github-w.com";
        hostname = "ssh.github.com";
        user = "git";
        port = 443;
        identityFile = "~/.ssh/id_ed25519_goline";
        identitiesOnly = true;
        # controlMaster = "no" + controlPath riêng để tránh reuse socket
        # của github.com (cùng host ssh.github.com:443 nhưng khác account)
        controlMaster = "no";
        controlPath = "none";
      };

      psi-215 = {
        host = "psi-215";
        hostname = "192.168.1.215";
        user = "administrator";
        proxyJump = "goline@10.10.1.132,goline@103.139.12.115";
      };

      psi-216 = {
        host = "psi-216";
        hostname = "192.168.1.216";
        user = "administrator";
        proxyJump = "goline@10.10.1.132,goline@103.139.12.115";
      };

      psi-217 = {
        host = "psi-217";
        hostname = "192.168.1.217";
        user = "administrator";
        proxyJump = "goline@10.10.1.132,goline@103.139.12.115";
      };

      psi-214 = {
        host = "psi-214";
        hostname = "192.168.1.214";
        user = "vgaia";
        proxyJump = "goline@10.10.1.132,goline@103.139.12.115";
      };

      psi-219 = {
        host = "psi-219 192.168.1.219";
        hostname = "192.168.1.219";
        user = "vgaia";
        proxyJump = "goline@10.10.1.132,goline@103.139.12.115";
      };

      psi-236 = {
        host = "psi-236";
        hostname = "192.168.1.236";
        user = "administrator";
        proxyJump = "goline@10.10.1.132,goline@103.139.12.115";
      };

      psi-237 = {
        host = "psi-237";
        hostname = "192.168.1.237";
        user = "administrator";
        proxyJump = "goline@10.10.1.132,goline@103.139.12.115";
      };

      psi-238 = {
        host = "psi-238";
        hostname = "192.168.1.238";
        user = "administrator";
        proxyJump = "goline@10.10.1.132,goline@103.139.12.115";
      };

      psi-239 = {
        host = "psi-239";
        hostname = "192.168.1.239";
        user = "vgaia";
        proxyJump = "goline@10.10.1.132,goline@103.139.12.115";
      };

      psi-prod-241 = {
        host = "psi-prod-241";
        hostname = "10.1.90.241";
        user = "administrator";
        proxyJump = "administrator@10.10.1.119";
      };

      # PSI PROD — wildcard cho IP trực tiếp (ansible dùng ansible_host IP)
      # Jump: 10.10.1.119 → 10.1.90.241 → target
      "psi-prod-core" = {
        host = "10.1.33.* 10.1.35.*";
        user = "vgaia";
        proxyJump = psiProdJump;
      };

      # PSI PROD — named entries cho SSH hostname
      psi-prod-vcoremanager01 = mkPsiProdHost "psi-prod-vcoremanager01" "10.1.33.74";
      psi-prod-vcoremanager02 = mkPsiProdHost "psi-prod-vcoremanager02" "10.1.33.75";
      psi-prod-vcoremanager03 = mkPsiProdHost "psi-prod-vcoremanager03" "10.1.33.76";
      psi-prod-vcoreback01    = mkPsiProdHost "psi-prod-vcoreback01"    "10.1.33.45";
      psi-prod-vcoreapp01     = mkPsiProdHost "psi-prod-vcoreapp01"     "10.1.33.110";
      psi-prod-vmarket01      = mkPsiProdHost "psi-prod-vmarket01"      "10.1.33.120";
      psi-prod-vmarket02      = mkPsiProdHost "psi-prod-vmarket02"      "10.1.33.121";
      psi-prod-vmiddleware01  = mkPsiProdHost "psi-prod-vmiddleware01"  "10.1.33.130";
      psi-prod-vmiddleware02  = mkPsiProdHost "psi-prod-vmiddleware02"  "10.1.33.131";
      psi-prod-vmiddleware03  = mkPsiProdHost "psi-prod-vmiddleware03"  "10.1.33.132";
      psi-prod-vmktmid01      = mkPsiProdHost "psi-prod-vmktmid01"      "10.1.33.140";
      psi-prod-vmktmid02      = mkPsiProdHost "psi-prod-vmktmid02"      "10.1.33.141";
      psi-prod-vmktmid03      = mkPsiProdHost "psi-prod-vmktmid03"      "10.1.33.142";
      psi-prod-vmonitor01     = mkPsiProdHost "psi-prod-vmonitor01"     "10.1.33.92";
      psi-prod-vfileserver01  = mkPsiProdHost "psi-prod-vfileserver01"  "10.1.33.83";
      psi-prod-vdockerhub01   = mkPsiProdHost "psi-prod-vdockerhub01"   "10.1.33.200";
      psi-prod-vdbfo01        = mkPsiProdHost "psi-prod-vdbfo01"        "10.1.35.20";
    };
  };

  services.ssh-agent.enable = true;
}
