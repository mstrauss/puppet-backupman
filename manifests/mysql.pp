# Define: mysql
#   Use this definition on the server to be backed up.  It generates an
#   exported resource for the BackupMan server.
# Parameters:
#   $title: database name
#   $host: FQDN of remote host
#   $destination: Local destination directory
#   $user: Remote user name for SSH
#   $options: Options for mysqldump
# Restore:
#   $restore_enabled: Set to true to perform a restore to the source
#   Databases with zero tables are restored.  The restore is checked for/performed on puppet runs.
#   $restore_identity: Use file from an other host for restore.
define backupman::mysql ( $host = $::fqdn, $destination = '', $user = '',
  $options = undef,
  $restore_enabled = false, $restore_identity = $host )
{
  
  # Class[mysql::newserver] -> Backupman::Mysql[$title]
  
  # our backup definition to be put on the BackupMan server
  @@mysql_for_backupman { "${host}:${title}":
    host        => $host,
    database    => $title,
    destination => $destination,
    user        => $user,
    options     => $options,
    # If we have restore enabled, we check FROM THE SERVER if a restore is required.
    # If it is, the server then pushes the data to the client.      
    restore_enabled  => $restore_enabled,
    restore_identity => $restore_identity,
  }
  
  # If we have restore enabled, we require that the database is managed by
  # puppet.
  if $restore_enabled != false {
    Mysql::Database[$title] -> Backupman::Mysql[$title]
  }

}
