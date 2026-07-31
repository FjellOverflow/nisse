{ user, ... }:

{
  home-manager.users.${user} = _: {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
