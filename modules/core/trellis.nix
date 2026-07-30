{ pkgs, ... }:
let
  modelsDir = "/var/lib/trellis";
in
{
  systemd.services.trellis-api = {
    description = "TRELLIS 3D Generation API Server";
    after = [ "docker.service" "network-online.target" ];
    requires = [ "docker.service" ];

    serviceConfig = {
      Type = "exec";
      Restart = "on-failure";
      RestartSec = "10s";
      ExecStartPre = [
        "-${pkgs.docker}/bin/docker stop trellis-api"
        "-${pkgs.docker}/bin/docker rm trellis-api"
      ];
      ExecStart = ''
        ${pkgs.docker}/bin/docker run \
          --name trellis-api \
          --gpus all \
          -p 8092:8092 \
          -v ${modelsDir}:/root/.cache/huggingface \
          -e HUGGINGFACE_HUB_CACHE=/root/.cache/huggingface \
          trellis-api
      '';
      ExecStop = "${pkgs.docker}/bin/docker stop trellis-api";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${modelsDir} 0755 root root -"
  ];
}
