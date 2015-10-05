# Bogo Websocket

Simple websocket library

## Usage

### Basic Usage

```ruby
require 'bogo-websocket'

socket = Bogo::Websocket::Client.new(
  :destination => 'ws://example.com:8080',
  :path => '/websocket',
  :params => {
    :fubar => true
  },
  :on_connect => proc{
    puts 'Socket Connected'
  },
  :on_disconnect => proc{
    puts 'Socket Disconnected'
  },
  :on_error => proc{|error|
    puts "Error caught: #{error.class} - #{error}"
  },
  :on_message => proc{|msg|
    puts "Received message: #{msg.inspect}"
  }
)
socket.write('stuff')
```

### SSL Usage

```ruby
socket = Bogo::Websocket::Client.new(
  :destination => 'wss://example.com:8080',
  ...
```

#### SSL Usage with Client Key/Certificate

```ruby
socket = Bogo::Websocket::Client.new(
  :destination => 'wss://example.com:8080',
  :ssl_key => '/local/path/to/key',
  :ssl_certificate => '/local/path/to/cert',
  ...
```

#### SSL Usage with Custom Context

```ruby
ssl_ctx = OpenSSL::SSL::SSLContext.new
...
socket = Bogo::Websocket::Client.new(
  :destination => 'wss://example.com:8080',
  :ssl_context => ssl_ctx,
  ...
```

## Info
* Repository: https://github.com/spox/bogo-websocket