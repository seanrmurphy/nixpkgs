{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.soci-snapshotter;

  pluginArgs = concatStringsSep " " (map (x: "-p ${x}") cfg.plugins);
in {
  ###### interface

  options = {

    services.soci-snapshotter = {
      enable = mkEnableOption (lib.mdDoc "soci-snapshotter");

      config = mkOption {
        type = types.lines;
        default = "";
        description = lib.mdDoc "Soci-snapshotter config.";
      };

      package = mkPackageOption pkgs "soci-snapshotter" { };

      # plugins = mkOption {
      #   type = types.listOf types.path;
      #   default = [];
      #   description = lib.mdDoc ''
      #     A list of plugin paths to pass into fluentd. It will make plugins defined in ruby files
      #     there available in your config.
      #   '';
      # };
    };
  };


  ###### implementation

  config = mkIf cfg.enable {
    systemd.services.fluentd = with pkgs; {
      description = "Soci-snapshotter Daemon";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/soci-snapshotter-grpc";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      };
    };
  };
}
