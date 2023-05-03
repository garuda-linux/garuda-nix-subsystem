_: {
  boot = {
    consoleLogLevel = 0;
    initrd = {
      # extremely experimental, just the way I like it on a production machine
      systemd.enable = true;

      # strip copied binaries and libraries from inframs
      # saves 30~ mb space according to the nix derivation
      systemd.strip = true;
      verbose = false;
    };
    kernelParams = [ "quiet" ];
    plymouth = {
      enable = true;
      theme = "bgrt";
    };
  };
}
