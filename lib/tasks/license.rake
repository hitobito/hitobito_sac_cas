# encoding: utf-8

namespace :app do
  namespace :license do
    task :config do # rubocop:disable Rails/RakeEnvironment
      @licenser = Licenser.new('hitobito_sac_cas',
                               'TODO: Customer Name',
                               'https://github.com/hitobito/hitobito_sac_cas')
    end
  end
end
