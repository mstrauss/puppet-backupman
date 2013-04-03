# $title : please use "hostname:/directory/path"
define backupman::rsync_for_backupman ( $host, $directory, $destination, $user, $options = undef, $extra_options = undef,
  $restore_enabled = false, $restore_identity = $host,
  $pre_script = undef, $post_script = undef,
  $ensure = present )
{
  if $destination == '' {
    $_destination_dir = "${backupman::destdir}/${host}/rsync"
    if !defined( Managed_dir["${backupman::destdir}/${host}"] ) {
      managed_dir { "${backupman::destdir}/${host}": }
    }
  } else {
    $_destination_dir = $destination
    if $restore_identity != $host {
      crit( "Cannot use other restore_identity with non-default destination." )
    }
  }
  $_destination = "b.to '${_destination_dir}'; "
  
  # a) one managed_dir per resource and
  # b) no recursion, cause that is slow and breaks the restore
  # it's not needed anyway 'cause the top level dirs are secured
  if( !defined( Managed_dir[$_destination_dir] ) ) {
    managed_dir { $_destination_dir: recurse => false }
  }

  if $user == '' {
    $_user = ''
  } else {
    $_user = "b.user '${user}'; "
  }

  $_directory = regsubst( $directory, '/', '_', 'G' )
  
  if $extra_options == undef {
    $__extra_options = ""
  } else {
    $__extra_options = $extra_options
  }
  
  if $options == undef {
    # by default we log into the same file as 
    $rsynclog = "${backupman::logdir}/${host}/rsync${_directory}.log"
    # --numeric-ids required when using --fake-super (ext. attributes ALWAYS store
    # numeric ids only)
    $__options = "-azR --delete --fake-super --numeric-ids --log-file=${rsynclog} ${__extra_options}"
  } else {
    $__options = $options
  }
  
  $_options = "b.options '${__options}'; "

  # the BackupMan configuration file
  if !defined( Managed_file[$host] ) {
    managed_file{ $host: }
  }
  
  if $ensure == present {
    if $restore_enabled == true and $restore_identity == $host {
      # we do NOT do backups if restoring on same host is enabled!
      $_do_backup = false
    } else {
      $_do_backup = true
    }
  } else {
    $_do_backup = false
  }
  
  entry { "${host}.d/rsync${_directory}":
    line => "Rsync.new('${host}') {|b| b.backup '${directory}'; ${_destination}${_user}${_options} }",
    ensure => $_do_backup ? {
      false   => absent,
      default => present,
    },
  }
  
  # --- Restoring ---
  # we install a small rsync restore script to ease manual restore
  $restore_source_dir = "rsync"
  file { "${backupman::destdir}/${host}/rsync${_directory}_restore":
    content => template( 'backupman/restore.erb' ),
    mode    => 755,
    ensure  => present,
  }

  if $restore_enabled == true {
    debug( "Restoring enabled for #{title} with identity #{restore_identity}.")
    
    # for each source we check if a restore is required
    rsync_server_checks_for_restore { $title:
      # manage the Backupman cron job first
      require => Entry["${host}.d/rsync${_directory}"],
      host => $host,
      directory => $directory,
      sourcepath  => "${backupman::destdir}/${restore_identity}/rsync${directory}",
    }
  }
}
