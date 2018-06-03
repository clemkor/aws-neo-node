$:.unshift File.join(File.dirname(__FILE__), 'lib')

require 'yaml'

require 'rake_terraform'
require 'rake_docker'
require 'confidante'

require 's3_version_file'
require 'terraform_output'

RakeTerraform.define_installation_tasks(
    path: File.join(Dir.pwd, 'vendor', 'terraform'),
    version: '0.11.7')

configuration = Confidante.configuration
shared_configuration =
    configuration
        .for_overrides(
            shared_deployment_identifier: 'default')
version = S3VersionFile.new(
    shared_configuration.region,
    shared_configuration.shared_storage_bucket_name,
    shared_configuration.image_version_key,
    'build/version')

task :default => [
    :'bootstrap:plan',
    :'blockchain_archive_lambda:plan',
    :'neo:image_repository:plan',
]

namespace :version do
  task :bump do
    version.bump(:revision)
  end
end

namespace :virtualenv do
  task :create do
    mkdir_p 'vendor'
    sh 'virtualenv vendor/virtualenv --always-copy'
  end

  task :destroy do
    rm_rf 'vendor/virtualenv'
  end

  task :ensure do
    unless File.exists?('vendor/virtualenv')
      Rake::Task['virtualenv:create'].invoke
    end
  end
end

namespace :dependencies do
  namespace :install do
    task :blockchain_archive_lambda => ['virtualenv:ensure'] do
      puts 'Installing dependencies for blockchain archive lambda'

      sh_in_virtualenv(
          'pip', 'install -r ' +
          'infra/blockchain-archive-lambda/' +
          'lambda-definitions/blockchain-archive/requirements.txt')
    end

    task :all => ['dependencies:install:blockchain_archive_lambda']
  end
end

namespace :test do
  namespace :unit do
    task :blockchain_archive_lambda => [
        'dependencies:install:blockchain_archive_lambda'
    ] do
      puts 'Running unit tests for blockchain archive lambda'

      sh_in_virtualenv(
          'python', '-m unittest discover -s ' +
              'infra/blockchain-archive-lambda/' +
              'lambda-definitions/blockchain-archive')
    end

    task :all => ['test:unit:blockchain_archive_lambda']
  end
end

namespace :bootstrap do
  RakeTerraform.define_command_tasks do |t|
    t.argument_names = [:deployment_identifier]

    t.configuration_name = 'bootstrap'
    t.source_directory = 'infra/bootstrap'
    t.work_directory = 'build'

    t.state_file = lambda do |args|
      deployment =
          configuration
              .for_overrides(args)
              .deployment_identifier

      File.join(Dir.pwd, "state/bootstrap-#{deployment}.tfstate")
    end

    t.vars = lambda do |args|
      deployment =
          configuration
              .for_overrides(args)
              .deployment_identifier

      configuration
          .for_overrides(args)
          .for_scope(
              role: 'bootstrap',
              deployment: deployment)
          .vars
    end
  end
end

namespace :blockchain_archive_lambda do
  task :prepare => [
      'terraform:ensure',
      'dependencies:install:blockchain_archive_lambda'
  ] do
    rm_rf('build/lambda-definitions/blockchain-archive')
    mkdir_p('build/lambda-definitions/blockchain-archive')
    cp_r(
        'infra/blockchain-archive-lambda/lambda-definitions/blockchain-archive/.',
        'build/lambda-definitions/blockchain-archive')
    cp_r(
        'vendor/virtualenv/lib/python3.6/site-packages/.',
        'build/lambda-definitions/blockchain-archive')
  end

  RakeTerraform.define_command_tasks do |t|
    t.argument_names = [:specific_deployment_identifier]

    t.ensure_task = 'blockchain_archive_lambda:prepare'

    t.configuration_name = 'blockchain archive lambda'
    t.source_directory = 'infra/blockchain-archive-lambda'
    t.work_directory = 'build'

    t.backend_config = lambda do |args|
      deployment =
          configuration
              .for_overrides(args)
              .specific_deployment_identifier

      configuration
          .for_overrides(args)
          .for_scope(
              role: 'blockchain-archive-lambda',
              deployment: deployment)
          .backend_config
    end

    t.vars = lambda do |args|
      deployment =
          configuration
              .for_overrides(args)
              .specific_deployment_identifier

      configuration
          .for_overrides(args)
          .for_scope(
              role: 'blockchain-archive-lambda',
              deployment: deployment)
          .vars
    end
  end
