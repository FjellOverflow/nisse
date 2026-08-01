{
  config,
  lib,
  user,
  variables,
  ...
}:

{
  services.xserver.xkb = {
    layout = lib.mkDefault variables.keyboardLayout;
    variant = lib.mkDefault "";
  };
  console.keyMap = lib.mkDefault variables.keyboardLayout;

  home-manager.users.${user} = _: {
    dconf.settings."org/gnome/desktop/input-sources" = {
      sources = lib.mkDefault [
        (lib.gvariant.mkTuple [
          "xkb"
          config.services.xserver.xkb.layout
        ])
      ];
    };
  };
}
