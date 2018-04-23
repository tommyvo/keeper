require "keeper/version"
require "active_support/inflector"

module Keeper
  class Base
    def self.store key, find: :id, select: :id, &block
      mod = Module.new
      const_set("#{key.to_s.upcase}_KEEPER_STORE", mod)
      mod.send(:define_method, "#{key}_content", block)
      include mod

      define_method key do
        get_or_init_var __method__ do
          send("#{key}_content")
        end
      end

      define_method "#{key}=" do |value|
        instance_variable_set("@#{key}", value)
      end

      define_method "get_#{key.to_s.pluralize}" do |id|
        hash = get_hash(__method__)

        hash[id] ||= select_in(send(key), key: select, id: id)
      end

      define_method "get_#{key.to_s.singularize}" do |id|
        hash = get_hash(__method__)

        hash[id] ||= find_in(send(key), key: find, id: id)
      end

      define_method "#{key.to_s.pluralize}_ids" do
        get_or_init_var __method__ do
          send(key).map(&:id)
        end
      end
    end

    private
    def get_hash name
      get_or_init_var("#{name}_hash".gsub('get_', '')) { {} }
    end

    def select_in collection, key: nil, id: nil
      collection.select{|o| o[key] == id }
    end

    def find_in collection, key: nil, id: nil
      collection.find{|o| o[key] == id }
    end

    def get_or_init_var var_name
      var_name = "@#{var_name}"
      var = instance_variable_get(var_name)
      if var.nil?
        instance_variable_set(var_name, yield)
      else
        var
      end
    end
  end
end
