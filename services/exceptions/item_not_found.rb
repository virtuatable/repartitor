# frozen_string_literal: true

module Services
  module Exceptions
    # Exception thrown when an element to which a message should be sent is not found in the sockets list.
    # @author Vincent Courtois <courtois.vincent@outlook.com>
    class ItemNotFound < StandardError
      # @!attribute [r] key
      #   @return [String] the key to put in the error message.
      attr_reader :key

      # Constructor of the exception.
      # @param key [String] the name of the key throwing this error.
      def initialize(key)
        @key = key
      end

      # Returns a formatted error message to be used by the :custom_error method of the controller.
      # @return [String] the error message for this exception.
      def to_s
        "messages.#{key}.unknown"
      end
    end
  end
end
