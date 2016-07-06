class PrinterApp
  def self.call(env)
    request = Rack::Request.new env
    read = request.body.read
    $stdout.puts("read #{read.size} bytes")
    $stderr.puts(read)
    response = Rack::Response.new
    response.write 'Hello World' # write some content to the body
    # response.body = ['Hello World'] # or set it directly
    # response['X-Custom-Header'] = 'foo'
    # response.set_cookie 'bar', 'baz'
    response.status = 200

    response.finish # return the generated triplet
  end
end
