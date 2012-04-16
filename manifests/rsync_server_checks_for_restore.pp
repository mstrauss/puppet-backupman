# $title : please use "hostname:/directory/path"
# $host  : the destination host
# $directory  : the destination directory
# $sourcepath : the source path on the backupman server
define backupman::rsync_server_checks_for_restore ( $host, $directory, $sourcepath ) {
  exec { "${title}_missing?":
    # just a placeholder to run the test below without 'changing' the puppet state
    # (and thus producing a state change log entry)
    command => 'true',
    # first test: TRUE (retval=0) if the directory exists
    # second test: TRUE (retval=0) if any file is found
    # combination: when BOTH are true, we DO NOT restore;  if ANY is false, we DO restore
    # (the correct retval is 1 then;  ssh errors are 130 or 255 or others)
    onlyif => shellquote([ 'sudo', '-u', 'backupman', 'ssh', "root@${host}",
      "test -d '${directory}' && test $( find '${directory}' -type f | wc -l ) -ne 0; test $? -eq 1",
    ]),
    # Good, let's restore!
    notify => Exec["restore ${title}"],
  }
  
  $_directory = regsubst( $directory, '/', '_', 'G' )
  
  $logfile = shellquote("restore_for${_directory}_$( date +%s ).log")
  exec{ "restore ${title}":
    refreshonly => true,
    cwd => $restore_sourcepath,
    command => "sudo -u backupman rsync -e 'ssh -l root' -avr --fake-super --numeric-ids '${sourcepath}/' '${host}:${directory}' | tee -a '${logfile}'",
  }
}
