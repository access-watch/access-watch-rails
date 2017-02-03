# Access Watch Rails library

A Ruby library to log and analyse Rails HTTP requests using the [Access Watch](http://access.watch/) cloud service.

## Installation

Install the latest version in your Gemfile

```gem "access_watch_rails"```

## Basic Usage

You will need an API key.

To get an API key, send us an email at api@access.watch and we will come back to you.

Then create the following file `config/access_watch.yml` and restart/deploy your app.

```yaml
development:
  api_key: API_KEY

production:
  api_key: API_KEY
```

Or if you prefere add the following line in `config/application.rb` and restart/deploy your app.

```ruby
config.middleware.use "AccessWatch::RackLogger", api_key: API_KEY
```

API documentation is here: https://access.watch/api-documentation/#request-logging

### Author

Alexis Bernard - <alexis@bernard.io> - <http://basesecrete.com/>

### License

The Access Watch Ruby library is licensed under the MIT License - see the `LICENSE` file for details
