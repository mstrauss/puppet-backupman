define backupman::rsync_server_checks_for_restore ( $restore_destination, $restore_sourcepath ) {
  exec { "${restore_destination}:${title}_missing?":
    # just a placeholder to run the test below without 'changing' the puppet state
    # (and thus producing a state change log entry)
    command => 'true',
    # first test: TRUE (retval=0) if the directory exists
    # second test: TRUE (retval=0) if any file is found
    # combination: when BOTH are true, we DO NOT restore;  if ANY is false, we DO restore
    # (the correct retval is 1 then;  ssh errors are 130 or 255 or others)
    onlyif => shellquote([ 'sudo', '-u', 'backupman', 'ssh', "root@${restore_destination}",
      "test -d '${title}' && test $( find '${title}' -type f | wc -l ) -ne 0; test $? -eq 1",
    ]),
    # Good, let's restore!
    notify => Exec["${restore_destination}:${title}_restore"],
  }
  
  $logfile = shellquote("restore_for_${restore_destination}_$( date +%s ).log")
  exec{ "${restore_destination}:${title}_restore":
    refreshonly => true,
    cwd => $restore_sourcepath,
    
    command => "sudo -u backupman rsync -e 'ssh -l root' -avr --fake-super --numeric-ids '${$restore_sourcepath}${title}/' '${restore_destination}:${title}' | tee -a '${logfile}'",
  }
}
