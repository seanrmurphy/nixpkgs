{ lib
, buildPythonPackage
, fetchFromGitHub
, poetry-core
, home-assistant
, python
}:

buildPythonPackage rec {
  pname = "homeassistant-stubs";
  version = "2024.2.3";
  format = "pyproject";

  disabled = python.version != home-assistant.python.version;

  src = fetchFromGitHub {
    owner = "KapJI";
    repo = "homeassistant-stubs";
    rev = "refs/tags/${version}";
    hash = "sha256-kBr9NaP1FBTMBloAXEpx4s4iMe1T45i7Gui1aULQPXg=";
  };

  nativeBuildInputs = [
    poetry-core
    home-assistant
  ];

  postPatch = ''
    # Relax constraint to year and month
    substituteInPlace pyproject.toml --replace-fail \
      'homeassistant = "${version}"' \
      'homeassistant = "~${lib.versions.majorMinor home-assistant.version}"'
  '';

  pythonImportsCheck = [
    "homeassistant-stubs"
  ];

  doCheck = false;

  meta = with lib; {
    description = "Typing stubs for Home Assistant Core";
    homepage = "https://github.com/KapJI/homeassistant-stubs";
    changelog = "https://github.com/KapJI/homeassistant-stubs/releases/tag/${version}";
    license = licenses.mit;
    maintainers = teams.home-assistant.members;
  };
}
