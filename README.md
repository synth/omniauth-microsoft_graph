# Omniauth::MicrosoftGraph ![ruby workflow](https://github.com/synth/omniauth-microsoft_graph/actions/workflows/ruby.yml/badge.svg)


Microsoft Graph OAuth2 Strategy for OmniAuth.
Can be used to authenticate with Office365 or other MS services, and get a token for the Microsoft Graph Api, formerly the Office365 Unified Api.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-microsoft_graph'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install omniauth-microsoft_graph

## Usage

#### Configuration
```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :microsoft_graph, ENV['AZURE_APPLICATION_CLIENT_ID'], ENV['AZURE_APPLICATION_CLIENT_SECRET']
end
```

#### Login Hint
Just add {login_hint: "email@example.com"} to your url generation to form:
```ruby
/auth/microsoft_graph?login_hint=email@example.com
```

## Contributing

1. Fork it ( https://github.com/synth/omniauth-microsoft_graph/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
