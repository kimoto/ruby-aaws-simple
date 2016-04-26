# ruby-aaws-simple
Simple wrapper for ruby-aaws

## Installation
    gem install ruby-aaws-simple

## Usage
    require 'amazon/aws/simple'
    aws = Amazon::AWS::Simple::Search.new(key_id, secret_key_id, affiliate_tag, country_code, encoding, cacahe_dir)
    items = aws.retrieve_by_keyword('Books', 'Ruby')
    items.first.title
      # => The Ruby Programming Language

