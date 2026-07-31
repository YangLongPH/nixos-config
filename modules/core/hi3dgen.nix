{ pkgs, ... }:
let
  modelsDir = "/var/lib/hi3dgen";
in
{
  systemd.services.hi3dgen-api = {
    description = "Hi3DGen 3D Generation API Server";
    after = [ "docker.service" "network-online.target" ];
    requires = [ "docker.service" ];

    serviceConfig = {
      Type = "exec";
      Restart = "on-failure";
      RestartSec = "10s";
      ExecStartPre = [
        "-${pkgs.docker}/bin/docker stop hi3dgen-api"
        "-${pkgs.docker}/bin/docker rm hi3dgen-api"
      ];
      ExecStart = ''
        ${pkgs.docker}/bin/docker run \
          --name hi3dgen-api \
          --device=nvidia.com/gpu=all \
          -p 8096:8096 \
          -v ${modelsDir}:/root/.cache/huggingface \
          -e HUGGINGFACE_HUB_CACHE=/root/.cache/huggingface \
          hi3dgen-api
      '';
      ExecStop = "${pkgs.docker}/bin/docker stop hi3dgen-api";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${modelsDir} 0755 root root -"
  ];
}
