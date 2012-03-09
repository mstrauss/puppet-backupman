# $title : name of database to restore
define backupman::mysql_server_checks_for_restore ( $restore_destination, $restore_sourcepath ) {
  exec { "${restore_destination}:mysql_${title}_missing?":
    # just a placeholder to run the test below without 'changing' the puppet state
    # (and thus producing a state change log entry)
    command => 'true',

    onlyif => shellquote([ 'sudo', '-u', 'backupman', 'ssh', "root@${restore_destination}",
      "test $( mysql -NBe 'select count(*) from information_schema.tables where table_schema=\"${title}\"' ) -eq 0",
    ]),
    # Good, let's restore!
    notify => Exec["${restore_destination}:mysql_${title}_restore"],
  }
  
  $logfile = shellquote("restore_for_${restore_destination}_$( date +%s ).log")
  exec{ "${restore_destination}:mysql_${title}_restore":
    refreshonly => true,
    cwd => $restore_sourcepath,
    command => "zcat '${title}.sql.gz' | sudo -u backupman ssh root@${restore_destination} mysql '${title}' | tee -a '${logfile}'",
    # command => "sudo -u backupman mysql  -e 'ssh -l root' -avr --fake-super --numeric-ids '${$restore_sourcepath}${title}/' '${restore_destination}:${title}' | tee -a '${logfile}'",
    # command => 'false',
  }
}
