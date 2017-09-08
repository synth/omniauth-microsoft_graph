require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class MicrosoftGraph < OmniAuth::Strategies::OAuth2
      option :name, :microsoft_graph

      option :client_options, {
        site:          'https://login.microsoftonline.com',
        token_url:     '/common/oauth2/v2.0/token',
        authorize_url: '/common/oauth2/v2.0/authorize'
      }

      option :authorize_options, [:scope]

      uid { raw_info["id"] }

      info do
        {
          email:      raw_info["mail"],
          first_name: raw_info["givenName"],
          last_name:  raw_info["surname"],
          name:       full_name,
          nickname:   raw_info["displayName"],
        }
      end

      extra do
        {
          'raw_info' => raw_info,
          'params' => access_token.params
        }
      end

      def raw_info
        @raw_info ||= access_token.get('/v2.0/me').parsed
      end

      def full_name
        [raw_info["givenName"], raw_info["surname"]].compact.join(' ')
      end
    end
  end
end
