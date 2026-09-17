{ ... }:
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

      psi-219 = {
        host = "psi-219";
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
    };
  };

  services.ssh-agent.enable = true;
}
