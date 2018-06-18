# -*- mode: ruby -*-
# vi: set ft=ruby :
# See README.md for details

#VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(2) do |config|

  config.vm.define "kube-master"  do |ctl|
    ctl.vm.synced_folder '.', '/vagrant', disabled: true
    ctl.vm.box = "ubuntu/xenial64"
        ctl.vm.hostname = "kube-master"
        ctl.vm.network "private_network", ip: "172.31.0.10"
        ctl.vm.provider "virtualbox" do |vb|
          vb.memory = 2048
        end
  end

  config.vm.define "worker01"  do |web01|
    web01.vm.synced_folder '.', '/vagrant', disabled: true
    web01.vm.box = "ubuntu/xenial64"
        web01.vm.hostname = "worker01"
        web01.vm.network "private_network", ip: "172.31.0.11"
        web01.vm.provider "virtualbox" do |vb|
          vb.memory = 1024
        end
  end

  config.vm.define "worker02"  do |web02|
    web02.vm.synced_folder '.', '/vagrant', disabled: true
    web02.vm.box = "ubuntu/xenial64"
        web02.vm.hostname = "worker02"
        web02.vm.network "private_network", ip: "172.31.0.12"
        web02.vm.provider "virtualbox" do |vb|
          vb.memory = 1024
        end
  end
end
