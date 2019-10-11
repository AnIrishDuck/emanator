# frozen_string_literal: true

module Emanator
  class Change
    INSERT = 1
    DELETE = 2

    attr_reader :kind, :schema, :table, :columns

    def initialize(kind, schema, table, columns)
      @kind = kind
      @schema = schema
      @table = table
      @columns = columns
    end

    def self.parse_wal2json_change(change)
      kind = parse_kind(change['kind'])
      columns = (
        case kind
        when INSERT
          change['columnnames'].zip(change['columnvalues']).to_h
        when DELETE
          old = change['oldkeys']
          old['keynames'].zip(old['keyvalues']).to_h
        end
      )

      Change.new(kind, change['schema'], change['table'], columns)
    end

    def self.parse_kind(kind)
      kinds = {
        'insert' => INSERT,
        'delete' => DELETE
      }
      value = kinds[kind]
      raise ArgumentError, "Invalid change kind: #{value}" if value.nil?

      value
    end
  end
end
