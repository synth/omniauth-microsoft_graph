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

Register a new app in the [Azure Portal / App registrations](https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade) to get the `AZURE_APPLICATION_CLIENT_ID` and `AZURE_APPLICATION_CLIENT_SECRET` below.

#### Configuration
```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :microsoft_graph, ENV['AZURE_APPLICATION_CLIENT_ID'], ENV['AZURE_APPLICATION_CLIENT_SECRET']
end
```

#### Login Hint
Just add `{login_hint: "email@example.com"}` to your url generation to form:
```ruby
/auth/microsoft_graph?login_hint=email@example.com
```

#### Domain Verification
Because Microsoft allows users to set vanity emails on their accounts, the value of the user's "email" doesn't establish membership in that domain. Put another way, user malicious@hacker.biz can edit their email in Active Directory to ceo@yourcompany.com, and (depending on your auth implementation) may be able to log in automatically as that user.

To establish membership in the claimed email domain, we use two strategies:

* `email` domain matches `userPrincipalName` domain (which by definition is a verified domain)
* The user's `id_token` includes the `xms_edov` ("Email Domain Ownership Verified") claim, with a truthy value

The `xms_edov` claim is [optional](https://github.com/MicrosoftDocs/azure-docs/issues/111425), and must be configured in the Azure console before it's available in the token. Refer to [Clerk's guide](https://clerk.com/docs/authentication/social-connections/microsoft#stay-secure-against-the-n-o-auth-vulnerability) for instructions on configuring the claim.

If you're not able or don't need to support domain verification, you can bypass for an individual domain:
```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :microsoft_graph,
           ENV['AZURE_APPLICATION_CLIENT_ID'],
           ENV['AZURE_APPLICATION_CLIENT_SECRET'],
           skip_domain_verification: %w[contoso.com]
end
```

Or, you can disable domain verification entirely. We *strongly recommend* that you do *not* disable domain verification if at all possible.
```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :microsoft_graph,
           ENV['AZURE_APPLICATION_CLIENT_ID'],
           ENV['AZURE_APPLICATION_CLIENT_SECRET'],
           skip_domain_verification: true
end
```

[nOAuth: How Microsoft OAuth Misconfiguration Can Lead to Full Account Takeover](https://www.descope.com/blog/post/noauth) from [Descope](https://www.descope.com/)

### Upgrading to 1.0.0
This version requires OmniAuth v2. If you are using Rails, you will need to include or upgrade `omniauth-rails_csrf_protection`. If you upgrade and get an error in your logs complaining about "authenticity error" or similiar, make sure to do `bundle update omniauth-rails_csrf_protection`

## Contributing

1. Fork it ( https://github.com/synth/omniauth-microsoft_graph/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
