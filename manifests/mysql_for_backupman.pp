# $title : please use "hostname:databasename"
define backupman::mysql_for_backupman ( $host, $database, $destination, $user, $options = undef,
  $restore_enabled = false, $restore_identity = $host )
{
  if $destination == '' {
    $_destination_dir = "${backupman::destdir}/${host}/mysql"
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

  $_databases = join( $database, ' ' )

  if $options == undef {
    $__options = "-u root ${_databases}"
  } else {
    $__options = $options
  }
  
  $_options = "b.options '${__options}'; "
  
  $_filename = "b.filename '${database}.sql.gz'"

  # the BackupMan configuration file
  if !defined( Managed_file[$host] ) {
    managed_file{ $host: }
  }

  if $restore_enabled == true and $restore_identity == $host {
    # we do NOT do backups if restoring on same host is enabled!
    $_do_backup = false
  } else {
    $_do_backup = true
  }

  entry { "${host}.d/mysql-${title}":
    line => "Mysql.new('${host}') {|b| ${_destination}${_user}${_options}${_filename} }",
    ensure => $_do_backup ? {
      false   => absent,
      default => present,
    },
  }
  
  # --- Restoring ---
  # # we install a small rsync restore script to ease manual restore
  # $restore_source_dir = "mysql"
  # file { "${backupman::destdir}/${host}/mysql_restore":
  #   content => template( 'backupman/mysql_restore.erb' ),
  #   mode    => 755,
  #   ensure  => present,
  # }
  if $restore_enabled == true {
    debug( "Restoring enabled for #{title} with identity #{restore_identity}.")
    
    # for each source we check if a restore is required
    mysql_server_checks_for_restore { $database:
      restore_destination => $host,
      # we assume the default path
      restore_sourcepath  => "${backupman::destdir}/${restore_identity}/mysql",
    }
  }
}
