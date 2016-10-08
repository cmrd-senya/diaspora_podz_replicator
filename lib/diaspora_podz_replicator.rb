require "rake"
require "yaml"
require_relative "../vendor/replica/api"

module DiasporaPodzReplicator
  module Tasks
    include Rake::DSL if defined? Rake::DSL
    def self.install_tasks
      load "#{File.dirname(__FILE__)}/diaspora_podz_replicator/tasks/replica.rake"
    end
  end

  def self.configuration_file=(conf_file)
    @configuration_file = conf_file
  end

  def self.configuration
    return unless @configuration_file
    @configuration ||= YAML.load(open(@configuration_file))["configuration"]
  end

  def self.pod_uri(pod_nr)
    configuration["pod#{pod_nr}"]["uri"] || "http://pod#{pod_nr}.diaspora.local"
  end

  def self.pod_host(pod_nr)
    URI.parse(pod_uri(pod_nr)).host
  end

  def self.pod_count
    configuration["pod_count"]
  end

  def self.diaspora_root
    configuration["diaspora_root"] || "#{File.dirname(@configuration_file)}/.."
  end
end
DiasporaPodzReplicator::Tasks.install_tasks