include_recipe "apache2"
include_recipe "apache2::mod_python"

if node['platform_family'] == 'debian'
  packages = [ "python-cairo-dev", "python-django", "python-django-tagging", "python-memcache", "python-rrdtool" ]
elsif ["fedora", "rhel"].include?(node['platform_family'])
  include_recipe "build-essential"

  if platform?("amazon")
    packages = %w(bitmap Django14 python-django-tagging pycairo python-memcached rrdtool-python)
  else
    packages = %w(bitmap bitmap-fonts Django django-tagging pycairo python-memcached rrdtool-python)
  end
else
  packages = [ "python-cairo-dev", "python-django", "python-django-tagging", "python-memcache", "python-rrdtool" ]
end

packages.each do |graphite_package|
  package graphite_package
end

python_pip "graphite-web" do
  version node["graphite"]["version"]
  options %Q{--install-option="--prefix=#{node['graphite']['home']}" --install-option="--install-lib=#{node['graphite']['home']}/webapp"}
  action :install
end

template "#{node['graphite']['home']}/conf/graphTemplates.conf" do
  mode "0644"
  source "graphTemplates.conf.erb"
  owner node["apache"]["user"]
  group node["apache"]["group"]
  notifies :restart, resources(:service => 'apache2')
end

template "#{node['graphite']['home']}/webapp/graphite/local_settings.py" do
  mode "0644"
  source "local_settings.py.erb"
  owner node["apache"]["user"]
  group node["apache"]["group"]
  variables(
    :home           => node["graphite"]["home"],
    :whisper_dir    => node["graphite"]["carbon"]["whisper_dir"],
    :timezone       => node["graphite"]["dashboard"]["timezone"],
    :memcache_hosts => node["graphite"]["dashboard"]["memcache_hosts"]
  )
  notifies :restart, resources(:service => 'apache2')
end

apache_site "000-default" do
  enable false
end

web_app "graphite" do
  template "graphite.conf.erb"
  docroot "#{node['graphite']['home']}/webapp"
  server_name "graphite"
  graphite_home node["graphite"]["home"]
end

directory "#{node['graphite']['home']}/storage/log" do
  owner node["apache"]["user"]
  group node["apache"]["group"]
end

directory node['graphite']['carbon']['whisper_dir'] do
  owner node["apache"]["user"]
  group node["apache"]["group"]
end

directory "#{node['graphite']['home']}/storage/log/webapp" do
  owner node["apache"]["user"]
  group node["apache"]["group"]
end

cookbook_file "#{node['graphite']['home']}/storage/graphite.db" do
  owner node["apache"]["user"]
  group node["apache"]["group"]
  action :create_if_missing
end

logrotate_app "dashboard" do
  cookbook "logrotate"
  path "#{node['graphite']['home']}/storage/log/webapp/*.log"
  frequency "daily"
  rotate 7
  create "644 root root"
end
