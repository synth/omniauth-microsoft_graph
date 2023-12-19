# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'omniauth_microsoft_graph'
require 'stringio'

describe OmniAuth::Strategies::MicrosoftGraph do
  let(:request) { double('Request', params: {}, cookies: {}, env: {}) }
  let(:app) do
    lambda do
      [200, {}, ['Hello.']]
    end
  end

  subject do
    OmniAuth::Strategies::MicrosoftGraph.new(app, 'appid', 'secret', @options || {}).tap do |strategy|
      allow(strategy).to receive(:request) do
        request
      end
    end
  end

  before do
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.test_mode = false
  end

  describe '#client_options' do
    it 'has correct site' do
      expect(subject.client.site).to eq('https://login.microsoftonline.com/')
    end

    it 'has correct authorize_url' do
      expect(subject.client.options[:authorize_url]).to eq('common/oauth2/v2.0/authorize')
    end

    it 'has correct token_url' do
      expect(subject.client.options[:token_url]).to eq('common/oauth2/v2.0/token')
    end

    describe 'overrides' do
      context 'as strings' do
        it 'should allow overriding the site' do
          @options = { client_options: { 'site' => 'https://example.com' } }
          expect(subject.client.site).to eq('https://example.com')
        end

        it 'should allow overriding the authorize_url' do
          @options = { client_options: { 'authorize_url' => 'https://example.com' } }
          expect(subject.client.options[:authorize_url]).to eq('https://example.com')
        end

        it 'should allow overriding the token_url' do
          @options = { client_options: { 'token_url' => 'https://example.com' } }
          expect(subject.client.options[:token_url]).to eq('https://example.com')
        end
      end

      context 'as symbols' do
        it 'should allow overriding the site' do
          @options = { client_options: { site: 'https://example.com' } }
          expect(subject.client.site).to eq('https://example.com')
        end

        it 'should allow overriding the authorize_url' do
          @options = { client_options: { authorize_url: 'https://example.com' } }
          expect(subject.client.options[:authorize_url]).to eq('https://example.com')
        end

        it 'should allow overriding the token_url' do
          @options = { client_options: { token_url: 'https://example.com' } }
          expect(subject.client.options[:token_url]).to eq('https://example.com')
        end
      end
    end
  end

  describe '#authorize_options' do
    %i[display score auth_type scope prompt login_hint domain_hint response_mode].each do |k|
      it "should support #{k}" do
        @options = { k => 'http://someval' }
        expect(subject.authorize_params[k.to_s]).to eq('http://someval')
      end
    end

    describe 'callback_url' do
      it 'should default to nil' do
        @options = {}
        expect(subject.authorize_params['callback_url']).to eq(nil)
      end

      it 'should set the callback_url parameter if present' do
        @options = { callback_url: 'https://example.com' }
        expect(subject.authorize_params['callback_url']).to eq('https://example.com')
      end
    end

    describe 'access_type' do
      it 'should default to "offline"' do
        @options = {}
        expect(subject.authorize_params['access_type']).to eq('offline')
      end

      it 'should set the access_type parameter if present' do
        @options = { access_type: 'online' }
        expect(subject.authorize_params['access_type']).to eq('online')
      end
    end

    describe 'login_hint' do
      it 'should default to nil' do
        expect(subject.authorize_params['login_hint']).to eq(nil)
      end

      it 'should set the login_hint parameter if present' do
        @options = { login_hint: 'john@example.com' }
        expect(subject.authorize_params['login_hint']).to eq('john@example.com')
      end
    end

    describe 'prompt' do
      it 'should default to nil' do
        expect(subject.authorize_params['prompt']).to eq(nil)
      end

      it 'should set the prompt parameter if present' do
        @options = { prompt: 'consent select_account' }
        expect(subject.authorize_params['prompt']).to eq('consent select_account')
      end
    end

    describe 'scope' do

      it 'should leave base scopes as is' do
        @options = { scope: 'profile' }
        expect(subject.authorize_params['scope']).to eq('profile')
      end

      it 'should join scopes' do
        @options = { scope: 'profile,email' }
        expect(subject.authorize_params['scope']).to eq('profile email')
      end

      it 'should deal with whitespace when joining scopes' do
        @options = { scope: 'profile, email' }
        expect(subject.authorize_params['scope']).to eq('profile email')
      end

      it 'should set default scope to email,profile' do
        expect(subject.authorize_params['scope']).to eq('offline_access openid email profile https://graph.microsoft.com/User.Read')
      end

      it 'should support space delimited scopes' do
        @options = { scope: 'profile email' }
        expect(subject.authorize_params['scope']).to eq('profile email')
      end

      it 'should support extremely badly formed scopes' do
        @options = { scope: 'profile email,foo,steve yeah http://example.com' }
        expect(subject.authorize_params['scope']).to eq('profile email https://graph.microsoft.com/foo https://graph.microsoft.com/steve https://graph.microsoft.com/yeah http://example.com')
      end
    end

    describe 'state' do
      it 'should set the state parameter' do
        @options = { state: 'some_state' }
        expect(subject.authorize_params['state']).to eq('some_state')
        expect(subject.authorize_params[:state]).to eq('some_state')
        expect(subject.session['omniauth.state']).to eq('some_state')
      end

      it 'should set the omniauth.state dynamically' do
        allow(subject).to receive(:request) { double('Request', params: { 'state' => 'some_state' }, env: {}) }
        expect(subject.authorize_params['state']).to eq('some_state')
        expect(subject.authorize_params[:state]).to eq('some_state')
        expect(subject.session['omniauth.state']).to eq('some_state')
      end
    end

    describe 'overrides' do
      it 'should include top-level options that are marked as :authorize_options' do
        @options = { authorize_options: %i[scope foo request_visible_actions], scope: 'http://bar', foo: 'baz', hd: 'wow', request_visible_actions: 'something' }
        expect(subject.authorize_params['scope']).to eq('http://bar')
        expect(subject.authorize_params['foo']).to eq('baz')
        expect(subject.authorize_params['hd']).to eq(nil)
        expect(subject.authorize_params['request_visible_actions']).to eq('something')
      end

      describe 'request overrides' do
        %i[access_type login_hint prompt scope state].each do |k|
          context "authorize option #{k}" do
            let(:request) { double('Request', params: { k.to_s => 'http://example.com' }, cookies: {}, env: {}) }

            it "should set the #{k} authorize option dynamically in the request" do
              @options = { k: '' }
              expect(subject.authorize_params[k.to_s]).to eq('http://example.com')
            end
          end
        end

        describe 'custom authorize_options' do
          let(:request) { double('Request', params: { 'foo' => 'something' }, cookies: {}, env: {}) }

          it 'should support request overrides from custom authorize_options' do
            @options = { authorize_options: [:foo], foo: '' }
            expect(subject.authorize_params['foo']).to eq('something')
          end
        end
      end
    end
  end

  describe '#authorize_params' do
    it 'should include any authorize params passed in the :authorize_params option' do
      @options = { authorize_params: { request_visible_actions: 'something', foo: 'bar', baz: 'zip' }, hd: 'wow', bad: 'not_included' }
      expect(subject.authorize_params['request_visible_actions']).to eq('something')
      expect(subject.authorize_params['foo']).to eq('bar')
      expect(subject.authorize_params['baz']).to eq('zip')
      expect(subject.authorize_params['bad']).to eq(nil)
    end
  end

  describe '#token_params' do
    it 'should include any token params passed in the :token_params option' do
      @options = { token_params: { foo: 'bar', baz: 'zip' } }
      expect(subject.token_params['foo']).to eq('bar')
      expect(subject.token_params['baz']).to eq('zip')
    end
  end

  describe '#token_options' do
    it 'should include top-level options that are marked as :token_options' do
      @options = { token_options: %i[scope foo], scope: 'bar', foo: 'baz', bad: 'not_included' }
      expect(subject.token_params['scope']).to eq('bar')
      expect(subject.token_params['foo']).to eq('baz')
      expect(subject.token_params['bad']).to eq(nil)
    end
  end

  describe '#callback_path' do
    it 'has the correct default callback path' do
      allow(subject).to receive(:script_name).and_return('')
      expect(subject.callback_path).to eq('/auth/microsoft_graph/callback')
    end

    it 'should set the callback_path parameter if present' do
      @options = { callback_path: '/auth/foo/callback' }
      expect(subject.callback_path).to eq('/auth/foo/callback')
    end

    it 'should set the callback_path with script_name if present' do
      allow(subject).to receive(:script_name).and_return('/api/v1')
      expect(subject.callback_path).to eq('/api/v1/auth/microsoft_graph/callback')
    end
  end

  describe '#info' do
    let(:client) do
      OAuth2::Client.new('abc', 'def') do |builder|
        builder.request :url_encoded
        builder.adapter :test do |stub|
          stub.get('/v1.0/me') { [200, { 'content-type' => 'application/json' }, response_hash.to_json] }
        end
      end
    end
    let(:access_token) { OAuth2::AccessToken.from_hash(client, { 'access_token' => 'a' }) }
    before { allow(subject).to receive(:access_token).and_return(access_token) }

    context 'with verified email' do
      let(:response_hash) do
        { mail: 'something@domain.invalid' }
      end

      it 'should return equal email ' do
        expect(subject.info['email']).to eq('something@domain.invalid')
      end
    end

    context 'when email verification fails' do
      let(:response_hash) { { mail: 'something@domain.invalid' } }
      let(:error) { OmniAuth::MicrosoftGraph::DomainVerificationError.new }

      before do
        allow(OmniAuth::MicrosoftGraph::DomainVerifier).to receive(:verify!).and_raise(error)
      end

      it 'raises an error' do
        expect { subject.auth_hash }.to raise_error error
      end
    end
  end

  describe '#extra' do
    let(:client) do
      OAuth2::Client.new('abc', 'def') do |builder|
        builder.request :url_encoded
        builder.adapter :test do |stub|
          stub.get('/v1.0/me') { [200, { 'content-type' => 'application/json' }, '{"id": "12345"}'] }
        end
      end
    end
    let(:access_token) { OAuth2::AccessToken.from_hash(client, { 'access_token' => 'a' }) }

    before { allow(subject).to receive(:access_token).and_return(access_token) }

    describe 'raw_info' do
      it 'should include raw_info' do
        expect(subject.extra['raw_info']).to eq('id' => '12345')
      end
    end
  end

  describe 'build_access_token' do
    it 'should use a hybrid authorization request_uri if this is an AJAX request with a code parameter' do
      allow(request).to receive(:scheme).and_return('https')
      allow(request).to receive(:url).and_return('https://example.com')
      allow(request).to receive(:xhr?).and_return(true)
      allow(request).to receive(:params).and_return('code' => 'valid_code')

      client = double(:client)
      auth_code = double(:auth_code)
      allow(client).to receive(:auth_code).and_return(auth_code)
      expect(subject).to receive(:client).and_return(client)
      expect(auth_code).to receive(:get_token).with('valid_code', { redirect_uri: '/auth/microsoft_graph/callback' }, {})

      expect(subject).not_to receive(:orig_build_access_token)
      subject.instance_variable_set("@env", {})
      subject.send(:build_access_token)
    end

    it 'should use a hybrid authorization request_uri if this is an AJAX request (mobile) with a code parameter' do
      allow(request).to receive(:scheme).and_return('https')
      allow(request).to receive(:url).and_return('https://example.com')
      allow(request).to receive(:xhr?).and_return(true)
      allow(request).to receive(:params).and_return('code' => 'valid_code', 'callback_url' => 'localhost')

      client = double(:client)
      auth_code = double(:auth_code)
      allow(client).to receive(:auth_code).and_return(auth_code)
      expect(subject).to receive(:client).and_return(client)
      expect(auth_code).to receive(:get_token).with('valid_code', { redirect_uri: 'localhost' }, {})

      expect(subject).not_to receive(:orig_build_access_token)
      subject.instance_variable_set("@env", {})
      subject.send(:build_access_token)
    end

    it 'should use the request_uri from params if this not an AJAX request (request from installed app) with a code parameter' do
      allow(request).to receive(:scheme).and_return('https')
      allow(request).to receive(:url).and_return('https://example.com')
      allow(request).to receive(:xhr?).and_return(false)
      allow(request).to receive(:params).and_return('code' => 'valid_code', 'callback_url' => 'callback_url')

      client = double(:client)
      auth_code = double(:auth_code)
      allow(client).to receive(:auth_code).and_return(auth_code)
      expect(subject).to receive(:client).and_return(client)
      expect(auth_code).to receive(:get_token).with('valid_code', { redirect_uri: 'callback_url' }, {})

      expect(subject).not_to receive(:orig_build_access_token)
      subject.send(:build_access_token)
    end

    it 'should read access_token from hash if this is not an AJAX request with a code parameter' do
      allow(request).to receive(:scheme).and_return('https')
      allow(request).to receive(:url).and_return('https://example.com')
      allow(request).to receive(:xhr?).and_return(false)
      allow(request).to receive(:params).and_return('access_token' => 'valid_access_token')
      expect(subject).to receive(:verify_token).with('valid_access_token').and_return true
      expect(subject).to receive(:client).and_return(:client)

      token = subject.send(:build_access_token)
      expect(token).to be_instance_of(::OAuth2::AccessToken)
      expect(token.token).to eq('valid_access_token')
      expect(token.client).to eq(:client)
    end

    it 'reads the code from a json request body' do
      body = StringIO.new(%({"code":"json_access_token"}))
      client = double(:client)
      auth_code = double(:auth_code)

      allow(request).to receive(:scheme).and_return('https')
      allow(request).to receive(:url).and_return('https://example.com')
      allow(request).to receive(:xhr?).and_return(false)
      allow(request).to receive(:content_type).and_return('application/json')
      allow(request).to receive(:body).and_return(body)
      allow(client).to receive(:auth_code).and_return(auth_code)
      expect(subject).to receive(:client).and_return(client)

      expect(auth_code).to receive(:get_token).with('json_access_token', { redirect_uri: '/auth/microsoft_graph/callback' }, {})

      subject.send(:build_access_token)
    end

    it 'should use callback_url without query_string if this is not an AJAX request' do
      allow(request).to receive(:scheme).and_return('https')
      allow(request).to receive(:url).and_return('https://example.com')
      allow(request).to receive(:xhr?).and_return(false)
      allow(request).to receive(:params).and_return('code' => 'valid_code')
      allow(request).to receive(:content_type).and_return('application/x-www-form-urlencoded')

      client = double(:client)
      auth_code = double(:auth_code)
      allow(client).to receive(:auth_code).and_return(auth_code)
      allow(subject).to receive(:callback_url).and_return('callback_url_without_query_string')

      expect(subject).to receive(:client).and_return(client)
      expect(auth_code).to receive(:get_token).with('valid_code', { redirect_uri: 'callback_url_without_query_string' }, {})
      subject.send(:build_access_token)
    end
  end

  describe 'verify_token' do
    before(:each) do
      subject.options.client_options[:connection_build] = proc do |builder|
        builder.request :url_encoded
        builder.adapter :test do |stub|
          stub.get('/v1.0/me?access_token=valid_access_token') do
            [200, { 'Content-Type' => 'application/json; charset=UTF-8' }, JSON.dump(
              aud: '000000000000.apps.googleusercontent.com',
              id: '123456789',
              email: 'example@example.com',
              access_type: 'offline',
              scope: 'profile email',
              expires_in: 436
            )]
          end
          stub.get('/v1.0/me?access_token=invalid_access_token') do
            [400, { 'Content-Type' => 'application/json; charset=UTF-8' }, JSON.dump(error_description: 'Invalid Value')]
          end
        end
      end
    end

    it 'should verify token if access_token is valid and app_id equals' do
      subject.options.client_id = '000000000000.apps.googleusercontent.com'
      expect(subject.send(:verify_token, 'valid_access_token')).to eq(true)
    end

    it 'should verify token if access_token is valid and app_id authorized' do
      subject.options.authorized_client_ids = ['000000000000.apps.googleusercontent.com']
      expect(subject.send(:verify_token, 'valid_access_token')).to eq(true)
    end

    it 'should not verify token if access_token is valid but app_id is false' do
      expect(subject.send(:verify_token, 'valid_access_token')).to eq(false)
    end

    it 'should raise error if access_token is invalid' do
      expect do
        subject.send(:verify_token, 'invalid_access_token')
      end.to raise_error(OAuth2::Error)
    end
  end
end
