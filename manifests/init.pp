# Class: backupman
#
# This module manages {https://github.com/mstrauss/backupman BackupMan}
#
# Parameters:
#   $destdir: Where all the backed up data go.
#   $lockdir: Place where the lockfiles should go. Defaults to $destdir. BackupMan needs write access there too.
#   $sshapp:  The ssh command. Defaults to 'ssh'. But you can use something like 'ssh -i /home/me/.ssh/id_rsa' if you need.
#   $user:    The user account under which the BackupMan cron jobs run
#   $version: The BackupMan gem version to use - should fit together with this
#     module; expect things to break when you change the default.
#
# Actions:
#
# Requires:
#   - common: git://git.puppet.immerda.ch/module-common.git
#   - ssh::user
#
# Sample Usage:
#
# [Remember: No empty lines between comments and class definition]
class backupman(
  $destdir,
  $lockdir = "${destdir}/locks",
  $logdir = "${destdir}/logs",
  $sshapp = 'ssh',
  $user = 'backupman',
  $version = ''
) {
  
  # FixMe: this should come from the 'common' module, but that's broken right now
  managed_dir { '/var/lib/puppet/modules/backupman': }
  
  package { 'BackupMan': ensure => '0.1.5', provider => gem }
  
  # ssh::user - we have a 1 client to n servers setup here
  ssh::user { $user: role => client, definemaster => true }
  
  # # the servers need something like
  # ssh::user { $user: role => server }
  
  # we manage $destdir, $lockdir and $logdir
  managed_dir { $destdir: }
  if !defined( Managed_dir[$lockdir] ) {  managed_dir { $lockdir: } }
  if !defined( Managed_dir[$logdir] )  {  managed_dir { $logdir: } }
  
  # on the server, we collect and realizes all exported sources
  Rsync_for_backupman    <<| |>>
  Schedule_for_backupman <<| |>>
  

  # private
  define managed_dir ( $recurse = false ) {
    file { $title: ensure => directory, owner => $backupman::user, group => puppet, mode  => 640,
      recurse => $recurse }
  }
  
  # private
  define managed_file () {
    $dir = "/var/lib/puppet/modules/backupman/${name}.d"
    concatenated_file { "/var/lib/puppet/modules/backupman/${name}":
      dir => $dir,
      mode => 0644,
    }

    file {
      "${dir}/000-header":
        content => "# managed by Puppet - DO NOT EDIT\n#\nDESTDIR='${backupman::destdir}'\nLOCKDIR='${backupman::lockdir}'\nSSH_APP='${backupman::sshapp}'\n",
        mode => 0644, owner => root, group => 0,
        notify => Exec["concat_${dir}"];
    }
  }

  # private
  define entry ($line) {
    $target = "/var/lib/puppet/modules/backupman/${name}"
    $dir = dirname($target)
    file { $target:
      content => "${line}\n",
      mode => 0644, owner => root, group => 0,
      notify => Exec["concat_${dir}"],
    }
  }
  

  # Define: schedule
  #   Sets up an cron job on the BackupMan server.
  # Parameters:
  #   $title: the FQDN of the host
  #   $user: the account the cronjob will run with
  #   other paramters: passed to cron
  #
  # arguments
  #
  define schedule ( $user = 'backupman', $minute = undef, $hour = undef, $monthday = undef, $month = undef, $weekday = undef ) {
    @@schedule_for_backupman { $title:
      user     => $user,
      minute   => $minute,
      hour     => $hour,
      monthday => $monthday,
      month    => $month,
      weekday  => $weekday,
    }
  }

  define schedule_for_backupman ( $user = 'backupman', $minute = '*', $hour = '*', $monthday = '*', $month = '*', $weekday = '*' ) {
    cron { "BackupMan_${title}":
      user    => $user,
      command => "/usr/bin/backup_man -l '${backupman::logdir}/${title}.log' /var/lib/puppet/modules/backupman/${title}",
      minute  => $minute, hour => $hour, monthday => $monthday, month => $month, weekday => $weekday,
    }
  }
  

  # Define: rsync
  #   Use this definition on the server to be backed up.  It generates an
  #   exported resource for the BackupMan server.
  # Parameters:
  #   $title: a self-explanatory name for this definition
  #   $host: FQDN of remote host
  #   $sources: Array of remote directories to backup
  #   $destination: Local destination directory
  #   $user: Remote user name for SSH
  #   $options: Options for rsync
  define rsync ( $host, $sources, $destination = '', $user = '',
    $options = '-azR --delete --fake-super') {
    
      @@rsync_for_backupman { $title:
        host        => $host,
        sources     => $sources,
        destination => $destination,
        user        => $user,
        options     => $options,
      }
  }
  
  define rsync_for_backupman ( $host, $sources, $destination, $user, $options ) {

    if $destination == '' {
      $_destination_dir = "${backupman::destdir}/${host}/rsync_${title}"
      managed_dir { "${backupman::destdir}/${host}": }
    } else {
      $_destination_dir = $destination
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

    if $options == '' {
      $_options = ''
    } else {
      $_options = "b.options '${options}'; "
    }
    
    $_sources = array_to_s( $sources )

    managed_file{ $host: }
    entry { "${host}.d/rsync-${title}":
      line => "Rsync.new('${host}') {|b| b.backup ${_sources}; ${_destination}${_user}${_options} }",
    }
  }
  
}
