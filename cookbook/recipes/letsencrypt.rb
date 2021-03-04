letsencrypt_config_dir = "/etc/letsencrypt"
letsencrypt_dir = ::File.join(node[:primero][:home_dir], "letsencrypt")
letsencrypt_public_dir = ::File.join(node[:primero][:app_dir], "public")

#TODO: After upgrading to Ubuntu 16.04 LTS, use the native package instead of downloading
directory letsencrypt_dir do
  action :create
end

execute 'snap install certbot' do
  command "snap install --classic certbot"
end
execute 'certbot alternatives configure' do
  command "update-alternatives --install /usr/bin/certbot certbot /snap/bin/certbot 1"
  only_if { !File.exists?('/usr/bin/certbot') && File.exists?('/snap/bin/certbot')}
end

unless node[:primero][:letsencrypt][:email]
  Chef::Application.fatal!("You must specify the LetsEncrypt registration email in node[:primero][:letsencrypt][:email]!")
end

fullchain = ::File.join(letsencrypt_config_dir, 'live', node[:primero][:server_hostname], 'fullchain.pem')
privkey = ::File.join(letsencrypt_config_dir, 'live', node[:primero][:server_hostname], 'privkey.pem')

service 'nginx' do
  action 'stop'
end

execute "Register Let's Encrypt Certificate" do
  command "certbot certonly --standalone -d #{node[:primero][:server_hostname]} --non-interactive --agree-tos --email #{node[:primero][:letsencrypt][:email]}"
  cwd letsencrypt_dir
  not_if do
    File.exist?(fullchain) &&
    File.exist?(privkey)
  end
end

execute 'Trigger Certbot update and a cert renewal' do
  command 'certbot renew -n'
  cwd letsencrypt_dir
end

#Update references to letsencrypt certs in app
certfiles = {
  '/etc/nginx/ssl/primero.crt' => fullchain,
  '/etc/nginx/ssl/primero.key' => privkey
}
if node[:primero][:letsencrypt] && node[:primero][:letsencrypt][:couchdb]
  certfiles = certfiles.merge({
    node[:primero][:couchdb][:cert_path] => fullchain,
    node[:primero][:couchdb][:key_path] => privkey
  })
end

certfiles.each do |certfile|
  file certfile[0] do
    action :delete
    not_if { ::File.symlink?(certfile[0]) }
  end

  link certfile[0] do
    to certfile[1]
    not_if { ::File.symlink?(certfile[0])   }
  end
end

#Start nginx
service 'nginx' do
  action :start
end

file "/etc/cron.daily/letsencrypt_renew" do
  mode '0755'
  owner "root"
  group "root"
  content <<EOH
#!/bin/bash

cd #{letsencrypt_dir}
certbot renew --quiet -n --no-self-upgrade --pre-hook "service nginx stop" --post-hook "service nginx start"
EOH
end


