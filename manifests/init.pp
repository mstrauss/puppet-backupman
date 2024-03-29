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
  $group = 'root',
  $version = ''
) {
  
  # FixMe: this should come from the 'common' module, but that's broken right now
  managed_dir { '/var/lib/puppet/modules/backupman': purge => true, recurse => true, force => true }
  
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
  Rsync_for_backupman         <<| |>>
  Mysql_for_backupman         <<| |>>
  Schedule_for_backupman      <<| |>>  
  # # does not work: Could not find resource type 'mysql_for_backupman'
  # resources { [rsync_for_backupman, schedule_for_backupman]: purge => true }
  # resources { mysql_for_backupman: purge => true }
  
  # THIS DOES NOT WORK (as for Puppet 3.1.1): http://projects.puppetlabs.com/issues/3220
  resources { cron: purge => true }
  
  # private
  define managed_dir ( $recurse = false, $purge = false, $force = false ) {
    file { $title: ensure => directory, owner => $::backupman::user, group => $::backupman::group, mode  => 640,
      recurse => $recurse, purge => $purge, force => $force }
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
        content => "# managed by Puppet - DO NOT EDIT\n#\nDESTDIR='${::backupman::destdir}'\nLOCKDIR='${::backupman::lockdir}'\nSSH_APP='${::backupman::sshapp}'\n",
        mode => 0644, owner => root, group => 0,
        notify => Exec["concat_${dir}"];
    }
  }

  # private
  define entry ( $line, $ensure = present ) {
    $target = "/var/lib/puppet/modules/backupman/${name}"
    $dir = dirname($target)
    file { $target:
      content => "${line}\n",
      mode => 0644, owner => root, group => 0,
      ensure => $ensure,
      notify => Exec["concat_${dir}"],
    }
  }
    


}
