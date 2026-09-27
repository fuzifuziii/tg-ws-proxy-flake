{
  description = "tg-ws-proxy — local MTProto proxy for Telegram Desktop via WebSocket";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python3;

        customtkinter = python.pkgs.buildPythonPackage rec {
          pname = "customtkinter";
          version = "5.2.2";
          format = "pyproject";
          src = pkgs.fetchurl {
            url = "https://files.pythonhosted.org/packages/source/c/customtkinter/customtkinter-5.2.2.tar.gz";
            sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          };
          build-system = [ python.pkgs.setuptools ];
          propagatedBuildInputs = [ python.pkgs.tkinter darkdetect ];
          doCheck = false;
        };

        darkdetect = python.pkgs.buildPythonPackage rec {
          pname = "darkdetect";
          version = "0.8.0";
          format = "pyproject";
          src = python.pkgs.fetchPypi {
            inherit pname version;
            sha256 = "sha256-tUKOEXAmPrXepEwl3DiV7ddeb1IwCYY1PNY1M/59+LE=";
          };
          build-system = [ python.pkgs.setuptools ];
          doCheck = false;
        };

        pystray = python.pkgs.buildPythonPackage rec {
          pname = "pystray";
          version = "0.19.5";
          format = "pyproject";
          src = python.pkgs.fetchPypi {
            inherit pname version;
            sha256 = "sha256-FaTJvD5vUZ34AeJzMGNfQ4HObGAPpBbYkqMcTEXJijM=";
          };
          build-system = [ python.pkgs.setuptools ];
          propagatedBuildInputs = [ python.pkgs.pillow ]
            ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ python.pkgs.pygobject3 ];
          doCheck = false;
        };

        tg-ws-proxy = python.pkgs.buildPythonPackage {
          pname = "tg-ws-proxy";
          version = "unstable";
          format = "pyproject";

          src = pkgs.fetchFromGitHub {
            owner = "Flowseal";
            repo = "tg-ws-proxy";
            rev = "caa949bee0873d2b95dfb4fbeb1b7868b0ee3843";
            sha256 = "sha256-c/A66gt5buAbdOBlZ3cVwXfKsHPHdXYJAXGxXObg6Ok=";
          };

          build-system = [ python.pkgs.hatchling ];

          propagatedBuildInputs = with python.pkgs; [
            pyperclip
            certifi
            psutil
            cryptography
            pillow
            customtkinter
            pystray
          ];

          doCheck = false;

          meta = {
            description = "Local MTProto proxy for Telegram Desktop via WebSocket";
            homepage = "https://github.com/Flowseal/tg-ws-proxy";
            license = pkgs.lib.licenses.mit;
            mainProgram = "tg-ws-proxy-tray-linux";
          };
        };

      in {
        packages.default = tg-ws-proxy;
        packages.tg-ws-proxy = tg-ws-proxy;

        apps.default = flake-utils.lib.mkApp {
          drv = tg-ws-proxy;
          exePath = "/bin/tg-ws-proxy-tray-linux";
        };

        devShells.default = pkgs.mkShell {
          packages = [ (python.withPackages (_: [ tg-ws-proxy ])) ];
        };
      }
    )
    // {
      nixosModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.services.tg-ws-proxy;
          pkg = self.packages.${pkgs.system}.default;
        in {
          options.services.tg-ws-proxy = {
            enable = lib.mkEnableOption "tg-ws-proxy MTProto WebSocket proxy";

            user = lib.mkOption {
              type = lib.types.str;
              description = "Пользователь, от имени которого запускать прокси";
            };

            port = lib.mkOption {
              type = lib.types.port;
              default = 1443;
              description = "Локальный порт MTProto прокси";
            };
          };

          config = lib.mkIf cfg.enable {
            systemd.user.services.tg-ws-proxy = {
              description = "tg-ws-proxy MTProto WebSocket proxy";
              wantedBy = [ "default.target" ];
              after = [ "network.target" ];
              serviceConfig = {
                ExecStart = "${pkg}/bin/tg-ws-proxy";
                Restart = "on-failure";
                RestartSec = "5s";
              };
            };
          };
        };
    };
}
