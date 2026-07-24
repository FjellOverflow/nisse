{ lib, ... }:

{
  services.xserver.xkb = {
    layout = lib.mkDefault "no";
    variant = lib.mkDefault "";
  };
  console.keyMap = lib.mkDefault "no";
}
