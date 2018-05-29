require 'version'
require 'aws-sdk'

class S3VersionFile
  def initialize(
      region,
      bucket,
      key,
      local_path,
      server_side_encryption = 'AES256',
      initial_version = '0.1.0')
    @bucket = bucket
    @key = key
    @local_path = local_path
    @server_side_encryption = server_side_encryption
    @initial_version = initial_version

    @client = Aws::S3::Client.new(region: region)
  end

  def bump(component)
    current = get.to_version
    bumped = current.bump(component)
    put(bumped.to_s)
  end

  def refresh
    get_remote_file || write_local_file(@initial_version)
    self
  end

  def to_s
    read_local_file
  end

  private

  def get
    get_remote_file || write_local_file(@initial_version)
    read_local_file
  end

  def put(version)
    write_local_file(version)
    put_remote_file(version)
    read_local_file
  end

  def get_remote_file
    begin
      puts 'Getting remote'
      FileUtils.mkdir_p(File.dirname(@local_path))
      @client.get_object(
          response_target: @local_path,
          bucket: @bucket,
          key: @key)
      return true
    rescue Aws::S3::Errors::NoSuchKey
      return false
    end
  end

  def put_remote_file(version)
    puts 'Putting remote'
    @client.put_object(
        body: version,
        bucket: @bucket,
        key: @key,
        server_side_encryption: @server_side_encryption)
  end

  def read_local_file
    puts 'Reading local'
    File.read(@local_path)
  end

  def write_local_file(version)
    puts 'Writing local'
    File.open(@local_path, 'w') { |f| f.write(version) }
  end
end
