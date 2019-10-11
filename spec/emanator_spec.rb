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
          ['INSERT OR IGNORE INTO emanator_progress(txid, view) VALUES(?, ?)', [1234, 'target']],
          ['UPDATE emanator_progress SET txid = ? WHERE view = ?', [1234, 'target']],
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
          ['INSERT OR IGNORE INTO emanator_progress(txid, view) VALUES(?, ?)', [1234, 'target']],
          ['UPDATE emanator_progress SET txid = ? WHERE view = ?', [1234, 'target']],
          ['INSERT INTO target VALUES (?,?)', [1, 'Backup and Restore']],
          ['INSERT INTO target VALUES (?,?)', [3, 'Replication']],
          ['DELETE FROM target WHERE (a = ?)', [1]]
        ]
      )
    end
  end

  describe 'when integrated with sqlite' do
    let(:db) do
      SQLite3::Database.new(':memory:').tap do |db|
        db.execute('CREATE TABLE emanator_progress (view STRING PRIMARY KEY, txid INTEGER);')
        db.execute('CREATE TABLE target (a INTEGER, b STRING);')
      end
    end

    def process(view_sql)
      Emanator::Replica.new('target', view_sql).tap do |view|
        view.process(change_data).each do |sql, params|
          db.execute(sql, params)
        end
      end
    end

    def view_data(columns)
      db.execute("SELECT #{columns} FROM target").to_a
    end

    def progress
      db.execute('SELECT view, txid FROM emanator_progress').to_a
    end

    describe('with mixed change data') do
      let(:change_data) do
        data = File.new('spec/fixtures/cd-delete.json').read
        Emanator::ChangeData.parse_wal2json(data)
      end

      it 'properly updates the view' do
        process('SELECT a, b FROM table2_with_pk')
        expect(view_data('a, b')).to eq([[3, 'Replication']])
      end

      it 'updates the progress table' do
        process('SELECT a, b FROM table2_with_pk')
        expect(progress).to eq([['target', 1234]])
      end
    end
  end
end
