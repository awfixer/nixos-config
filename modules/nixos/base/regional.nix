# Regional and Internationalization Settings
# Configure timezone, locale, and language settings for the system
# NixOS i18n configuration: https://nixos.org/manual/nixos/stable/#sec-i18n
# Timezone database: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
{
  ...
}:

{
  # System timezone configuration
  # Use 'timedatectl list-timezones' to see available timezones
  time.timeZone = "America/Los_Angeles";  # Pacific Time Zone

  # Primary system locale
  # Determines language for system messages, default formatting, etc.
  i18n.defaultLocale = "en_US.UTF-8";

  # Specific locale settings for different categories
  # These can be customized independently for different regions/preferences
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";        # Address formatting
    LC_IDENTIFICATION = "en_US.UTF-8"; # Personal name formatting
    LC_MEASUREMENT = "en_US.UTF-8";    # Measurement units (metric/imperial)
    LC_MONETARY = "en_US.UTF-8";       # Currency formatting
    LC_NAME = "en_US.UTF-8";           # Personal name conventions
    LC_NUMERIC = "en_US.UTF-8";        # Number formatting (decimal separators, etc.)
    LC_PAPER = "en_US.UTF-8";          # Paper size standards
    LC_TELEPHONE = "en_US.UTF-8";      # Telephone number formatting
    LC_TIME = "en_US.UTF-8";           # Date and time formatting
  };
  
  # Additional regional settings that can be configured:
  # console.keyMap = "us";             # Console keyboard layout
  # services.xserver.layout = "us";    # X11 keyboard layout
}
