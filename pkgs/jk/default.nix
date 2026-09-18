{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "jk";
  version = "0.0.36";

  src = fetchFromGitHub {
    owner = "avivsinai";
    repo = "jenkins-cli";
    rev = "v${version}";
    hash = "sha256-iq6pecIp3nT963oBNOKlj9mU0r9BZwrlwb92vZctDAQ=";
  };

  vendorHash = "sha256-C+De7EVziBecP7ifXkychDb2h2mDWw3LidiDEaLnagQ=";

  meta = with lib; {
    description = "GitHub CLI-style Jenkins controller management";
    homepage = "https://github.com/avivsinai/jenkins-cli";
    license = licenses.mit;
    mainProgram = "jk";
  };
}
