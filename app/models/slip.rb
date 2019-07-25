class Slip < ActiveYamlBase
  include International
  include ActiveHash::Associations

  field :visible, default: true

  self.singleton_class.send :alias_method, :all_with_invisible, :all
  def self.all
    all_with_invisible.select &:visible
  end

  def self.enumerize
    all_with_invisible.inject({}) {|memo, i| memo[i.code.to_sym] = i.id; memo}
  end

  def self.codes
    @keys ||= all.map &:code
  end

  def self.ids
    @ids ||= all.map &:id
  end

  def self.system_slip_method
    Rails.cache.read(system_key) || 1
  end

  def self.update_system_slip(id)
    Rails.cache.write(system_key, id) 
  end

  def self.system_key
    "peatio:slip_method"
  end

  def as_json(options = {})
    {
      id: id,
      code: code,
      name: name,
      host: host
    }
  end

end
