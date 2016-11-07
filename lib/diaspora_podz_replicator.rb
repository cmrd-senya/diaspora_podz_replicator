require "English"
require "yaml"
require_relative "../vendor/replica/api"

module DiasporaPodzReplicator
  class << self
    attr_writer :configuration_file

    include Diaspora::Replica::API

    def bring_up_testfarm
      install_vagrant_requirements
      unless check_repository_clone
        report_error "Can't find diaspora source repository"
        return false
      end

      ENV["pod_count"] = pod_count.to_s
      Bundler.with_clean_env do
        report_info `vagrant --version`
      end
      report_info "Host #{`ruby --version`}"
      if testenv_off?
        report_info "Bringing up test environment"
        within_diaspora_replica { pipesh "env pod_count=#{pod_count} vagrant group up testfarm" }
        return false unless $CHILD_STATUS == 0
      end
      return true
    end

    def deploy_apps
      return unless bring_up_testfarm
      (1..pod_count).each do |i|
        deploy_app_revision(i, pod_revision(i))
      end
    end

    def launch_pods
      bring_up_testfarm
      if testenv_off?
        logger.info "Required machines are halted! Aborting"
      else
        (1..pod_count).each do |i|
          launch_pod(i)
        end
        (1..pod_count).each do |i|
          next if wait_pod_up(pod_uri(i))
          report_error "Error encountered during pod #{i} launch"
          break
        end
      end
    end

    def stop_pods
      (1..pod_count).each do |i|
        stop_pod(i)
      end
    end

    def reset_databases
      (1..pod_count).each do |i|
        within_capistrano do
          pipesh "bundle exec env SERVER_URL='#{pod_host(i)}' cap test"\
          " rails:rake:db:drop rails:rake:db:setup diaspora:fixtures:generate_and_load"
        end
      end
    end

    def clean(domain)
      run_vagrant_action(domain, "destroy")
    end

    def halt(domain)
      run_vagrant_action(domain, "halt")
    end

    private

    def run_vagrant_action(domain, action)
      subcmd = if domain == "testfarm"
                 "group #{action} testfarm"
               else
                 "#{action} #{domain}"
               end
      within_diaspora_replica { system "env pod_count=#{pod_count} vagrant #{subcmd}" }
    end

    def configuration
      @configuration ||= YAML.load(open(@configuration_file))["configuration"]
    rescue => e
      report_info "Failed to read configuration #{e.to_s}, will use defaults"
      @configuration = {}
    end

    def access_nested_setting(*args)
      conf = configuration
      args.each do |arg|
        conf = conf[arg]
        return unless conf
      end
      conf
    end

    def pod_uri(pod_nr)
      access_nested_setting("pods", pod_nr, "uri") || "http://192.168.11.#{4+pod_nr*2}"
    end

    def pod_host(pod_nr)
      URI.parse(pod_uri(pod_nr)).host
    end

    def pod_revision(pod_nr)
      access_nested_setting("pods", pod_nr, "revision") || "HEAD"
    end

    def pod_count
      configuration["pod_count"] || 1
    end

    def diaspora_root
      configuration["diaspora_root"] || "#{File.dirname(@configuration_file)}/.."
    end

    def within_diaspora_replica(*_args)
      Bundler.with_clean_env do
        super
      end
    end

    def eye(*_args)
      Bundler.with_clean_env do
        super
      end
    end

    def testenv_off?
      (1..pod_count).each do |pod_nr|
        return true if machine_off?("pod#{pod_nr}")
      end
      false
    end

    def launch_pod(pod_nr)
      if diaspora_up?(pod_uri(pod_nr))
        logger.info "Pod number #{pod_nr} is already up!"
      else
        eye("start", "test", "SERVER_URL='#{pod_host(pod_nr)}'")
      end
      eye("info", "test", "SERVER_URL='#{pod_host(pod_nr)}'", true)
    end

    def stop_pod(pod_nr)
      if diaspora_up?(pod_uri(pod_nr))
        eye("stop", "test", "SERVER_URL='#{pod_host(pod_nr)}'")
      else
        logger.info "Pod number #{pod_nr} isn't up!"
      end
    end

    def deploy_app_revision(pod_nr, revision)
      report_info "Deploying revision #{revision} on pod#{pod_nr}"
      Bundler.with_clean_env do
        deploy_app("test", "BRANCH=#{revision} SERVER_URL='#{pod_host(pod_nr)}'")
      end
    end

    def install_vagrant_plugin(name)
      within_diaspora_replica do
        unless `vagrant plugin list`.include?(name)
          pipesh "vagrant plugin install #{name}"
        end
      end
    end

    def install_vagrant_requirements
      install_vagrant_plugin("vagrant-hosts")
      install_vagrant_plugin("vagrant-group")
      install_vagrant_plugin("vagrant-puppet-install")
      install_vagrant_plugin("vagrant-lxc")
    end

    def check_repository_clone
      within_diaspora_replica do
        pipesh "ln -fs -T #{diaspora_root}/ src"
        `cd src && git status`
        # if $? == 0
        #  pipesh "cd src && git fetch --all"
        # end
      end
    end
  end
end