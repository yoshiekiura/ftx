class LobbyMessage < ActiveYamlBase
  # include NewRelic::Agent::Instrumentation::ControllerInstrumentation
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

  def self.ids
    @ids ||= all.map &:id
  end

  def self.assets(code)
    find_by_code(code)[:assets]
  end


end
