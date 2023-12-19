# frozen_string_literal: true

require 'spec_helper'
require 'omniauth/microsoft_graph/domain_verifier'

RSpec.describe OmniAuth::MicrosoftGraph::DomainVerifier do
  subject(:verifier) { described_class.new(auth_hash, access_token, options) }

  let(:auth_hash) do
    {
      'info' => { 'email' => email },
      'extra' => { 'raw_info' => { 'userPrincipalName' => upn } }
    }
  end
  let(:email) { 'foo@example.com' }
  let(:upn) { 'bar@hackerman.biz' }
  let(:options) { { skip_domain_verification: false } }
  let(:access_token) { double('OAuth2::AccessToken', params: { 'id_token' => id_token }) }
  let(:id_token) { nil }

  describe '#verify!' do
    subject(:result) { verifier.verify! }

    context 'when email domain and userPrincipalName domain match' do
      let(:email) { 'foo@example.com' }
      let(:upn) { 'bar@example.com' }

      it { is_expected.to be_truthy }
    end

    context 'when domain validation is disabled' do
      let(:options) { super().merge(skip_domain_verification: true) }

      it { is_expected.to be_truthy }
    end

    context 'when the email domain is explicitly permitted' do
      let(:options) { super().merge(skip_domain_verification: ['example.com']) }

      it { is_expected.to be_truthy }
    end

    context 'when the ID token indicates domain verification' do
      # Sign a fake ID token with our own local key
      let(:mock_key) do
        optional_parameters = { kid: 'mock-kid', use: 'sig', alg: 'RS256' }
        JWT::JWK.new(OpenSSL::PKey::RSA.new(2048), optional_parameters)
      end
      let(:id_token) do
        payload = { email: email, xms_edov: true }
        JWT.encode(payload, mock_key.signing_key, mock_key[:alg], kid: mock_key[:kid])
      end

      # Mock the API responses to return the local key
      before do
        allow(access_token).to receive(:get)
          .with(OmniAuth::MicrosoftGraph::OIDC_CONFIG_URL)
          .and_return(
            double('OAuth2::Response', parsed: {
              'id_token_signing_alg_values_supported' => ['RS256'],
              'jwks_uri' => 'https://example.com/jwks-keys'
            })
          )
        allow(access_token).to receive(:get)
          .with('https://example.com/jwks-keys')
          .and_return(
            double('OAuth2::Response', parsed: JWT::JWK::Set.new(mock_key).export)
          )
      end

      it { is_expected.to be_truthy }
    end

    context 'when all verification strategies fail' do
      before { allow(access_token).to receive(:get).and_raise(::OAuth2::Error.new('whoops')) }

      it 'raises a DomainVerificationError' do
        expect { result }.to raise_error OmniAuth::MicrosoftGraph::DomainVerificationError
      end
    end
  end
end
