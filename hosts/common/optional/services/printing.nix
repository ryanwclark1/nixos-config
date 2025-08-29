{
  pkgs,
  ...
}:

{
  services.avahi = {
    enable = true;
    openFirewall = true;
    nssmdns4 = true; # Allows software to use Avahi to resolve.
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
      userServices = true;
    };
  };

  # Cupsd configuration for printing
  services.printing = {
    enable = true;
    browsing = true;
    defaultShared = false; # Don't share local printers by default
    openFirewall = true;   # Allow network printer discovery
    startWhenNeeded = true; # Socket activation - more efficient
    webInterface = true;   # Enable CUPS web interface at localhost:631
    
    # PDF printer configuration
    cups-pdf = {
      enable = true;
      instances = {
        pdf = {
          settings = {
            Out = "\${HOME}/Documents/PDF-Prints";
            UserUMask = "0022"; # Readable by owner and group
            Label = 1;          # Add labels to filename
            TitlePref = 1;      # Prefer document title in filename
          };
        };
      };
    };
    
    # Printer drivers
    drivers = with pkgs; [ 
      hplipWithPlugin    # HP printers
      gutenprint         # High-quality drivers for many printers
      canon-cups-ufr2    # Canon printers
      epson-escpr        # Epson printers
    ];
    
    # Logging configuration
    logLevel = "warn"; # Reduce log verbosity (default is "info")
    
    # Additional CUPS configuration
    extraConf = ''
      # Security settings
      DefaultAuthType Basic
      DefaultEncryption Never
      
      # Performance settings
      MaxJobs 100
      MaxJobsPerPrinter 10
      PreserveJobHistory On
      PreserveJobFiles Off
      
      # Browsing settings
      BrowseLocalProtocols CUPS
      BrowseWebIF Yes
      
      # Auto-purge jobs older than 1 week
      MaxJobTime 604800
    '';
  };
}
