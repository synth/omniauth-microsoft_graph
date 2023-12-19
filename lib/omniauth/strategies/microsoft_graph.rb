require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class MicrosoftGraph < OmniAuth::Strategies::OAuth2
      BASE_SCOPE_URL = 'https://graph.microsoft.com/'
      BASE_SCOPES = %w[offline_access openid email profile].freeze
      DEFAULT_SCOPE = 'offline_access openid email profile User.Read'.freeze

      option :name, :microsoft_graph

      option :client_options, {
        site:          'https://login.microsoftonline.com/',
        token_url:     'common/oauth2/v2.0/token',
        authorize_url: 'common/oauth2/v2.0/authorize'
      }

      option :authorize_options, %i[state callback_url access_type display score auth_type scope prompt login_hint domain_hint response_mode]

      option :token_params, {
      }

      option :scope, DEFAULT_SCOPE
      option :authorized_client_ids, []
      option :skip_domain_verification, false

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
          'params' => access_token.params,
          'aud' => options.client_id
        }
      end

      def auth_hash
        super.tap do |ah|
          verify_email(ah, access_token)
        end
      end

      def authorize_params
        super.tap do |params|
          options[:authorize_options].each do |k|
            params[k] = request.params[k.to_s] unless [nil, ''].include?(request.params[k.to_s])
          end

          params[:scope] = get_scope(params)
          params[:access_type] = 'offline' if params[:access_type].nil?

          session['omniauth.state'] = params[:state] if params[:state]
        end
      end

      def raw_info
        @raw_info ||= access_token.get('https://graph.microsoft.com/v1.0/me').parsed
      end

      def callback_url
        options[:callback_url] || full_host + script_name + callback_path
      end

      def custom_build_access_token
        access_token = get_access_token(request)
        access_token
      end

      alias build_access_token custom_build_access_token

      private

      def get_access_token(request)
        verifier = request.params['code']
        redirect_uri = request.params['redirect_uri'] || request.params['callback_url']
        if verifier && request.xhr?
          client_get_token(verifier, redirect_uri || '/auth/microsoft_graph/callback')
        elsif verifier
          client_get_token(verifier, redirect_uri || callback_url)
        elsif verify_token(request.params['access_token'])
          ::OAuth2::AccessToken.from_hash(client, request.params.dup)
        elsif request.content_type =~ /json/i
          begin
            body = JSON.parse(request.body.read)
            request.body.rewind # rewind request body for downstream middlewares
            verifier = body && body['code']
            client_get_token(verifier, '/auth/microsoft_graph/callback') if verifier
          rescue JSON::ParserError => e
            warn "[omniauth microsoft_graph] JSON parse error=#{e}"
          end
        end
      end

      def client_get_token(verifier, redirect_uri)
        client.auth_code.get_token(verifier, get_token_options(redirect_uri), get_token_params)
      end

      def get_token_params
        deep_symbolize(options.auth_token_params || {})
      end

      def get_token_options(redirect_uri = '')
        { redirect_uri: redirect_uri }.merge(token_params.to_hash(symbolize_keys: true))
      end

      def get_scope(params)
        raw_scope = params[:scope] || DEFAULT_SCOPE
        scope_list = raw_scope.split(' ').map { |item| item.split(',') }.flatten
        scope_list.map! { |s| s =~ %r{^https?://} || BASE_SCOPES.include?(s) ? s : "#{BASE_SCOPE_URL}#{s}" }
        scope_list.join(' ')
      end

      def verify_token(access_token)
        return false unless access_token
        # access_token.get('https://graph.microsoft.com/v1.0/me').parsed
        raw_response = client.request(:get, 'https://graph.microsoft.com/v1.0/me',
                                      params: { access_token: access_token }).parsed
        (raw_response['aud'] == options.client_id) || options.authorized_client_ids.include?(raw_response['aud'])
      end

      def verify_email(auth_hash, access_token)
        OmniAuth::MicrosoftGraph::DomainVerifier.verify!(auth_hash, access_token, options)
      end
    end
  end
end
