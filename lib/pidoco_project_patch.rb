module PidocoProjectPatch
  def self.included(base)
    base.send(:include, PidocoProjectPatch::InstanceMethods)
    
    base.class_eval do
      unloadable
      has_many :pidoco_keys
    end
  end
  
  module InstanceMethods
    def prototypes
      self.pidoco_keys.map{|o| o.prototypes}.flatten
    end
  end
end