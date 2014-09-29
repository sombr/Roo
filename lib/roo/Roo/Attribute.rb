module Roo
  module Attribute

    def self.included( cl )
      cl.define_singleton_method :has, lambda { | **args |
        raise "Syntax: has name: { is: 'ro' }" unless args.size == 1

        _roo_meta_ ||= cl.class_variable_defined?("@@_roo_meta_") ? cl.class_variable_get("@@_roo_meta_") : {}
        _roo_meta_[:attributes] ||= {}

        attr_name = args.keys[0]
        attr_params = args.values[0]

        raise "Trying to override 'final' attribute: #{attr_name}" if (_roo_meta_[:attributes][attr_name] || {})[:final] == true

        var_name = ("@" + attr_name.to_s).to_sym

        reader_name = attr_name
        writer_name = (attr_name.to_s + "=").to_sym

        isa_check = attr_params[:isa] || lambda { |x| true }
        raise "Isa should be a function returning Boolean" unless isa_check.is_a? Proc

        coercer = attr_params[:coerce] || lambda { |x| x }
        raise "Coerce should be a function" unless coercer.is_a? Proc

        trigger = attr_params[:trigger] || lambda { |x| }
        raise "Trigger should be a function" unless trigger.is_a? Proc

        accessors = { :reader => false, :writer => false, :private => false }
        if { ro: true, rw: true, rwp: true }[attr_params[:is]]
            accessors[:reader] = true
        else
            raise "Accessor type should be specified: is: :ro, :rw, :rwp"
        end
        if { rw: true, rwp: true }[attr_params[:is]]
            accessors[:writer] = true
            accessors[:private] = true if attr_params[:is] == :rwp
        end

        reader = nil
        writer = lambda do |val|
          val = coercer.call( val )
          if isa_check.call( val )
            self.instance_variable_set( var_name, val )
            trigger.call(val)
          else
            raise "ISA failed for attribute #{attr_name} in #{self.to_s}"
          end
        end
        default = nil

        if attr_params[:lazy]
          builder = lambda { nil }
          # optimization
          if attr_params[:default] && attr_params[:builder]
            raise "Only one builder should be specified - either default or builder option"
          else
            if attr_params[:default]
              builder = ( attr_params[:default].is_a? Proc ) ? attr_params[:default] : lambda { attr_params[:default] }
            else # builder
              builder = lambda { self.send( attr_params[:builder] ) }
            end
          end

          reader = lambda {
            val = self.instance_variable_get( var_name )
            if val == nil
              val = self.instance_exec( &builder )
              self.instance_variable_set( var_name, val )
            end
            val
          }
        else # eager
          reader = lambda { self.instance_variable_get( var_name ) }
          pval = ( attr_params[:default].is_a? Proc ) ? attr_params[:default] : lambda { attr_params[:default] }
          default = pval.call()
        end
        define_method reader_name, reader if accessors[:reader]
        define_method writer_name, writer if accessors[:writer]

        _roo_meta_[:defaults] ||= {}
        _roo_meta_[:defaults][attr_name] = default

        if accessors[:private]
          protected writer_name
        end

        if attr_params[:clearer]
          attr_params[:clearer] = ("clear_" + attr_name.to_s).to_sym if attr_params[:clearer] == true
          raise "Clearer should be a symbol" unless attr_params[:clearer].is_a? Symbol
          define_method attr_params[:clearer], lambda { self.instance_variable_set( var_name, nil ) }
        end

        if attr_params[:predicate]
          attr_params[:predicate] = ("has_" + attr_name.to_s).to_sym if attr_params[:predicate] == true
          raise "Predicate should be a symbol" unless attr_params[:predicate].is_a? Symbol
          define_method attr_params[:predicate], lambda { self.instance_variable_get( var_name ) != nil }
        end

        _roo_meta_[:attributes][attr_name] ||= {}
        attr_params.each do |k,v|
          _roo_meta_[:attributes][attr_name][k] = v
        end

        cl.class_variable_set("@@_roo_meta_", _roo_meta_)
      }
    end

  end
end
