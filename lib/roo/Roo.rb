module Roo
  require_relative "Roo/Attribute"

  def self.included( cl )
    cl.send( :include, Roo::Attribute )
    cl.send( :define_method, :initialize, lambda { |**args|
        _roo_meta_ = self.class.class_variable_get("@@_roo_meta_") || {}
        _roo_meta_[:attributes] ||= {}

        _roo_meta_[:attributes].keys.each do |attr_name|
          val = args[attr_name] || _roo_meta_[:defaults][attr_name]
          var_name = ("@" + attr_name.to_s).to_sym
          self.instance_variable_set( var_name, val )
        end
    })
  end
end
