require 'docker'
class ContainerInfo
  def self.image_name container_id
    ::Docker::Container.get(container_id).json['Config']['Image']
  end
  def self.name container_id
    ::Docker::Container.get(container_id).json['Name']
  end
  def self.env container_id
    envs = ::Docker::Container.get(container_id).json['Config']['Env']
    Hash[envs.map{ |e| e.split('=') }]
  end
end

