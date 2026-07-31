{ pkgs, ... }:
let
  modelsDir = "/var/lib/instantmesh";
in
{
  systemd.services.instantmesh-api = {
    description = "InstantMesh 3D Generation API Server";
    after = [ "docker.service" "network-online.target" ];
    requires = [ "docker.service" ];

    serviceConfig = {
      Type = "exec";
      Restart = "on-failure";
      RestartSec = "10s";
      ExecStartPre = [
        "-${pkgs.docker}/bin/docker stop instantmesh-api"
        "-${pkgs.docker}/bin/docker rm instantmesh-api"
      ];
      ExecStart = ''
        ${pkgs.docker}/bin/docker run \
          --name instantmesh-api \
          --device=nvidia.com/gpu=all \
          -p 8095:8095 \
          -v ${modelsDir}:/root/.cache/huggingface \
          -e HUGGINGFACE_HUB_CACHE=/root/.cache/huggingface \
          instantmesh-api
      '';
      ExecStop = "${pkgs.docker}/bin/docker stop instantmesh-api";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${modelsDir} 0755 root root -"
  ];
}
