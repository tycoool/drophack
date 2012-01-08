
require 'dropbox_sdk'
require 'json'
require 'open-uri'
require 'yaml'
require 'pdf/reader'

require './conf/drophack_conf'

# PDF converter

# login

def login
  $session = DropboxSession.new(APP_KEY, APP_SECRET)

  $session.get_request_token

  authorize_url = $session.get_authorize_url

  # dev hack work around
  #puts "authorizing"
  #page = open(authorize_url).read
  #raise "Did not authorize" unless page =~ /Success/


  puts "Got a request token.  Your request token key is #{$session.request_token.key} and your token secret is #{$session.request_token.secret}"

  # make the user log in and authorize this token
  puts "AUTHORIZING", authorize_url, "Please visit that web page and hit 'Allow', then hit Enter here."
  gets
            
  # get the access token from the server. Its then stored in the session.
  $session.get_access_token

  $client = DropboxClient.new($session, ACCESS_TYPE)

end

# list files
def ls_files
  $listing = $client.metadata '/'
end


# get each file
def get_file(parms)
  $client.get_file("/#{parms['path']}")
end

# save to folder with meta info
def save_file(parms, data)

  filename = File.basename(parms['path'])
  File.open( "processing/#{filename}", "w+").write( data )


  rawfilename = filename[0..filename.rindex('.')]
  File.open( "processing/#{rawfilename}meta", "w+").write( parms.to_json )
end

# for each (PDF) file, extract text 
def extract_text(filepath)

  outfile = "#{filepath[0..filepath.rindex('.')]}txt"

  converter = if RUBY_PLATFORM =~ /linux/
   "pdftotext"
  elsif RUBY_PLATFORM =~ /darwin/
    "pdf_text"
  else
    raise "unknown platform (#{RUBY_PLATFORM}) detected"
  end

  system( "#{converter} #{filepath} > #{outfile}" )

  #raise "pdf conversion failed" if $?.to_i
end


login

ls_files['contents'].each do |meta|

  next unless meta['mime_type'] == 'application/pdf'

  puts "saving #{meta['path']}"

  save_file meta, get_file(meta)

  puts 'extracting text'

  extract_text "processing/#{File.basename(meta['path'])}"

end

