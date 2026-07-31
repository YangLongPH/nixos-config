{ pkgs, ... }:
let
  modelsDir = "/var/lib/triposg";
in
{
  systemd.services.triposg-api = {
    description = "TripoSG 3D Generation API Server";
    after = [ "docker.service" "network-online.target" ];
    requires = [ "docker.service" ];

    serviceConfig = {
      Type = "exec";
      Restart = "on-failure";
      RestartSec = "10s";
      ExecStartPre = [
        "-${pkgs.docker}/bin/docker stop triposg-api"
        "-${pkgs.docker}/bin/docker rm triposg-api"
      ];
      ExecStart = ''
        ${pkgs.docker}/bin/docker run \
          --name triposg-api \
          --device=nvidia.com/gpu=all \
          -p 8093:8093 \
          -v ${modelsDir}:/app/pretrained_weights \
          -e PRETRAINED_WEIGHTS_PATH=/app/pretrained_weights \
          triposg-api
      '';
      ExecStop = "${pkgs.docker}/bin/docker stop triposg-api";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${modelsDir} 0755 root root -"
  ];
}
