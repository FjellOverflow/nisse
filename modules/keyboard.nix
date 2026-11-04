{
  lib,
  variables,
  ...
}:

{
  services.xserver.xkb = {
    layout = lib.mkDefault variables.keyboardLayout;
    variant = lib.mkDefault "";
  };
  console.keyMap = lib.mkDefault (lib.head (lib.splitString "," variables.keyboardLayout));
}
