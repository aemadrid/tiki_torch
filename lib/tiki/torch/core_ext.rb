unless Object.respond_to? :local_methods
  class Object
    def local_methods(obj = self)
      (obj.methods - obj.class.superclass.instance_methods).sort
    end
  end
end

# Stolen from ...
unless ''.respond_to? :underscore
  class String
    def underscore
      self.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
        gsub(/([a-z\d])([A-Z])/, '\1_\2').
        tr('-', '_').
        downcase
    end
  end
end

# Stolen from https://raw.githubusercontent.com/basho/riak-ruby-client/lib/riak/core_ext/stringify_keys.rb
unless {}.respond_to? :stringify_keys
  class Hash
    def stringify_keys
      inject({}) do |hash, pair|
        hash[pair[0].to_s] = pair[1]
        hash
      end
    end
  end
end
