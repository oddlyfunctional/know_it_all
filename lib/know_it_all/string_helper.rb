# Extracted from hanami-utils:
# https://github.com/hanami/utils/blob/3d7aa877182a545654b2ebd3a2a495546051ac91/lib/hanami/utils/string.rb

module KnowItAll
  class StringHelper
    EMPTY_STRING        = ''.freeze
    UNDERSCORE_DIVISION_TARGET  = '\1_\2'.freeze
    NAMESPACE_SEPARATOR = '::'.freeze
    CLASSIFY_SEPARATOR  = '_'.freeze
    UNDERSCORE_SEPARATOR = '/'.freeze
    DASHERIZE_SEPARATOR = '-'.freeze

    CLASSIFY_WORD_SEPARATOR = /#{CLASSIFY_SEPARATOR}|#{NAMESPACE_SEPARATOR}|#{UNDERSCORE_SEPARATOR}|#{DASHERIZE_SEPARATOR}/

    def self.classify(string)
      string = string.to_s

      words = underscore(string).split(CLASSIFY_WORD_SEPARATOR).map!(&:capitalize)
      delimiters = string.scan(CLASSIFY_WORD_SEPARATOR)

      delimiters.map! do |delimiter|
        delimiter == CLASSIFY_SEPARATOR ? EMPTY_STRING : NAMESPACE_SEPARATOR
      end

      words.zip(delimiters).join
    end

    def self.underscore(string)
      new_string = string.gsub(NAMESPACE_SEPARATOR, UNDERSCORE_SEPARATOR)
      new_string.gsub!(/([A-Z\d]+)([A-Z][a-z])/, UNDERSCORE_DIVISION_TARGET)
      new_string.gsub!(/([a-z\d])([A-Z])/, UNDERSCORE_DIVISION_TARGET)
      new_string.gsub!(/[[:space:]]|\-/, UNDERSCORE_DIVISION_TARGET)
      new_string.downcase
    end
  end
end
