# frozen_string_literal: true

require 'sqlite3'

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

    it 'can process delete change data' do
      data = File.new('spec/fixtures/cd-delete.json').read
      change_data = Emanator::ChangeData.parse_wal2json(data)

      view = Emanator::Replica.new('target', 'SELECT a, b FROM table2_with_pk')
      expect(view.process(change_data)).to eq(
        [
          ['UPDATE emanator_progress SET txid = 1234', []],
          ['INSERT INTO target VALUES (?,?)', [1, 'Backup and Restore']],
          ['INSERT INTO target VALUES (?,?)', [3, 'Replication']],
          ['DELETE FROM target WHERE (a = ?)', [1]]
        ]
      )
    end
  end

  describe 'when integrated with sqlite' do
    it '#process updates the view' do
      db = SQLite3::Database.new ':memory:'
      db.execute('CREATE TABLE emanator_progress (txid INTEGER);')
      db.execute('CREATE TABLE target (a INTEGER, b STRING);')

      data = File.new('spec/fixtures/cd-delete.json').read
      change_data = Emanator::ChangeData.parse_wal2json(data)

      view = Emanator::Replica.new('target', 'SELECT a, b FROM table2_with_pk')
      view.process(change_data).each do |sql, params|
        db.execute(sql, params)
      end
      expect(db.execute('SELECT a, b FROM target').to_a).to eq(
        [
          [3, 'Replication']
        ]
      )
    end
  end
end
