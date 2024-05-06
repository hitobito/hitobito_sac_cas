$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your wagon's version:
require 'hitobito_sac_cas/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  # rubocop:disable SingleSpaceBeforeFirstArg
  s.name        = 'hitobito_sac_cas'
  s.version     = HitobitoSacCas::VERSION
  s.authors     = ['Carlo Beltrame', 'Pascal Simon']
  s.email       = ['beltrame@puzzle.ch', 'simon@puzzle.ch']
  s.homepage    = 'https://sac-cas.ch'
  s.summary     = 'SAC CAS'
  s.description = 'Organization structure and specific features for SAC CAS'

  s.files = Dir['{app,config,db,lib}/**/*'] + ['Rakefile']
  s.test_files = Dir['test/**/*']
  s.add_dependency 'hitobito_youth'
  s.add_dependency 'net-ssh', '~> 7.0.0.beta1' # TODO: remove once net-sftp 3 updates ssh 7
  s.add_dependency 'net-sftp'
  # rubocop:enable SingleSpaceBeforeFirstArg
end
