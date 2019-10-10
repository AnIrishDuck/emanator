# frozen_string_literal: true

require 'emanator'
require 'emanator/change_data'
require 'emanator/change'

RSpec.describe Emanator do
  it 'has a version number' do
    expect(Emanator::VERSION).not_to be nil
  end

  describe '#process' do
    it 'handles basic insert change data' do
      data = File.new('spec/fixtures/cd.json').read
      change_data = Emanator::ChangeData.parse_wal2json(data)

      view = Emanator::Replica.new('target', 'SELECT a, b FROM table2_with_pk')
      expect(view.process(change_data)).to eq(
        [
          ['UPDATE emanator_progress SET txid = 1234', []],
          ['INSERT INTO target VALUES (?,?)', [1, 'Backup and Restore']],
          ['INSERT INTO target VALUES (?,?)', [3, 'Replication']]
        ]
      )
    end
  end
end
