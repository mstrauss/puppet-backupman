define backupman::schedule_for_backupman ( $user = 'backupman', $minute = '*', $hour = '*', $monthday = '*', $month = '*', $weekday = '*', $ensure = present ) {
  cron { "BackupMan_${title}":
    user    => $user,
    command => "/usr/bin/backup_man -l '${backupman::logdir}/${title}.log' /var/lib/puppet/modules/backupman/${title}",
    minute  => $minute, hour => $hour, monthday => $monthday, month => $month, weekday => $weekday,
    ensure  => $ensure,
  }
}
