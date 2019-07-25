require 'json'
require 'net/http'
require 'net/https'
require 'openssl'
require 'rubygems'
require 'uri'

class BtcPaymentAPI

  # Data gets passed in as a json
  # This then gets timestamped and signed
  # adding the signature to the data and
  # filling in user/secret/endpoint fields
  # from the initialization of the function.
  def initialize(user, secret, api)
    @API_USER = user
    @API_SECRET = secret
    @API_ENDPOINT = api
  end

  def send_api(apicall, payload)
    data = Hash.new
    data[:api_ts] = Time.now.to_i
    data[:api_user] = @API_USER
    if payload != 0
      data[:payload] = JSON.generate(payload)
    end
    signed_data = sign_data(data)
    data[:api_sig] = signed_data
    url = "#{@API_ENDPOINT}/#{apicall}"
    post_data = post(url, data)
    if post_data == false
      puts "Error in parsing result!"
      return false
    else
      result = JSON.parse(post_data)
      if result[:status] != "ok"
        api_reply = {:status => result[:status],
                     :message => result[:message]}
        return JSON.to_json(api_reply)
      else
        return JSON.to_json(result)
      end
    end
  end

  def post(url, data)
    begin
      uri = URI.parse(url)
      req = Net::HTTP::Post.new(uri.request_uri)
      puts "Sending request to API endpoint " + url + " with post data:"
      puts data
      req.set_form_data(data)
      returnval = Net::HTTP::start(
        uri.host,
        uri.port, 
        :use_ssl => true,
        :read_timeout => 10) { |http| http.request(req)}
      return returnval.body
    rescue StandardError => e
      puts "Hits error, returning false..."
      puts "Error: "
      puts e
      false
    end
  end

  def sign_data(post_data)
    post_data.keys.sort
    str_post = ''
    post_data.each do |key, value|
      str_post << "#{key}=#{value}&"
    end
    str_post = str_post[0...-1]
    puts "str_post:"
    puts str_post
    api_secret = @API_SECRET
    return_val = OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest::SHA256.new,
      api_secret,
      str_post)
    return return_val
  end

end
