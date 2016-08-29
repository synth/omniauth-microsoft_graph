require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class MicrosoftGraph < OmniAuth::Strategies::OAuth2
      option :name, :microsoft_graph

      option :client_options, {
        site:          'https://login.microsoftonline.com/',
        token_url:     'common/oauth2/v2.0/token',
        authorize_url: 'common/oauth2/v2.0/authorize'
      }

      option :authorize_params, {
      }

      option :token_params, {
      }

      option :scope, "https://graph.microsoft.com/profile https://graph.microsoft.com/email https://graph.microsoft.com/User.Read https://graph.microsoft.com/User.ReadBasic.All"

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

      def raw_info
        @raw_info ||= access_token.get('https://graph.microsoft.com/v1.0/me').parsed
      end

      def callback_url
        options[:callback_url] || full_host + script_name + callback_path
      end      
    end
  end
end
