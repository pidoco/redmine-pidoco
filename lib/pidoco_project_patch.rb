module PidocoProjectPatch
  def self.included(base)
    base.class_eval do
      unloadable
      has_many :pidoco_keys
    end
  end
end