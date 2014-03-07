test_name 'Use a directory environment from environmentpath with an environment.conf'

testdir = master.tmpdir('use-environment-conf')
absolute_manifestdir = "#{testdir}/manifests"
absolute_modulesdir  = "#{testdir}/absolute-modules"
absolute_globalsdir  = "#{testdir}/global-modules"


apply_manifest_on(master, <<-MANIFEST, :catch_failures => true)
File {
  ensure => directory,
  owner => puppet,
  mode => 0700,
}

file {
  "#{testdir}":;
  "#{testdir}/environments":;
  "#{testdir}/environments/direnv":;
  "#{testdir}/environments/direnv/environment.conf":
    ensure => file,
    content => '
      manifest=#{absolute_manifestdir}
      modulepath=relative-modules:#{absolute_modulesdir}
      config_version=version_script.sh
    '
  ;

  "#{testdir}/environments/direnv/relative-modules":;
  "#{testdir}/environments/direnv/relative-modules/relmod":;
  "#{testdir}/environments/direnv/relative-modules/relmod/manifests":;
  "#{testdir}/environments/direnv/relative-modules/relmod/manifests/init.pp":
    ensure => file,
    content => 'class relmod {
      notify { "included relmod": }
    }'
  ;

  "#{testdir}/environments/direnv/version_script.sh":
    ensure => file,
    content => '#!/usr/bin/env sh
echo "ver123"
'
  ;

  "#{absolute_manifestdir}":;
  "#{absolute_manifestdir}/site.pp":
    ensure => file,
    content => '
      notify { "direnv site.pp": }
      include relmod
      include absmod
      include globalmod
    '
  ;

  "#{absolute_modulesdir}":;
  "#{absolute_modulesdir}/absmod":;
  "#{absolute_modulesdir}/absmod/manifests":;
  "#{absolute_modulesdir}/absmod/manifests/init.pp":
    ensure => file,
    content => 'class absmod {
      notify { "included absmod": }
    }'
  ;

  "#{absolute_globalsdir}":;
  "#{absolute_globalsdir}/globalmod":;
  "#{absolute_globalsdir}/globalmod/manifests":;
  "#{absolute_globalsdir}/globalmod/manifests/init.pp":
    ensure => file,
    content => 'class globalmod {
      notify { "included globalmod": }
    }'
  ;
}
MANIFEST

master_opts = {
  'master' => {
    'environmentpath' => "#{testdir}/environments",
    'basemodulepath' => "#{absolute_globalsdir}",
  }
}

with_puppet_running_on master, master_opts, testdir do
  agents.each do |agent|
    on(agent,
       puppet("agent", "-t", "--server", master, "--environment", "direnv"),
       :acceptable_exit_codes => [2]) do |result|

      assert_match(/direnv site.pp/, result.stdout)
      assert_match(/included relmod/, result.stdout)
      assert_match(/included absmod/, result.stdout)
      assert_match(/included globalmod/, result.stdout)
      assert_match(/Applying.*ver123/, result.stdout)
    end
  end
end
