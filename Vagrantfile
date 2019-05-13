# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
  config.vm.box = 'chef/windows-server-2016-standard'

  config.vm.provider 'virtualbox' do |v|
    v.gui = true
    v.memory = 4096
    v.cpus = 2
  end

  config.vm.network 'forwarded_port', guest: 22, host: 8022, auto_correct: true

  config.vm.provision 'shell', name: 'enable winrm', inline: <<-SHELL
    winrm quickconfig -q
  SHELL

  # TODO: This is busted
  config.vm.provision 'shell', name: 'enable sshd', inline: <<~SHELL
    Get-WindowsCapability -Online | ? Name -like 'OpenSSH*' | Add-WindowsCapability -Online
  SHELL

  config.vm.provision 'shell', name: 'install ruby', inline: <<-SHELL
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    choco install ruby -y
    choco install msys2 -y
  SHELL

  config.vm.provision 'shell', name: 'rake test:functional:windows',
    path: 'windows-setup-and-rake.bat'

  #config.vm.provision 'shell', name: 'install ruby', inline: <<-SHELL
  #  choco install ruby -y
  #SHELL

  #config.vm.provision 'shell', name: 'install bundler', inline: <<-SHELL
  #  gem install bundler
  #SHELL
end
