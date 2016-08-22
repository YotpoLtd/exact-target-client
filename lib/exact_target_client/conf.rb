
module ExactTargetClient
  class Conf

    DEFAULT_TOKEN_ENDPOINT = 'https://auth.exacttargetapis.com/v1/requestToken'
    DEFAULT_API_ENDPOINT = 'https://www.exacttargetapis.com'
    DEFAULT_WSDL = 'https://webservice.s%{instance}.exacttarget.com/etframework.wsdl'

    class << self

      attr_accessor :wsdl, :token_endpoint, :api_endpoint, :client_id, :client_secret

      def configure
        @token_endpoint = DEFAULT_TOKEN_ENDPOINT
        @api_endpoint = DEFAULT_API_ENDPOINT
        @wsdl = DEFAULT_WSDL
        yield self
        true
      end

    end

  end
end

