require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class MicrosoftGraph < OmniAuth::Strategies::OAuth2
      option :name, :microsoft_graph

      option :client_options, {
        site:          'https://login.microsoftonline.com/common/oauth2/authorize',
        token_url:     'https://login.microsoftonline.com/common/oauth2/token',
        authorize_url: 'https://login.microsoftonline.com/common/oauth2/authorize'
      }

      option :authorize_params, {
        resource: 'https://graph.microsoft.com/'
      }

      option :token_params, {
        resource: 'https://graph.microsoft.com/'        
      }

      uid { raw_info["id"] }

      info do
        {
          'email' => raw_info["mail"],
          'first_name' => raw_info["givenName"],
          'last_name' => raw_info["surname"],
          'name' => [raw_info["givenName"], raw_info["surname"]].join(' '),
          'nickname' => raw_info["displayName"],
        }
      end

      extra do
        {
          'raw_info' => raw_info,
          'params' => access_token.params
        }
      end

      def callback_url
        full_host + script_name + callback_path
      end

      def raw_info
        @raw_info ||= access_token.get(authorize_params.resource + 'v1.0/me').parsed
      end
    end
  end
end