end

namespace :neo do
  namespace :image_repository do
    RakeTerraform.define_command_tasks do |t|
      t.configuration_name = 'Neo image repository'
      t.source_directory = 'infra/image-repository'
      t.work_directory = 'build'

      t.backend_config = lambda do
        configuration
            .for_overrides(
                shared_deployment_identifier: 'default')
            .for_scope(
                role: 'neo-image-repository',
                deployment: 'default')
            .backend_config
      end

      t.vars = lambda do
        configuration
            .for_overrides(
                shared_deployment_identifier: 'default')
            .for_scope(
                role: 'neo-image-repository',
                deployment: 'default')
            .vars
      end
    end
  end

  namespace :image do
    RakeDocker.define_image_tasks do |t|
      t.image_name = 'aws-neo'
      t.work_directory = 'build/images'

      t.copy_spec = [
          {from: 'src/neo/Dockerfile', to: 'Dockerfile'},
          {from: 'src/neo/start-consensus', to: 'start-consensus'},
      ]

      t.repository_name = 'eth-quest/aws-neo'
      t.repository_url = lambda do
        backend_config =
            configuration
                .for_overrides(
                    shared_deployment_identifier: 'default')
                .for_scope(
                    role: 'ardor-image-repository',
                    deployment: 'default')
                .backend_config

        TerraformOutput.for(
            name: 'repository_url',
            source_directory: 'infra/image-repository',
            work_directory: 'build',
            backend_config: backend_config)
      end

      t.credentials = lambda do
        configuration =
            configuration
                .for_overrides(
                    shared_deployment_identifier: 'default')
                .for_scope(
                    role: 'neo-image-repository',
                    deployment: 'default')

        backend_config = configuration.backend_config
        region = configuration.region

        authentication_factory = RakeDocker::Authentication::ECR.new do |c|
          c.region = region
          c.registry_id = TerraformOutput.for(
              name: 'registry_id',
              source_directory: 'infra/image-repository',
              work_directory: 'build',
              backend_config: backend_config)
        end

        authentication_factory.call
      end

      t.tags = lambda do
        [version.refresh.to_s, 'latest']
      end
    end

    task :publish => [
        'version:bump',
        'neo:image:clean',
        'neo:image:build',
        'neo:image:tag',
        'neo:image:push'
    ]
  end

  namespace :service do
    RakeTerraform.define_command_tasks do |t|
      t.argument_names = [
          :specific_deployment_identifier,
          :shared_deployment_identifier,
          :environment_deployment_identifier
      ]

      t.configuration_name = 'Neo service'
      t.source_directory = 'infra/neo-service'
      t.work_directory = 'build'

      t.backend_config = lambda do |args|
        deployment_identifier =
            configuration
                .for_overrides(args)
                .deployment_identifier

        configuration
            .for_overrides(args)
            .for_scope(
                role: 'neo-service',
                deployment: deployment_identifier)
            .backend_config
      end

      t.vars = lambda do |args|
        deployment =
            configuration
                .for_overrides(args)
                .for_scope(role: 'neo-service')
                .specific_deployment_identifier

        configuration
            .for_overrides(args.to_hash.merge(
                'neo_node_version_number' => version.refresh.to_s))
            .for_scope(
                role: 'neo-service',
                deployment: deployment)
            .vars
      end
    end
  end
end

def sh_in_virtualenv command, argument_string
  sh "#{File.expand_path('vendor/virtualenv/bin')}/#{command} " +
         "#{argument_string}"
end
