# tg-ws-proxy Nix flake

Nix flake for [tg-ws-proxy](https://github.com/Flowseal/tg-ws-proxy) — a local MTProto proxy for Telegram Desktop that routes traffic through WebSocket connections.

## Run without installing

```sh
nix run github:fuzifuziii/tg-ws-proxy-flake
```

## Add to your system flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    tg-ws-proxy.url = "github:fuzifuziii/tg-ws-proxy-flake";
  };

  outputs = { nixpkgs, tg-ws-proxy, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        tg-ws-proxy.nixosModules.default
        {
          services.tg-ws-proxy = {
            enable = true;
            user = "youruser";
          };
        }
      ];
    };
  };
}
```

## Just the package

```nix
environment.systemPackages = [
  tg-ws-proxy.packages.${system}.default
];
```
