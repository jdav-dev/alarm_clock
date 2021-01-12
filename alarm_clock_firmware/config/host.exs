import Config

# Add configuration that is only needed when running on the host here.

config :mnesia, dir: '.mnesia/#{Mix.env()}/#{node()}'
