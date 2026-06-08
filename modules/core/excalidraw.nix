{ ... }:
{
  virtualisation.oci-containers = {
    backend = "docker";
    containers.excalidraw = {
      image = "excalidraw/excalidraw:latest";
      ports = [ "3333:80" ];
      autoStart = true;
    };
  };
}
