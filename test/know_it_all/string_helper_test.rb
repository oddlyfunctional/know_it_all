# Extracted from hanami-utils:
# https://github.com/hanami/utils/blob/3d7aa877182a545654b2ebd3a2a495546051ac91/test/string_test.rb

require 'test_helper'

describe KnowItAll::StringHelper do
  describe '.classify' do
    it 'returns a classified string' do
      KnowItAll::StringHelper.classify('hanami').must_equal('Hanami')
      KnowItAll::StringHelper.classify('hanami_router').must_equal('HanamiRouter')
      KnowItAll::StringHelper.classify('hanami-router').must_equal('Hanami::Router')
      KnowItAll::StringHelper.classify('hanami/router').must_equal('Hanami::Router')
      KnowItAll::StringHelper.classify('hanami::router').must_equal('Hanami::Router')
      KnowItAll::StringHelper.classify('hanami::router/base_object').must_equal('Hanami::Router::BaseObject')
    end

    it 'returns a classified string from symbol' do
      KnowItAll::StringHelper.classify(:hanami).must_equal('Hanami')
      KnowItAll::StringHelper.classify(:hanami_router).must_equal('HanamiRouter')
      KnowItAll::StringHelper.classify(:'hanami-router').must_equal('Hanami::Router')
      KnowItAll::StringHelper.classify(:'hanami/router').must_equal('Hanami::Router')
      KnowItAll::StringHelper.classify(:'hanami::router').must_equal('Hanami::Router')
    end

    it 'does not remove capital letter in string' do
      KnowItAll::StringHelper.classify('AwesomeProject').must_equal('AwesomeProject')
    end
  end
end
