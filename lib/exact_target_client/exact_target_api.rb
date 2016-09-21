require 'exact_target_client/exact_target_rest_client'
require 'exact_target_client/exact_target_soap_client'

module ExactTargetClient
  class ExactTargetAPI

    attr_accessor :oauth_token, :refresh_token
    class TimeOut < Exception;
    end
    class TokenExpired < Exception;
    end
    class ClientException < Exception;
    end

    def initialize
      yield self if block_given?
      raise ArgumentError, 'block not given' unless block_given?
      init_clients
    end

    def refresh_oauth_token
      results = @rest_client.get_oauth_token(Conf.client_id, Conf.client_secret, refresh_token)
      if results
        @oauth_token = results['accessToken']
        @refresh_token = results['refreshToken']
        refresh_clients(results['accessToken'])
        results
      end
    end

    def get_emails(ids = nil)
      properties = %w(ID Name HTMLBody)
      if ids.present?
        filter = {property: 'ID', value: ids}
      end
      response = soap_client.retrieve('Email', properties, filter)
      check_response(response)
    end

    def create_email(email_name, subject, html_template)
      response = soap_client.create('Email',
                                    {'Name' => email_name,
                                     'Subject' => subject,
                                     'HTMLBody' => html_template}
      )
      check_response(response)
    end

    def update_email(email_id, name, html_template, subject = nil)
      properties = {'ID' => email_id, 'Name' => name, 'HTMLBody' => html_template}
      if subject.present?
        properties['Subject'] = subject
      end
      response = soap_client.update('Email', properties)
      check_response(response)
    end

    def delete_email(email_id)
      response = soap_client.delete('Email', {'ID' => email_id})
      check_response(response)
    end

    def create_content_area(name, content)
      response = soap_client.create('ContentArea',
                                    {'Name' => name,
                                     'Content' => content}
      )
      check_response(response)
    end

    def update_content_area(content_area_id, name, content)
      response = soap_client.update('ContentArea', {'ID' => content_area_id, 'Name' => name, 'Content' => content})
      check_response(response)
    end

    def delete_content_area(content_area_id)
      response = soap_client.delete('ContentArea', {'ID' => content_area_id})
      check_response(response)
    end

    def create_data_extension(properties)
      response = soap_client.create('DataExtension', properties)
      check_response(response)
    end

    def upsert_data_extension_row(data_extension_customer_key, primary_key_name, primary_key_value, object_hash)
      rest_client.upsert_data_extension_row(data_extension_customer_key, primary_key_name, primary_key_value, object_hash)
    end

    def increment_data_extension_row(data_extension_customer_key, primary_key_name, primary_key_value, column, step = 1)
      rest_client.increment_data_extension_row(data_extension_customer_key, primary_key_name, primary_key_value, column, step)
    end

    def get_subscribers_by_email(email, properties)
      response = soap_client.retrieve('Subscriber', properties, {property: 'EmailAddress', value: email})
      check_response(response)
    end

    private
    attr_accessor :soap_client, :rest_client

    def init_clients
      @soap_client = ExactTargetClient::ExactTargetSoapClient.new do |c|
        c.oauth_token = oauth_token
        c.wsdl = Conf.wsdl % {:instance => oauth_token[0]} # WSDL instance is determined by first char of token
      end
      @rest_client = ExactTargetClient::ExactTargetRestClient.new do |c|
        c.oauth_token = oauth_token
      end
    end

    def refresh_clients(token)
      @soap_client.set_oauth_token(token)
      @rest_client.set_oauth_token(token)
    end

    def check_response(response)
      if response.success?
        response.results
      else
        raise ClientException.new(response.message)
      end
    end

  end

end

