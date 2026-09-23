{ lib, buildGoModule, fetchFromGitHub, ... }:

buildGoModule rec {
  pname = "nexus3-cli-go";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "liang-junwei";
    repo = "nexus3-cli";
    rev = "29e9860cb150890cc29fd4da075428ae8f1db3b3";
    hash = "sha256-6YiAHV3sZW53J38JrbsKcXF9TO+KSn/AgrljbIWu5xE=";
  };

  vendorHash = "sha256-komX1AmHt2NoF1x6xsNa2RFkfVzOXfYEMPhT0zwMxjw=";

  meta = with lib; {
    description = "Nexus Repository Manager 3 CLI (REST API, no scripting)";
    homepage = "https://github.com/liang-junwei/nexus3-cli";
    license = licenses.mit;
    mainProgram = "nexus3-cli";
  };
}
