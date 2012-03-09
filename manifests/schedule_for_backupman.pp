# $title : hostname
define backupman::schedule_for_backupman ( $user = 'backupman', $minute = '*', $hour = '*', $monthday = '*', $month = '*', $weekday = '*', $ensure = present ) {

  file { "${backupman::logdir}/${title}": ensure => directory, owner => backupman }
  
  cron { "BackupMan_${title}":
    user    => $user,
    command => "/usr/bin/backup_man -l '${backupman::logdir}/${title}/backupman.log' /var/lib/puppet/modules/backupman/${title}",
    minute  => $minute, hour => $hour, monthday => $monthday, month => $month, weekday => $weekday,
    ensure  => $ensure,
  }
}
