{ lib, python3Packages, ... }:

python3Packages.buildPythonApplication rec {
  pname = "nexus3-cli";
  version = "4.2.1";

  src = python3Packages.fetchPypi {
    inherit pname version;
    hash = "sha256-2CUIdu5bVPsRaZ2nkhhQE+HihCX7rHsDidbmFwXXPoU=";
  };

  pyproject = true;

  build-system = with python3Packages; [ setuptools ];

  postPatch = ''
    sed -i '/setup_requires/d' setup.py
  '';

  pythonRelaxDeps = [ "inflect" "semver" "twine" ];

  propagatedBuildInputs = with python3Packages; [
    click
    click-aliases
    inflect
    requests
    semver
    setuptools
    texttable
    twine
  ];

  doCheck = false;

  meta = with lib; {
    description = "CLI for Sonatype Nexus Repository Manager 3";
    homepage = "https://github.com/thiagofigueiro/nexus3-cli";
    license = licenses.mit;
    mainProgram = "nexus3";
  };
}
