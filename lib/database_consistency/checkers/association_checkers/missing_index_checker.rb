# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks if association's foreign key has index in the database
    class MissingIndexChecker < AssociationChecker
      # Message templates
      MISSING_INDEX = 'associated model should have proper index in the database'

      private

      # We skip check when:
      #  - association isn't a `HasOne` or `HasMany`
      #  - association has `through` option
      #  - associated class doesn't exist
      def preconditions
        %i[
          has_one
          has_many
        ].include?(association.macro) && association.through_reflection.nil? && association.klass
      rescue NameError
        false
      end

      # Table of possible statuses
      # | index        | status |
      # | ------------ | ------ |
      # | persisted    | ok     |
      # | missing      | fail   |
      def check
        if index
          report_template(:ok)
        else
          report_template(:fail, MISSING_INDEX)
        end
      end

      def index
        @index ||= association.klass.connection.indexes(association.klass.table_name).find do |index|
          index_keys(index) == association_keys
        end
      end

      def association_keys
        @association_keys ||= [association.foreign_key, association.type].compact.map(&:to_s).sort
      end

      def index_keys(index)
        return unless index.columns.is_a?(Array)

        index.columns[0...association_keys.size].sort
      end
    end
  end
end
