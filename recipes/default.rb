#
# Cookbook Name:: fcgiwrap
# Recipe:: default
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

node['fcgiwrap']['pkgs'].each do |pkg|
  package pkg do
    action :install
  end
end

package "spawn-fcgi" do
	action :install
end

unless platform?("debian", "ubuntu")
  remote_file "/usr/local/src/fcgiwrap.tar.gz" do
    owner "root"
    group "root"
    mode 00644
    source "https://github.com/gnosek/fcgiwrap/tarball/master"
  end

  directory "/var/run/nginx" do
    owner node['fcgiwrap']['user']
    group node['fcgiwrap']['group']
    mode "0755"
    action :create
  end

  bash "install fcgiwrap" do
  	user "root"
  	cwd "/usr/local/src"
  	code <<-EOH
  	rm -rf fcgiwrap
  	mkdir fcgiwrap
  	tar -C ./fcgiwrap -xf fcgiwrap.tar.gz
  	mv fcgiwrap/*/* fcgiwrap/
  	cd fcgiwrap
  	autoreconf -i
  	./configure
  	make install
  	EOH
  	creates "/usr/local/sbin/fcgiwrap"
  end

  bash "launch fcgiwrap" do
  	code <<-EOH
  	spawn-fcgi -u #{node['fcgiwrap']['user']} -g #{node['fcgiwrap']['group']} -M 0775 -s /var/run/nginx/cgiwrap-dispatch.sock -U #{node['fcgiwrap']['user']} -G #{node['fcgiwrap']['group']} /usr/local/sbin/fcgiwrap
  	EOH
  	not_if 'pgrep fcgiwrap'
  end
end

# template "/etc/init.d/fcgiwrap" do
# 	source "fcgiwrap.erb"
# 	owner "root"
# 	group "root"
# 	mode 00644
# end
