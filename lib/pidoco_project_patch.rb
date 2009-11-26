require_dependency 'project'
require 'dispatcher'

module PidocoProjectPatch
  def self.included(base)
    base.class_eval do
      unloadable
      has_many :pidoco_keys
    end
  end
end

Dispatcher.to_prepare do
  Project.send(:include, PidocoProjectPatch) unless Project.include?(PidocoProjectPatch)
end