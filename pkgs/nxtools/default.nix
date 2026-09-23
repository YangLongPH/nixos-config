{ lib, buildGoModule, fetchFromGitHub, ... }:

buildGoModule rec {
  pname = "nxtools";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "jeanfrancoisgratton";
    repo = "nxtools";
    rev = "bde04ca97034007c283e293200d581df55a8f1c9";
    hash = "sha256-m61CxzlcCHUNmr/YO1RoRuuh7UXVXpFcBki3EsWOLl0=";
  };

  modRoot = "src";

  vendorHash = "sha256-a6kKSaCQpRBcYyiI6m3XwyF8Ia4/bS5+HtxHFq7lkMc=";

  meta = with lib; {
    description = "Nexus Repository Manager 3 CLI (REST API, credential management)";
    homepage = "https://github.com/jeanfrancoisgratton/nxtools";
    license = licenses.mit;
    mainProgram = "nxtools";
  };
}
