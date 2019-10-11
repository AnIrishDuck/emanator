# frozen_string_literal: true

require 'sql-parser'
require 'emanator/change_data'
require 'emanator/change'

module Emanator
  class Replica
    def initialize(target, view)
      @target = target
      @view = view
      parser = SQLParser::Parser.new
      @ast = parser.scan_str(view)
    end

    def operation(change)
      case @ast
      when SQLParser::Statement::DirectSelect
        raise ArgumentError unless @ast.order_by.nil?
        select(@ast.query_expression, change)
      else
        raise ArgumentError
      end
    end

    def select(query, change)
      case query
      when SQLParser::Statement::Select
        expr = query.table_expression
        blank = [expr.where_clause, expr.group_by_clause, expr.having_clause]
        raise ArgumentError unless blank.all?(&:nil?)
        tables = expr.from_clause.tables
        raise ArugmentError unless tables.size == 1
        return nil unless change.table == tables.first.name
        run_row(query.list.columns, change)
      end
    end

    def run_row(columns, change)
      case change.kind
      when Change::INSERT
        wildcards = columns.map { '?' }.join(',')
        values = columns.map { |c| change.columns[c.name] }
        ["INSERT INTO #{@target} VALUES (#{wildcards})", values]
      when Change::DELETE
        names = columns.map(&:name)
        active = change.columns.keys.select { |k| names.include? k }
        wildcards = active.map { |name| "#{name} = ?" }.join(' AND ')
        values = active.map { |name| change.columns[name] }
        ["DELETE FROM #{@target} WHERE (#{wildcards})", values]
      end
    end

    def process(change_data)
      [
        ["UPDATE emanator_progress SET txid = #{change_data.txid}", []],
        *change_data.changes.map { |change| operation(change) }
      ].compact
    end
  end
end
