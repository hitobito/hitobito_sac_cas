# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Sftp do
  let(:config) do
    Config::Options.new(host: 'sftp.local',
                        user: 'hitobito',
                        password: 'password',
                        private_key: 'private key',
                        port: 22)
  end

  subject { Sftp.new(config) }

  context 'with password' do
    before { config.delete_field!(:private_key) }

    it 'creates connection with password credential' do
      session = double

      expect(::Net::SFTP).to receive(:start)
                         .with('sftp.local', 'hitobito', { password: 'password',
                                                           non_interactive: true,
                                                           port: 22 })
                       .and_return(session)
      expect(session).to receive(:connect!)

      subject.send(:connection)
    end
  end

  context 'with private key' do
    before { config.delete_field!(:password) }

    it 'creates connection with private key' do
      session = double

      expect(::Net::SFTP).to receive(:start)
                        .with('sftp.local', 'hitobito', { key_data: ['private key'],
                                                          non_interactive: true,
                                                          port: 22 })
                       .and_return(session)
      expect(session).to receive(:connect!)

      subject.send(:connection)
    end
  end

  context 'with private key and password' do
    it 'creates connection with private key' do
      session = double

      expect(::Net::SFTP).to receive(:start)
                         .with('sftp.local', 'hitobito', { key_data: ['private key'],
                                                           non_interactive: true,
                                                           port: 22 })
                       .and_return(session)
      expect(session).to receive(:connect!)

      subject.send(:connection)
    end
  end

end
