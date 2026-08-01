{ pkgs, ... }:
let
  modelsDir = "/var/lib/trellis";
  patchDir = "/home/yanglong/work/github/YangLongPH/nixos-config/docker/trellis/patches";
in
{
  systemd.services.trellis-api = {
    description = "TRELLIS 3D Generation API Server";
    after = [ "docker.service" "network-online.target" ];
    requires = [ "docker.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "exec";
      Restart = "on-failure";
      RestartSec = "10s";
      ExecStartPre = [
        "-${pkgs.docker}/bin/docker stop trellis-api"
        "-${pkgs.docker}/bin/docker rm trellis-api"
      ];
      ExecStart = 
        ${pkgs.docker}/bin/docker run \
          --name trellis-api \
          --device=nvidia.com/gpu=all \
          -p 8097:8097 \
          -v ${modelsDir}:/root/.cache/huggingface \
          -e HUGGINGFACE_HUB_CACHE=/root/.cache/huggingface \
          -e ATTN_BACKEND=sdpa \
          -v /home/yanglong/work/github/YangLongPH/nixos-config/docker/trellis/server.py:/app/server.py \
          -v ${patchDir}/trellis/modules/sparse/__init__.py:/app/trellis/modules/sparse/__init__.py \
          -v ${patchDir}/trellis/modules/sparse/attention/full_attn.py:/app/trellis/modules/sparse/attention/full_attn.py \
          -v ${patchDir}/trellis/modules/sparse/attention/serialized_attn.py:/app/trellis/modules/sparse/attention/serialized_attn.py \
          -v ${patchDir}/trellis/modules/sparse/attention/windowed_attn.py:/app/trellis/modules/sparse/attention/windowed_attn.py \
          trellis-api
      ;
      ExecStop = "${pkgs.docker}/bin/docker stop trellis-api";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${modelsDir} 0755 root root -"
  ];
}
