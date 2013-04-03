# Define: rsync
#   Use this definition on the server to be backed up.  It generates an
#   exported resource for the BackupMan server.
# Parameters:
#   $title: the directory path to backup
#   $host: FQDN of remote host
#   $destination: Local destination directory
#   $user: Remote user name for SSH
#   $options: Options for rsync
# Restore:
#   $restore_enabled: Set to true to perform a restore to the source
#   directories when they are non-existent or empty. If any files are there,
#   no restore will be done.  The restore is checked for/performed on puppet
#   run.
#   $restore_identity: Use file from an other host for restore.
define backupman::rsync ( $host = $::fqdn, $destination = '', $user = '',
  $options = undef, $extra_options = undef,
  $restore_enabled = false, $restore_identity = $host,
  $pre_script = undef, $post_script = undef,
  $ensure = present )
{
  # rsync package
  if !defined(Package[rsync]) {
    package { rsync: ensure => installed }
  }
  
  # our backup definition to be put on the BackupMan server
  @@rsync_for_backupman { "${host}:${title}":
    host          => $host,
    directory     => $title,          # directory to backup
    destination   => $destination,
    user          => $user,
    options       => $options,
    extra_options => $extra_options,
    # If we have restore enabled, we check FROM THE SERVER if a restore is required.
    # If it is, the server then pushes the data to the client.      
    restore_enabled  => $restore_enabled,
    restore_identity => $restore_identity,
    pre_script    => $pre_script,
    post_script   => $post_script,
    ensure        => $ensure,
  }
  
  # # If we have restore enabled, we check on the client if a restore is required.
  # # If it is, the client exports the restore resource which then pushes the
  # # restore to the client.
  # # if $restore_enabled == 'true' {
  #   client_restore { $sources: }
  # # }

}
