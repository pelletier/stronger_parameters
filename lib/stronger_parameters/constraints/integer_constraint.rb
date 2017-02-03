require 'stronger_parameters/constraints'

module StrongerParameters
  class IntegerConstraint < Constraint
    def value(v)
      if v.is_a?(String) && v =~ /\A-?\d+\Z/
        return v.to_i
      else
        if 0.class == Integer # ruby 2.4
          return v if v.is_a?(Integer)
        else # ruby < 2.4
          return v if  v.is_a?(Fixnum) || v.is_a?(Bignum)
        end
      end

      InvalidValue.new(v, 'must be an integer')
    end
  end
end
