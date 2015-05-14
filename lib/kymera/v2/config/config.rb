require 'yaml'
module Kymera
  class Config

    #The constructor reads in the config.yaml file, converts it into a hash and then defines methods on this class based on the
    #different sections
    def initialize
      yaml_file = File.open(File.join(Dir.pwd, '/kymera_config.yaml'), 'r+')
      yaml_file.rewind
      @config_options = YAML.load(yaml_file.read)
      @config_options.each do |key, value|
        define_singleton_method(key){value}
      end
      yaml_file.close
    end

    #This takes any changes that were made to the different sections and updates the config.yaml file (more to the point, overrides the old file
    # and replaces the entire file with the new values)
    def update
      yaml_file = File.open(File.join(Dir.pwd, '/kymera_config.yaml'), 'w+')
      @config_options.to_yaml.split('\n').each do |line|
        yaml_file.write(line)
      end
      yaml_file.rewind
      str = yaml_file.read
      yaml_file.close
      str
    end

    def to_s
      @config_options.to_yaml
    end


  end
end