module ExactTargetClient
  class ExactTargetRestClient
    attr_accessor :oauth_token

    def initialize
      yield self if block_given?
    end

    def get_oauth_token(client_id, client_secret, refresh_token = nil)
      request_url = Conf.token_endpoint
      params = {
          clientId: client_id,
          clientSecret: client_secret,
          accessType: 'offline'
      }
      if refresh_token.present?
        params[:refreshToken] = refresh_token
      end
      request(:post, request_url, params, false)
    end

    def set_oauth_token(token)
      @oauth_token = token
    end

    def upsert_data_extension_row(data_extension_customer_key, primary_key_name, primary_key_value, object_hash)
      request_url = "#{Conf.api_endpoint}/hub/v1/dataevents/key:#{data_extension_customer_key}/rows/#{primary_key_name}:#{primary_key_value}"
      request('PUT', request_url, {values: object_hash})
    end

    def increment_data_extension_row(data_extension_customer_key, primary_key_name, primary_key_value, column, step = 1)
      request_url = "#{Conf.api_endpoint}/hub/v1/dataevents/key:#{data_extension_customer_key}/rows/#{primary_key_name}:#{primary_key_value}/column/#{column}/increment?step=#{step}"
      request('PUT', request_url)
    end


    private
    def request(type, url, params = nil, add_token = true)
      body = params.to_json if params
      headers = { 'Content-Type' => 'application/json' }
      headers['Authorization'] = "Bearer #{@oauth_token}" if add_token
      request = Typhoeus::Request.new(
          url,
          method: type,
          body: body,
          headers: headers
      )
      request.on_complete do |response|
        if response.success?
          return Oj.load(response.body)
        elsif response.timed_out?
          raise ExactTargetClient::ExactTargetAPI::TimeOut
        else
          response = JSON.parse(response.response_body)
          if (response['message'] == 'Unauthorized' || response['message'] == 'Not Authorized') && url == Conf.token_endpoint
            raise ExactTargetClient::ExactTargetAPI::TokenExpired
          else
            raise ExactTargetClient::ExactTargetAPI::ClientException.new("REST API Error #{response['errorcode'].to_s}: #{response['message']}")
          end
        end
      end
      request.run
    end
  end
end
