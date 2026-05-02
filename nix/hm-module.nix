self:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.niri-notify-focus;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.services.niri-notify-focus = {
    enable = lib.mkEnableOption "niri-notify-focus, a daemon that focuses the source window when a notification is clicked under niri";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.niri-notify-focus;
      defaultText = lib.literalExpression "niri-notify-focus.packages.\${system}.niri-notify-focus";
      description = "The niri-notify-focus package to use.";
    };

    systemd.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to install a systemd user unit that starts the daemon as part
        of `graphical-session.target`. Disable this if you start the daemon
        another way (for example, via `spawn-at-startup` in your niri config).
      '';
    };

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          effect = "shrink";
          pulse_pixels = 50;
        }
      '';
      description = ''
        Settings written to `$XDG_CONFIG_HOME/niri-notify-focus/config.toml`.
        See <https://github.com/Oaklight/niri-notify-focus/blob/master/config.toml.example>
        for available keys.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."niri-notify-focus/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "niri-notify-focus-config.toml" cfg.settings;
    };

    systemd.user.services.niri-notify-focus = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "Focus source window on notification click (niri)";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
