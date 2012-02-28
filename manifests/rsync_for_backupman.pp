define backupman::rsync_for_backupman ( $setname, $host, $sources, $destination, $user, $options = undef,
  $restore_enabled = false, $restore_identity = $host )
{
  if $destination == '' {
    $_destination_dir = "${backupman::destdir}/${host}/rsync_${setname}"
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
  
  # no recursion, cause that is slow and breaks the restore
  # it's not needed anyway 'cause the top level dirs are secured
  managed_dir { $_destination_dir: recurse => false }

  if $user == '' {
    $_user = ''
  } else {
    $_user = "b.user '${user}'; "
  }

  if $options == undef {
    # by default we log into the same file as 
    $rsynclog = "${backupman::logdir}/${host}_rsync_${setname}.log"
    # --numeric-ids required when using --fake-super (ext. attributes ALWAYS store
    # numeric ids only)
    $__options = "-azR --delete --fake-super --numeric-ids --log-file=${rsynclog}"
  } else {
    $__options = $options
  }
  
  $_options = "b.options '${__options}'; "
  $_sources = array_to_s( $sources )

  # the BackupMan configuration file
  if !defined( Managed_file[$host] ) {
    managed_file{ $host: }
  }
  entry { "${host}.d/rsync-${title}":
    line => "Rsync.new('${host}') {|b| b.backup ${_sources}; ${_destination}${_user}${_options} }",
  }
  
  # --- Restoring ---
  # we install a small rsync restore script to ease manual restore
  $restore_source_dir = "rsync_${setname}"
  file { "${backupman::destdir}/${host}/rsync_${setname}_restore":
    content => template( 'backupman/restore.erb' ),
    mode    => 755,
    ensure  => present,
  }
  if $restore_enabled == true {
    debug( "Restoring enabled for #{title} with identity #{restore_identity}.")
    
    # for each source we check if a restore is required
    rsync_server_checks_for_restore { $sources:
      restore_destination => $host,
      # we assume the default path
      restore_sourcepath  => "${backupman::destdir}/${restore_identity}/rsync_${setname}",
    }
  }
}
