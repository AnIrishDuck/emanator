# frozen_string_literal: true

require 'json'

module Emanator
  class ChangeData
    attr_reader :txid, :changes

    def initialize(txid, changes)
      @txid = txid
      @changes = changes
    end

    def self.parse_wal2json(blob)
      data = JSON.parse(blob)

      ChangeData.new(data['txId'], data['change'].map do |change|
        Change.parse_wal2json_change(change)
      end)
    end
  end
end
