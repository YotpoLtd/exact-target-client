module ExactTargetClient
  class SoapResponse
    attr_reader :code, :message, :results, :request_id, :body, :result_key

    def initialize(response, result_key, client)
      @results = []
      @result_key = result_key
      @client = client
      parse_response response
    rescue => e
      raise ExactTargetClient::ExactTargetAPI::ClientException.new("SOAP Client Error: #{e.message}")
    end

    def success?
      @success ||= false
    end

    private

    def get_more
      parse_results @client.soap_client.call(:retrieve, :message => {'ContinueRequest' => request_id})
    end

    def parse_response(response)
      @code = response.http.code
      parse_body response
    end

    def parse_body(response)
      @request_id = response.body[result_key][:request_id]
      @success = response.body[result_key][:overall_status] == 'OK'
      @results = result_key == :retrieve_response_msg ? parse_results(response) : response.body[result_key][:results]
      @message = @results.present? ? response.body[result_key][:results][:status_message] : response.body[result_key][:overall_status]
    rescue
      @message = response.http.body
      @body = response.http.body unless @body
    end

    def parse_results(response)
      res = response.body[result_key][:results] || []
      if response.body[result_key][:overall_status] == 'MoreDataAvailable'
        res += get_more
      end
      Array.wrap(res)
    rescue
      []
    end
  end

  class ExactTargetSoapClient
    attr_accessor :wsdl, :oauth_token

    RESPONSE_RESULT_KEYS = {
        create: :create_response,
        update: :update_response,
        delete: :delete_response,
        retrieve: :retrieve_response_msg
    }

    def initialize
      yield self if block_given?
    end

    def header
      raise ExactTargetClient::ExactTargetAPI::ClientException.new('OAuth token must be provided to SOAP client!') unless oauth_token
      {
          'fueloauth' => oauth_token,
          '@xmlns' => 'http://exacttarget.com'
      }
    end

    def wsdl
      @wsdl ||= 'https://webservice.exacttarget.com/etframework.wsdl'
    end

    def soap_client
      @soap_client = Savon.client(
          soap_header: header,
          wsdl: wsdl,
          log: false,
          open_timeout: 120,
          read_timeout: 120
      )
    end

    def set_oauth_token(token)
      @oauth_token = token
      soap_client.globals[:soap_header] = header
    end

    def retrieve(object_type, properties, filter = nil)
      raise ExactTargetClient::ExactTargetAPI::ClientException.new('Object properties must be specified') unless properties.present?
      payload = {'ObjectType' => object_type, 'Properties' => properties}
      if filter.present?
        values = Array.wrap(filter[:value])
        payload['Filter'] = {
            '@xsi:type' => 'tns:SimpleFilterPart',
            'Property' => filter[:property],
            'SimpleOperator' => values.one? ? 'equals' : 'IN',
            'Value' => values
        }
      end
      message = {'RetrieveRequest' => payload}
      soap_request :retrieve, message
    end

    def create(object_type, properties)
      soap_action :create, object_type, properties
    end

    def update(object_type, properties)
      soap_action :update, object_type, properties
    end

    def delete(object_type, properties)
      soap_action :delete, object_type, properties
    end

    private

    def soap_action(action, object_type, properties)
      properties['@xsi:type'] = "tns:#{object_type}"
      message = {
          'Objects' => properties
      }
      soap_request action, message
    end

    def soap_request(action, message)
      responseObject = SoapResponse
      begin
        tries ||= 3
        response = soap_client.call(action, :message => message)
          # TODO - handle other error types
      rescue Savon::SOAPFault => error
        message = error.to_hash[:fault][:faultstring]
        if message == 'Token Expired'
          raise ExactTargetClient::ExactTargetAPI::TokenExpired
        elsif message == 'Login Failed'
          retry unless (tries -= 1).zero?
        else
          raise ExactTargetClient::ExactTargetAPI::ClientException.new("SOAP Client Error: #{message}")
        end
      end
      responseObject.new response, RESPONSE_RESULT_KEYS[action], self
    end
  end
end
