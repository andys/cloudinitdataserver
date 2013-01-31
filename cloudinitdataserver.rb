#!/usr/bin/ruby

data = {
  'default' => {
    'user-data' => '',
    'meta-data' => {
      'instance-id' => 'ubuntu',
      'hostname'    => 'ubuntu',
      'public-keys' => { '0=pubkey' => { 'openssh-key' => File.read('~/.ssh/id_rsa.pub') } },
      'placement'   => { 'availability-zone' => 'unknown' }
    }
  }
}

require 'sinatra'
require 'json'

def arplookup(ip)
  `arp -an`.each_line do |l|
    if l =~ /(\d+\.\d+\.\d+\.\d+).*([0-9a-f\:]{17})/i
      return $2.downcase if $1 == ip
    end
  end
  nil
end

before do
  content_type 'text/plain'
end

get '/?' do
  body "current/\n"
end

get '/:version/?*' do
  ptr = data[arplookup(request.ip)] || data['default']
  params[:splat].first.split('/').each do |key|
    break unless ptr
    ptr = ptr[key]
  end
  if Hash===ptr
    ptr = ptr.keys.map {|k| "#{k}#{'/' if Hash===ptr[k]}" }.join("\n")
  end
  body ptr.to_s
end

post '/set/:mac/?' do
  user_data = params['user-data']
  meta_data = (JSON.parse(params['meta-data']) rescue nil)
  if(user_data && meta_data)
    data[params[:mac].downcase] = {'user-data' => user_data, 'meta-data' => meta_data}
    'OK'
  else
    500
  end
end

get '/get/:mac/?' do
  data[params[:mac].downcase].to_json
end
