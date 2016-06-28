$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'know_it_all'

require 'minitest/autorun'
require "minitest/reporters"
require 'active_support/core_ext/string/inflections'
require 'pry'

Minitest::Reporters.use!

module MiniTest::Assertions
  def refute_raises(*args)
    begin
      if block_given?
        yield
      else
        args[1].call
      end
    rescue => e
      flunk "Unexpected exception raised: #{e}"
    end
  end

  infect_an_assertion :refute_raises, :wont_raise
end
