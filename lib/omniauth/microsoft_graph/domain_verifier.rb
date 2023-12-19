# frozen_string_literal: true
require 'jwt' # for token signature validation
require 'omniauth' # to inherit from OmniAuth::Error
require 'oauth2' # to rescue OAuth2::Error

module OmniAuth
  module MicrosoftGraph
    # Verify user email domains to mitigate the nOAuth vulnerability
    # https://www.descope.com/blog/post/noauth
    # https://clerk.com/docs/authentication/social-connections/microsoft#stay-secure-against-the-n-o-auth-vulnerability
    OIDC_CONFIG_URL = 'https://login.microsoftonline.com/organizations/v2.0/.well-known/openid-configuration'

    class DomainVerificationError < OmniAuth::Error; end

    class DomainVerifier
      def self.verify!(auth_hash, access_token, options)
        new(auth_hash, access_token, options).verify!
      end

      def initialize(auth_hash, access_token, options)
        @email_domain = auth_hash['info']['email']&.split('@')&.last
        @upn_domain = auth_hash['extra']['raw_info']['userPrincipalName']&.split('@')&.last
        @access_token = access_token
        @id_token = access_token.params['id_token']
        @skip_verification = options[:skip_domain_verification]
      end

      def verify!
        # The userPrincipalName property is mutable, but must always contain a
        # verified domain:
        #
        #  "The general format is alias@domain, where domain must be present in
        #  the tenant's collection of verified domains."
        #  https://learn.microsoft.com/en-us/graph/api/resources/user?view=graph-rest-1.0
        #
        # This means while it's not suitable for consistently identifying a user
        # (the domain might change), it is suitable for verifying membership in
        # a given domain.
        return true if email_domain == upn_domain ||
          skip_verification == true ||
          (skip_verification.is_a?(Array) && skip_verification.include?(email_domain)) ||
          domain_verified_jwt_claim
        raise DomainVerificationError, verification_error_message
      end

      private

      attr_reader :access_token,
                  :email_domain,
                  :id_token,
                  :permitted_domains,
                  :skip_verification,
                  :upn_domain

      # https://learn.microsoft.com/en-us/entra/identity-platform/optional-claims-reference
      # Microsoft offers an optional claim `xms_edov` that will indicate whether the
      # user's email domain is part of the organization's verified domains. This has to be
      # explicitly configured in the app registration.
      #
      # To get to it, we need to decode the ID token with the key material from Microsoft's
      # OIDC configuration endpoint, and inspect it for the claim in question.
      def domain_verified_jwt_claim
        oidc_config = access_token.get(OIDC_CONFIG_URL).parsed
        algorithms = oidc_config['id_token_signing_alg_values_supported']
        keys = JWT::JWK::Set.new(access_token.get(oidc_config['jwks_uri']).parsed)
        decoded_token = JWT.decode(id_token, nil, true, algorithms: algorithms, jwks: keys)
        # https://github.com/MicrosoftDocs/azure-docs/issues/111425#issuecomment-1761043378
        # Comments seemed to indicate the value is not consistent
        ['1', 1, 'true', true].include?(decoded_token.first['xms_edov'])
      rescue JWT::VerificationError, ::OAuth2::Error
        false
      end

      def verification_error_message
        <<~MSG
          The email domain '#{email_domain}' is not a verified domain for this Azure AD account.
          You can either:
            * Update the user's email to match the principal domain '#{upn_domain}'
            * Skip verification on the '#{email_domain}' domain (not recommended)
            * Disable verification with `skip_domain_verification: true` (NOT RECOMMENDED!)
          Refer to the README for more details.
        MSG
      end
    end
  end
end
