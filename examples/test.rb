#!/bin/env ruby
# encoding: utf-8
# Author: kimoto
require 'amazon/aws/simple'

if $0 == __FILE__
  key_id = ""
  secret_key_id = ""
  cache_dir = "/tmp/amazon/"

  Amazon::AWS::Simple::Search.logger = Logger.new(STDERR)
  aws = Amazon::AWS::Simple::Search.new(key_id, secret_key_id, "kimoto-22", "us", "utf-8", cache_dir)
  puts aws.retrieve_by_keyword('ruby').map(&:title)
end
