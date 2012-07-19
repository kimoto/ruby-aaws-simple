require_relative "simple_version"
require 'amazon/aws/search'
require 'amazon/aws'
require 'logger'
require 'cgi'

module Amazon::AWS::Simple
  class APIWrapper
    @@logger = Logger.new(nil)
    def self.logger=(logger)
      @@logger = logger
    end

    def initialize(key_id, secret_key_id, tag, locale, encoding, cache_dir)
      @key_id = key_id
      @secret_key_id = secret_key_id
      @tag = tag
      @locale = locale
      @encoding = encoding
      @cache_dir = cache_dir
    end

    def request(query)
      req = Amazon::AWS::Search::Request.new(@key_id, @tag)
      req.config["cache_dir"] = @cache_dir
      req.config["secret_key_id"] = @secret_key_id
      req.locale = @locale
      req.encoding = @encoding
      req.cache = Amazon::AWS::Cache.new(@cache_dir)

      rg = Amazon::AWS::ResponseGroup.new(:Large)
      query.response_group = rg

      req.search(query)
    end

    def item_lookup(type, params={})
      request(Amazon::AWS::ItemLookup.new(type, params)).item_lookup_response.items.item
    end

    def item_search(type, params={})
      request(Amazon::AWS::ItemSearch.new(type, params)).item_search_response.items.item
    end
  end

  class Search < APIWrapper
    attr_reader :errors
    def initialize(*args)
      super(*args)
      @errors = []
    end

    ## どんだけたくさんのASINでも全部自動でAPIの最大数にあわせて分割してリクエストしてくれる版
    ## エラーは全部無視します
    ITEM_LOOKUP_MAX_ITEMS = 10
    def search_by_asin(*asins)
      asins.flatten.each_slice(ITEM_LOOKUP_MAX_ITEMS).map{ |asin_codes|
        @@logger.info "try to fetch: #{asin_codes.inspect}"
        _search_by_asin(asin_codes)
      }.flatten
    end

    def search_by_keyword(keyword)
      _search_by_keyword(keyword)
    end

    ## 更につかいやすくしたやつ
    def retrieve_by_asin(*asins)
      search_by_asin(*asins).map{ |item|
        Data.new.load_from_aws_item(item)
      }
    end

    def retrieve_by_keyword(keyword)
      search_by_keyword(keyword).map{ |item|
        Data.new.load_from_aws_item(item)
      }
    end

    private
    # 10以上は検索できないAPI, 仕様を満たしてる
    def _search_by_asin(*asins)
      params = asins.flatten
      if params.size > ITEM_LOOKUP_MAX_ITEMS
        raise ArgumentError.new("asin_codes > #{ITEM_LOOKUP_MAX_ITEMS}, #{params.inspect}")
      end
      begin
        results = item_lookup("ASIN", {"ItemId" => params.join(",")})
      rescue Amazon::AmazonError => ex
        @@logger.error "Multiple fetch mode error! change to single fetch mode: #{ex}"
        @@logger.error ex.backtrace.join($/)
        results = []
        params.each{ |asin|
          begin
            @@logger.info "try to fetch: #{asin.inspect}"
            results << item_lookup("ASIN", {"ItemId" => asin})
          rescue Amazon::AmazonError => ex
            @@logger.error ex
            @@logger.error ex.backtrace.join($/)
            @errors << asin
          end
        }
        results
      end
    end

    def _search_by_keyword(keyword)
      item_search("All", {'Keywords' => keyword})
    end
  end

  class Search::Data
    attr_accessor :asin
    attr_accessor :title
    attr_accessor :product_group
    attr_accessor :publisher
    attr_accessor :published_at
    attr_accessor :image_url
    attr_accessor :image_code
    attr_accessor :alt_image_urls
    attr_accessor :alt_image_codes
    attr_accessor :price
    attr_accessor :discount_price
    attr_accessor :discount_percentage
    attr_accessor :detail

    def load_from_aws_item(item)
      # 値段関係
      price = item.item_attributes.list_price.amount.first rescue nil
      discount_price = item.offers.offer.offer_listing.price.amount.first rescue nil
      discount_percentage = item.offers.offer.offer_listing.percentage_saved.first rescue nil

      # 画像関係
      image_url = item.large_image.url rescue nil
      image_code = extract_image_code_from_image_url(image_url)
      alt_image_urls = item.image_sets.image_set.map{ |set| set.swatch_image.url }.flatten rescue []
      alt_image_codes = alt_image_urls.map{|url| extract_image_code_from_image_url(url) }

      # 日付関係
      publication_date = item.item_attributes.publication_date.first rescue nil
      release_date = item.item_attributes.release_date.first rescue nil

      published_at = publication_date
      if published_at.nil?
        published_at = release_date
      end

      @asin = item.asin.first.to_s
      @title = CGI.unescape_html(item.item_attributes.title.join(","))
      @product_group = item.item_attributes.product_group.first.to_s
      @publisher = item.item_attributes.publisher.join(",") rescue nil
      @published_at = published_at
      @image_url = image_url.first.to_s
      @image_code = image_code
      @alt_image_urls = alt_image_urls
      @alt_image_codes = alt_image_codes
      @price = price
      @discount_price = discount_price
      @discount_percentage = discount_percentage
      @detail = item.detail_page_url
      self
    end

    def to_s
      "#<AWS::Simple::Data: #{@title}(#{@asin}) - #{@publisher} $#{@price}>"
    end

    private
    def extract_basename_from_image_url(image_url)
      if /([^\/]+)\.jpg$/.match(image_url)
        Regexp.last_match(0)
      end
    end

    def extract_image_code_from_image_url(image_url)
      basename = extract_basename_from_image_url(image_url)
      # 先頭の.までを抽出
      if /(^[^\.]+)\./.match(basename)
        Regexp.last_match(1)
      end
    end
  end
end
