export a `DL_URL` env variable (should be large file) then run `bin/setup` to start.

This installs gems and creates self-signed SSL cert.

## Interrupting ruby network operation

Trying to reproduce `Errno::EPIPE: Broken pipe` during upload using SSL.

### attempt 1

Not an exact recreation since not using SSL, but... what happens if we delete the tempfile from which we are reading
(i.e. file being uploaded) during upload?

* run script
* wait for upload to commence
* delete tempfile
* ruby doesn't crash, just hangs; when we send keyboard interrupt, we get the following stacktrace:

```
^C/Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/protocol.rb:155:in `select': Interrupt
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/protocol.rb:155:in `rescue in rbuf_fill'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/protocol.rb:152:in `rbuf_fill'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/protocol.rb:134:in `readuntil'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/protocol.rb:144:in `readline'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http/response.rb:39:in `read_status_line'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http/response.rb:28:in `read_new'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:1408:in `block in transport_request'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:1405:in `catch'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:1405:in `transport_request'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:1378:in `request'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:1371:in `block in request'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:853:in `start'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:1369:in `request'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/net_http.rb:82:in `perform_request'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/net_http.rb:40:in `block in call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/net_http.rb:87:in `with_net_http_connection'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/net_http.rb:32:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/request/url_encoded.rb:15:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/request/multipart.rb:14:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday_middleware-0.10.0/lib/faraday_middleware/response_middleware.rb:30:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/rack_builder.rb:139:in `build_response'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/connection.rb:377:in `run_request'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/connection.rb:177:in `post'
        from dl.rb:41:in `upload'
        from dl.rb:33:in `block in process'
        from dl.rb:28:in `download'
        from dl.rb:32:in `process'
        from dl.rb:51:in `<main>'
```

### attempt 2

If we try just switching code to use SSL, SSL handshake should fail, since server (`nv -l 8080 > /dev/null/`) doesn't do SSL.

dtrace oneliner

```
sudo dtrace -qn 'syscall:::entry /pid == $target/ { printf("(%d) %s %s", pid, probefunc, copyinstr(arg1)); }' -p 7742
sudo dtruss -p 7742
```

* run script with https
* just hangs forever
* would have expected poll or a similar syscall, but dtrace shows no syscalls by ruby process 7742
* send kbd int

```
^[[B^[[B%^A^[[A^[[A^[[A^C/Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:920:in `connect': Interrupt
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:920:in `block in connect'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/timeout.rb:76:in `timeout'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:920:in `connect'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:863:in `do_start'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:852:in `start'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:1369:in `request'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/net_http.rb:82:in `perform_request'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/net_http.rb:40:in `block in call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/net_http.rb:87:in `with_net_http_connection'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/net_http.rb:32:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/request/url_encoded.rb:15:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/request/multipart.rb:14:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday_middleware-0.10.0/lib/faraday_middleware/response_middleware.rb:30:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/rack_builder.rb:139:in `build_response'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/connection.rb:377:in `run_request'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/connection.rb:177:in `post'
        from dl.rb:41:in `upload'
        from dl.rb:33:in `block in process'
        from dl.rb:28:in `download'
        from dl.rb:32:in `process'
        from dl.rb:51:in `<main>'
```

### attempt 3

try using openssl for server?

```
openssl req -newkey rsa:2048 -nodes -x509 -subj '/CN=local.copromote.com' -days 3650 -out server.cert -keyout server.key
openssl s_server -accept 8080 -cert server.cert -key server.key -WWW
```

* run script
* server says handshake failed; client aborts with following stack trace, which makes sense, probably have to disable SSL
verification, or add manually add to osx keychain

```
/Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:920:in `connect': SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed (Faraday::SSLError)
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:920:in `block in connect'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/timeout.rb:76:in `timeout'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:920:in `connect'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:863:in `do_start'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:852:in `start'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:1369:in `request'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/net_http.rb:82:in `perform_request'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/net_http.rb:40:in `block in call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/net_http.rb:87:in `with_net_http_connection'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/net_http.rb:32:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/request/url_encoded.rb:15:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/request/multipart.rb:14:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday_middleware-0.10.0/lib/faraday_middleware/response_middleware.rb:30:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/rack_builder.rb:139:in `build_response'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/connection.rb:377:in `run_request'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/connection.rb:177:in `post'
        from dl.rb:41:in `upload'
        from dl.rb:33:in `block in process'
        from dl.rb:28:in `download'
        from dl.rb:32:in `process'
        from dl.rb:51:in `<main>'
```

### attempt 4

* disable ssl verfication and try again
* seems to hang, kill server with kdb int

```
/Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/openssl/buffering.rb:182:in `sysread_nonblock': end of file reached (Faraday::ConnectionFailed)
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/openssl/buffering.rb:182:in `read_nonblock'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/protocol.rb:153:in `rbuf_fill'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/protocol.rb:134:in `readuntil'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/protocol.rb:144:in `readline'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http/response.rb:39:in `read_status_line'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http/response.rb:28:in `read_new'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:1408:in `block in transport_request'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:1405:in `catch'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:1405:in `transport_request'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:1378:in `request'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:1371:in `block in request'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:853:in `start'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:1369:in `request'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/net_http.rb:82:in `perform_request'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/net_http.rb:40:in `block in call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/net_http.rb:87:in `with_net_http_connection'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/net_http.rb:32:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/request/url_encoded.rb:15:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/request/multipart.rb:14:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday_middleware-0.10.0/lib/faraday_middleware/response_middleware.rb:30:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/rack_builder.rb:139:in `build_response'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/connection.rb:377:in `run_request'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/connection.rb:177:in `post'
        from dl.rb:42:in `upload'
        from dl.rb:34:in `block in process'
        from dl.rb:29:in `download'
        from dl.rb:33:in `process'
        from dl.rb:52:in `<main>'
```

