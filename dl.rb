require 'open-uri'
require 'tempfile'
require 'faraday'
require 'faraday_middleware'
require 'excon'

def connection(url)
  options = {
    url: url,
    ssl: {verify: false}
  }
  @connection = Faraday.new(options) do |builder|
    builder.response :json, :content_type => /\bjson$/
    builder.request :multipart
    builder.request :url_encoded
    builder.adapter :excon
  end
end

def download(url, &block)
  ext = File.extname(URI(url).path)
  tmp = Tempfile.new(["dl", ext])
  puts "tempfile: #{tmp.inspect}"
  IO.copy_stream(open(url), tmp)
  yield tmp
end

def process(url)
  download(url) do |tempfile|
    upload(tempfile.path)
  end
end

def upload(path)
  puts "path: #{path}"
  file = Faraday::UploadIO.new(path, 'octet/stream')
  url = 'https://localhost:8080'
  connection(url).post("", file) do |req|
    req.headers['Content-Type'] = 'application/octet-stream'
    req.headers['Transfer-Encoding'] = 'chunked'
    req.headers['Accept-Encoding'] = 'gzip, deflate'
    req.headers['Content-Length'] = file.size.to_s
    req.headers['Content-Disposition'] = 'attachment; filename="video.mp4"'
  end
end

url = ENV['DL_URL']
process(url)
