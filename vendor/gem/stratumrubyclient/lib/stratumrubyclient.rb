require 'json'
require 'net/http'
require 'net/https'
require 'openssl'
require 'rubygems'
require 'uri'

class StratumRubyClient
  # Data gets passed in with apicall and json
  # payload to public function send_api. This 
  # then gets timestamped and signed, adding the 
  # signature to the data, and fills in user,
  # secret, and endpoint fields from the init
  # of the class. URL built from endpoint, POST
  # request sent and evaluated for errors. JSON
  # returned in all cases. Send 0 or false in case 
  # of no payload.
  def initialize(api_user, api_secret, api_endpoint)
    @API_USER = api_user
    @API_SECRET = api_secret
    @API_ENDPOINT = api_endpoint
  end

  def send_api(apicall, payload)
    data = Hash.new
    data[:api_ts] = Time.now.to_i
    data[:api_user] = @API_USER
    if payload != 0 or false
      data[:payload] = JSON.generate(payload)
    end
    signed_data = sign_data(data)
    data[:api_sig] = signed_data
    url = "#{@API_ENDPOINT}/#{apicall}"
    post_data = post(url, data)
    if post_data == false
      api_reply = {:status => "failed",
                   :message => "Error in parsing result!"}
      return JSON.to_json(api_reply)
    else
      result = JSON.parse(post_data)
      puts JSON.pretty_generate(result)
      if result[:status] != "ok"
        api_reply = {:status => result[:status],
                     :message => result[:message]}
        return JSON.to_json(api_reply)
      else
        # Success
        return JSON.to_json(result)
      end
    end
  end

  def post(url, data)
    begin
      uri = URI.parse(url)
      req = Net::HTTP::Post.new(uri.request_uri)
      puts "Sending request to API link #{url} with post data:"
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
    api_secret = @API_SECRET
    return_val = OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest::SHA256.new,
      api_secret,
      str_post)
    return return_val
  end

  public :send_api
  protected :post, :sign_data

end
