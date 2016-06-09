#!/usr/bin/env ruby
#
# Testing

# gem install sshkey
require 'sshkey'
# gem install gpgme
require 'gpgme'
require 'date'

str_host = 'hostnametest'
today = Date.today.to_s
tarfile = "#{str_host}-#{today}.tar"

# Create keys.
new_key = SSHKey.generate(
  type: 'RSA',
  bits: 4096,
  comment: str_host
)

# Set encryption.
crypto = GPGME::Crypto.new :always_trust => true

# Verify Keychain recipients.

# Write out new private key
File.open('id_rsa', 'w') do |f|
  crypto.encrypt new_key.private_key, :output => f, :recipients => \
    "jhanson@vistahigherlearning.com"
end
# Write out public key and put it in the authorized keys file
File.open('id_rsa.pub', 'w') do |f|
  crypto.encrypt new_key.ssh_public_key, :output => f, :recipients => \
    "jhanson@vistahigherlearning.com"
end
File.open('/home/vagrant/.ssh/authorized_keys', 'a') do |f|
  f.puts(new_key.ssh_public_key)
end

# Tar and send to S3
`tar cvf #{tarfile} id_rsa id_rsa.pub`
`aws s3 cp #{tarfile} s3://backups.recover-account/`
# Clean up:
# Clean up authorized_keys
file = File.open('/home/vagrant/.ssh/authorized_keys', 'r')
if file.readlines.size.to_i > 4
  puts 'yes'
end
# Clean up files
File.delete('id_rsa')
File.delete('id_rsa.pub')
File.delete(tarfile)
