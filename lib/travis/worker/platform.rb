#superclass for platfom specific options
# e.g. username is `travis` for linux and mac, but `Administrator` on windows

require 'erb'

class Platform < Hash

  def self.create(name, provider_name)
    platform_class = "::Platform::#{name.camelize}".constantize
    platform_class.new(provider_name)
  end


  attr_reader :provider_name

  def initialize(provider_name)
    @provider_name = provider_name
  end

  ##
  # returns wrapper script (content) for running build.sh
  # returns:
  #  nil      if no wrapper script needed
  #  Hash     key is file name, value is content of the wrapper script

  def wrapper_script(job_runner)
    nil
  end

  # return "bash" command which is executed on MV
  def command(job_runner)
    "GUEST_API_URL=%s bash --login ~/build.sh" % job_runner.guest_api_url
  end

  def password
    Travis::Worker.config[provider_name].password || platform_config.password
  end

  def username
    Travis::Worker.config[provider_name].username || platform_config.username || 'travis'
  end

  def port
    Travis::Worker.config[provider_name].port || platform_config.port || 22
  end

  def private_key_path
    Travis::Worker.config[provider_name].private_key_path || platform_config.private_key_path
  end

  def default_image
    Travis::Worker.config[provider_name].default_image || platform_config.default_image || 'travis_ubuntu1404'
  end


  protected

  def template(template_name, job_runner)
    class_name = self.class.to_s.split("::").last.downcase
    path = File.join(File.dirname(__FILE__), "platform", "templates", class_name, "#{template_name}.erb")
    template = File.read(path)
    bnd = job_runner.instance_eval { binding }
    ERB.new(template, nil, '-').result(bnd)
  end

  def platform_config
    @platform_config ||= Travis::Worker.config.platform[platform_name] || Hashr.new
  end

end

require 'travis/worker/platform/linux'
require 'travis/worker/platform/osx'
require 'travis/worker/platform/windows'
