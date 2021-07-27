# frozen_string_literal: true

module Matchd
  module Helpers
    module_function

    # Creates a new Hash with the key-value pairs of options for the keys given
    # and only if options has that keys.
    # Also, new keys will get symbolized.
    def extract_options(keys, options)
      keys.each_with_object({}) do |key, o|
        o[key.to_sym] = options[key] if options.key?(key)
      end
    end
  end
end