Progress, but it looks like the write completes very quickly, and we immediately jump into reading the response, which
probably indicates a problem, relevant code from ruby HTTP:

```ruby
def transport_request(req)
  count = 0
  begin
    begin_transport req
    res = catch(:response) {
      req.exec @socket, @curr_http_version, edit_path(req.path)
      begin
        res = HTTPResponse.read_new(@socket)
        res.decode_content = req.decode_content
      end while res.kind_of?(HTTPContinue)

      res.uri = req.uri

      res.reading_body(@socket, req.response_body_permitted?) {
        yield res if block_given?
      }
      res
    }
  rescue Net::OpenTimeout
    raise
  rescue Net::ReadTimeout, IOError, EOFError,
         Errno::ECONNRESET, Errno::ECONNABORTED, Errno::EPIPE,
         # avoid a dependency on OpenSSL
         defined?(OpenSSL::SSL) ? OpenSSL::SSL::SSLError : IOError,
         Timeout::Error => exception
    if count == 0 && IDEMPOTENT_METHODS_.include?(req.method)
      count += 1
      @socket.close if @socket and not @socket.closed?
      D "Conn close because of error #{exception}, and retry"
      retry
    end
    D "Conn close because of error #{exception}"
    @socket.close if @socket and not @socket.closed?
    raise
  end

  end_transport req, res
  res
rescue => exception
  D "Conn close because of error #{exception}"
  @socket.close if @socket and not @socket.closed?
  raise exception
end
```

Possibly openssl server is not accepting upload, which would make sense.

### attempt 5

use rack app with thin, explicitly try to receive and print file to stderr, bytes read to sdtout

* update script
* generate certs for thin
* start thin: `thin -R config.ru -p 8080 --ssl --ssl-key-file server.key --ssl-cert-file server.cert --ssl-disable-verify start 2> /dev/null`
* run script, server reads 102177483 bytes (~ 100 megs, seems right for file size), then client crashes with stack trace:

```
/Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/openssl/buffering.rb:182:in `sysread_nonblock': end of file reached (Faraday::ConnectionFailed)
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/openssl/buffering.rb:182:in `read_nonblock'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/protocol.rb:153:in `rbuf_fill'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/protocol.rb:134:in `readuntil'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/protocol.rb:144:in `readline'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http/response.rb:39:in `read_status_line'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http/response.rb:28:in `read_new'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:1408:in `block in transport_request'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:1405:in `catch'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:1405:in `transport_request'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:1378:in `request'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:1371:in `block in request'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:853:in `start'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/net/http.rb:1369:in `request'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/net_http.rb:82:in `perform_request'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/net_http.rb:40:in `block in call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/net_http.rb:87:in `with_net_http_connection'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/net_http.rb:32:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/request/url_encoded.rb:15:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/request/multipart.rb:14:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday_middleware-0.10.0/lib/faraday_middleware/response_middleware.rb:30:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/rack_builder.rb:139:in `build_response'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/connection.rb:377:in `run_request'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/connection.rb:177:in `post'
        from dl.rb:42:in `upload'
        from dl.rb:34:in `block in process'
        from dl.rb:29:in `download'
        from dl.rb:33:in `process'
        from dl.rb:52:in `<main>'
```

### attempt 6

fix previous issue by using different HTTP adapter

* start thin as per above
* run script with excon adapter
* works fine
* killing server part way through appears to cause the error we're looking for, except for NET/HTTP different:

```
/Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/openssl/buffering.rb:326:in `syswrite': Broken pipe (Errno::EPIPE) (Faraday::ConnectionFailed)
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/openssl/buffering.rb:326:in `do_write'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/openssl/buffering.rb:344:in `write'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/excon-0.42.1/lib/excon/socket.rb:134:in `block in write'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/timeout.rb:91:in `block in timeout'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/timeout.rb:35:in `block in catch'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/timeout.rb:35:in `catch'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/timeout.rb:35:in `catch'
        from /Users/luke/.rvm/rubies/ruby-2.1.2-railsexpress/lib/ruby/2.1.0/timeout.rb:106:in `timeout'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/excon-0.42.1/lib/excon/socket.rb:133:in `write'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/excon-0.42.1/lib/excon/connection.rb:165:in `request_call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/excon-0.42.1/lib/excon/middlewares/mock.rb:47:in `request_call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/excon-0.42.1/lib/excon/middlewares/instrumentor.rb:22:in `request_call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/excon-0.42.1/lib/excon/middlewares/base.rb:15:in `request_call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/excon-0.42.1/lib/excon/middlewares/base.rb:15:in `request_call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/excon-0.42.1/lib/excon/middlewares/base.rb:15:in `request_call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/excon-0.42.1/lib/excon/connection.rb:232:in `request'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/adapter/excon.rb:55:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/request/url_encoded.rb:15:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/request/multipart.rb:14:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday_middleware-0.10.0/lib/faraday_middleware/response_middleware.rb:30:in `call'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/rack_builder.rb:139:in `build_response'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/connection.rb:377:in `run_request'
        from /Users/luke/.rvm/gems/ruby-2.1.2-railsexpress/gems/faraday-0.9.2/lib/faraday/connection.rb:177:in `post'
        from dl.rb:43:in `upload'
        from dl.rb:35:in `block in process'
        from dl.rb:30:in `download'
        from dl.rb:34:in `process'
        from dl.rb:53:in `<main>'
```
