#!/bin/env ruby
require 'amazon/aws/simple'

if $0 == __FILE__
  key_id = ""
  secret_key_id = ""
  cache_dir = "/tmp/amazon/"

  Amazon::AWS::Simple::Search.logger = Logger.new(STDERR)
  aws = Amazon::AWS::Simple::Search.new(key_id, secret_key_id, "hoge-22", "us", "utf-8", cache_dir)
  puts aws.retrieve_by_keyword('All', 'ruby').map(&:title)
end
