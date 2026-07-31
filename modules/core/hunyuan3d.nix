{ pkgs, ... }:
let
  modelsDir = "/var/lib/hunyuan3d";
in
{
  systemd.services.hunyuan3d-api = {
    description = "Hunyuan3D 3D Generation API Server";
    after = [ "docker.service" "network-online.target" ];
    requires = [ "docker.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "exec";
      Restart = "on-failure";
      RestartSec = "10s";
      ExecStartPre = [
        "-${pkgs.docker}/bin/docker stop hunyuan3d-api"
        "-${pkgs.docker}/bin/docker rm hunyuan3d-api"
      ];
      ExecStart = ''
        ${pkgs.docker}/bin/docker run \
          --name hunyuan3d-api \
          --device /dev/nvidia0 --device /dev/nvidiactl --device /dev/nvidia-uvm \
          -p 8094:8094 \
          -v ${modelsDir}:/root/.cache/huggingface \
          -e HUGGINGFACE_HUB_CACHE=/root/.cache/huggingface \
          hunyuan3d-api
      '';
      ExecStop = "${pkgs.docker}/bin/docker stop hunyuan3d-api";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${modelsDir} 0755 root root -"
  ];
}
