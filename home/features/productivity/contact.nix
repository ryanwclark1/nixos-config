{
  config,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    khard
  ];

  accounts.contact = {
    basePath = "${config.home.homeDirectory}/Contacts";
    accounts.accent = {
      name = "accent";
      local = {
        type = "filesystem";
        fileExt = ".vcf";
      };

      # remote = {
      #   url = "http://localhost:1080/users/ryanc@accentvoice.com/calendar/";
      #   type = "caldav";
      #   userName = "ryanc@accentvoice.com";
      #   passwordCommand = [
      #     "cat"
      #     config.sops.secrets."accent-email/accent-email-password".path
      #   ];
      # };

      # vdirsyncer = {
      #   enable = true;
      #   collections = [ "calendar" ];
      #   itemTypes = [ "VEVENT" ];
      #   timeRange = {
      #     start = "datetime.now() - timedelta(days=7)";
      #     end = "datetime.now() + timedelta(days=30)";
      #   };
      # };
    };
  };

  home.file.".config/khard/khard.conf".text =
    /*
    toml
    */
    ''
      [addressbooks]
      [[contacts]]
      path = ~/Contacts

      [general]
      debug = no
      default_action = list
      editor = $EDITOR
      merge_editor = vimdiff

      [contact table]
      # display names by first or last name: first_name / last_name / formatted_name
      display = first_name
      # group by address book: yes / no
      group_by_addressbook = no
      # reverse table ordering: yes / no
      reverse = no
      # append nicknames to name column: yes / no
      show_nicknames = no
      # show uid table column: yes / no
      show_uids = no
      # sort by first or last name: first_name / last_name / formatted_name
      sort = last_name
      # localize dates: yes / no
      localize_dates = yes
      # set a comma separated list of preferred phone number types in descending priority
      # or nothing for alphabetical order
      preferred_phone_number_type = pref, cell, home
      # set a comma separated list of preferred email types in descending priority
      # or nothing for alphabetical order
      preferred_email_type = pref, work, home
    '';
}
