# Define: schedule
#   Sets up an cron job on the BackupMan server.
# Parameters:
#   $title: the FQDN of the host
#   $user: the account the cronjob will run with
#   other paramters: passed to cron
#
# arguments
#
define backupman::schedule ( $user = 'backupman', $minute = undef, $hour = undef, $monthday = undef, $month = undef, $weekday = undef, $ensure = present ) {
  @@schedule_for_backupman { $title:
    user     => $user,
    minute   => $minute,
    hour     => $hour,
    monthday => $monthday,
    month    => $month,
    weekday  => $weekday,
    ensure   => $ensure,
  }
}
