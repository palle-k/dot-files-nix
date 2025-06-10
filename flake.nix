# One flake to rule them all
{
  description = "Palle's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, homebrew-core, homebrew-cask, ... }:
  let
    configuration = { pkgs, config, ... }: {
      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = [
        pkgs.mkalias  # support for Spotlight indexing of installed apps
        pkgs.vim
        pkgs.python312
        (pkgs.python313.withPackages (python-pkgs: [
          python-pkgs.ipython
        ]))
        pkgs.ffmpeg-full
        pkgs.zsh
        pkgs.zsh-powerlevel10k
        pkgs.oh-my-zsh
        pkgs.zsh-autosuggestions
        pkgs.rsync
        pkgs.lsd
        pkgs.fzf
        pkgs.awscli2
        pkgs.git
        pkgs.wget
        pkgs.curl
        pkgs.jq
        pkgs.uv
        pkgs.ruff
        pkgs.nodejs_24
        pkgs.nodePackages."serve"
        pkgs.nodePackages."pm2"
        pkgs.gnupg
        pkgs.pkgconf
        pkgs.gcc
        pkgs.clang
        pkgs.cloc
        pkgs.mongosh
        pkgs.aws-sam-cli
        pkgs.ngrok
        pkgs.websocat
        pkgs.bun
      ];

      fonts.packages = [
        pkgs.nerd-fonts.jetbrains-mono
        pkgs.inter
      ];

      homebrew = {
        enable = true;

        brews = [
          "mas"  # mac app store
          "libevent"
          "openssl"
          "mongo-c-driver"
          "pango"
          "harfbuzz"
          "libffi"
          "libpst"
          "pv"
        ];

        casks = [
          "ghostty"
          "google-chrome"
          "1password"
          "betterdisplay"
          "chatgpt"
          "claude"
          "appcleaner"
          "discord"
          "displaylink"
          "sf-symbols"
          "zed"
          "orbstack"
          "pycharm"
          "mongodb-compass"
          "steam"
          "minecraft"
          "session-manager-plugin"
          "adobe-acrobat-reader"
          # "figma"
          "gephi"
          "redis-insight"
        ];

        masApps = {
          # "Xcode" = 497799835;
          # "AdBlock Pro" = 1018301773;
          # "Bear" = 1091189122;
          # "Apple Developer" = 640199958;
          # "Keynote" = 409183694;
          # "Numbers" = 409203825;
          # "Pages" = 409201541;
        };

        onActivation.cleanup = "zap";
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };

      system.primaryUser = "palle";

      system.activationScripts.extraActivation.text = ''
        softwareupdate --install-rosetta --agree-to-license

        xcode-select -p &>/dev/null || xcode-select --install
        # Wait until Xcode Command Line Tools installation has finished.
        until xcode-select -p &> /dev/null; do
          sleep 10;
        done

        xcodebuild -license accept
      '';
      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
        # Set up applications.
        echo "setting up /Applications..." >&2
        rm -rf /Applications/Nix\ Apps
        mkdir -p /Applications/Nix\ Apps
        find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
        while read -r src; do
          app_name=$(basename "$src")
          echo "copying $src" >&2
          ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
        done
            '';

      system.defaults = {
        dock.autohide = true;
        dock.largesize = 80;
        dock.tilesize = 64;
        dock.persistent-apps = [
          "/System/Applications/Mail.app"
          "/System/Cryptexes/App/System/Applications/Safari.app"
          "/Applications/Google Chrome.app"
          "/System/Applications/Messages.app"
          "/Applications/PyCharm.app"
          "/Applications/Xcode.app"
          "/Applications/Ghostty.app"
          "/System/Applications/Utilities/Activity Monitor.app"
          "/System/Applications/Calendar.app"
          "/System/Applications/Music.app"
          "/Applications/Bear.app"
          "/Applications/ChatGPT.app"
          "/System/Applications/Passwords.app"
          "/System/Applications/System Settings.app"
        ];

        finder.CreateDesktop = true;
        finder.ShowHardDrivesOnDesktop = true;
        finder.ShowExternalHardDrivesOnDesktop = true;
        finder.ShowMountedServersOnDesktop = true;
        finder.FXPreferredViewStyle = "Nlsv";

        loginwindow.GuestEnabled = false;

        ".GlobalPreferences"."com.apple.mouse.scaling" = 5.0;

        NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
        NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = false;
        NSGlobalDomain.NSAutomaticDashSubstitutionEnabled = false;
        NSGlobalDomain.NSAutomaticPeriodSubstitutionEnabled = false;
        NSGlobalDomain.NSAutomaticCapitalizationEnabled = false;

        NSGlobalDomain."com.apple.trackpad.enableSecondaryClick" = true;
        magicmouse.MouseButtonMode = "TwoButton";

        CustomUserPreferences = {
          "com.apple.Safari" = {
            "WebKitPreferences.developerExtrasEnabled" = true;
            IncludeDevelopMenu = true;
            WebKitDeveloperExtrasEnabledPreferenceKey = true;
            AutoOpenSafeDownloads = false;
            AlwaysRestoreSessionAtLaunch = true;
            ShowStandaloneTabBar = false;
          };

          "com.apple.Safari.SandboxBroker" = {
            "ShowDevelopMenu" = true;
          };

          "com.apple.AdLib" = {
            allowApplePersonalizedAdvertising = false;
            allowIdentifierForAdvertising = false;
          };

          "com.apple.Finder" = {
            "NSToolbar Configuration Browser"."TB Item Identifiers" = [
              "com.apple.finder.BACK"
              "com.apple.finder.SWCH"
              "NSToolbarSpaceItem"
              "com.apple.finder.PATH"
              "com.apple.finder.SHAR"
              "com.apple.finder.LABL"
              "com.apple.finder.ACTN"
              "NSToolbarSpaceItem"
              "com.apple.finder.SRCH"
            ];

            "NSToolbar Configuration Browser"."TB Display Mode" = 2;

            "NewWindowTarget" = "PfHm";  # New Finder windows show home directory.
          };
        };
      };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      programs.zsh = {
        enable = true;
        # enableCompletion = true;
        enableFzfCompletion = true;
        enableFzfHistory = true;
        enableSyntaxHighlighting = true;

        promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";

        interactiveShellInit = ''
          plugins=(git swiftpm cp docker gem git-flow man postgres xcode colored-man-pages colorize command-not-found extract web-search python pip virtualenv brew z)
          source ${pkgs.oh-my-zsh}/share/oh-my-zsh/oh-my-zsh.sh
          source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh

          alias ls='${pkgs.lsd}/bin/lsd'
          alias l='ls -l'
          alias la='ls -a'
          alias lla='ls -la'
          alias lt='ls --tree'

          alias dc='docker compose'
          alias dcu='docker compose up'
          alias dcd='docker compose down'
          alias dcl='docker compose logs -f'
          alias db='docker build'

          # add npm globally installed binaries to path
          export PATH="$PATH:$HOME/.npm/bin"
        '';
      };

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      security.pam.services.sudo_local.touchIdAuth = true;

      users.users.palle.shell = pkgs.zsh;
    };

    gitconfig = pkgs: pkgs.writeText "gitconfig" ''
    [user]
      name = "Palle Klewitz"
      email = "p@lle.dev"
      signingKey = ~/.ssh/id_rsa

    [commit]
      gpgSign = true

    [gpg]
      program = ${pkgs.gnupg}/bin/gpg
      format = ssh

    [core]
	    excludesfile = ~/.gitignore_global
	    editor = ${pkgs.vim}/bin/vim

    [init]
	    defaultBranch = main

	  [push]
	    autoSetupRemote = true

    [alias]
      yesterday = log --since='yesterday.midnight' --until='midnight' --all --no-merges --oneline --author=p@lle.dev
    '';

    gitignore = pkgs: pkgs.writeText "gitignore" ''
    .DS_Store
    .mypy_cache
    node_modules
    __pycache__
    .pytest_cache
    .vscode
    .idea
    *.iml
    .codebuddy
    '';

    ipython_config = pkgs: pkgs.writeText "ipython_config.py" ''
    c.InteractiveShellApp.extensions = ['autoreload']
    c.InteractiveShellApp.exec_lines = ['%autoreload 2']
    '';
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."work" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration

        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = "palle";

            # Optional: Declarative tap management
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
            };

            # Optional: Enable fully-declarative tap management
            #
            # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
            mutableTaps = false;
          };
        }

        ({pkgs, ...}: {
          nix.enable = false;
          system.activationScripts.postActivation.text = ''
            echo "writing git configuration..." >&2
            mkdir -p /Users/palle
            ln -sf ${gitconfig pkgs} /Users/palle/.gitconfig
            ln -sf ${gitignore pkgs} /Users/palle/.gitignore_global
            ln -sf ${ipython_config pkgs} /Users/palle/.ipython/profile_default/ipython_config.py
          '';
        })

     ];
    };
  };
}
