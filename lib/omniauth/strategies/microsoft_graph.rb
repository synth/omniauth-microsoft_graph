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

      option :authorize_options, %i[display score auth_type scope prompt login_hint domain_hint response_mode]

      uid { raw_info["id"] }

      info do
        {
          email:      raw_info["mail"] || raw_info["userPrincipalName"],
          first_name: raw_info["givenName"],
          last_name:  raw_info["surname"],
          name:       full_name,
          nickname:   raw_info["userPrincipalName"],
        }
      end

      extra do
        {
          'raw_info' => raw_info,
          'params' => access_token.params
        }
      end
      
      def callback_url
        options[:redirect_uri] || (full_host + script_name + callback_path)
      end

      def raw_info
        @raw_info ||= access_token.get('https://graph.microsoft.com/v1.0/me').parsed
      end

      def authorize_params
        super.tap do |params|
          %w[display score auth_type].each do |v|
            if request.params[v]
              params[v.to_sym] = request.params[v]
            end
          end
        end
      end

      def full_name
        raw_info["displayName"].presence || raw_info.values_at("givenName", "surname").compact.join(' ')
      end
    end
  end
end
