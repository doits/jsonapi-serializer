module FastJsonapi
  PROC_PARAMETER_COUNTS = ObjectSpace::WeakKeyMap.new

  class << self
    # Calls either a Proc or a Lambda, making sure to never pass more parameters to it than it can receive
    #
    # @param [Proc] proc the Proc or Lambda to call
    # @param [Array<Object>] *params any number of parameters to be passed to the Proc
    # @return [Object] the result of the Proc call with the supplied parameters
    def call_proc(proc, *params)
      # The parameters array for a lambda created from a symbol (&:foo) differs
      # from explictly defined procs/lambdas, so we can't deduce the number of
      # parameters from the array length (and differs between Ruby 2.x and 3).
      # In the case of negative arity -- unlimited/unknown argument count --
      # just send the object to act as the method receiver.
      return proc.call(params.first) if proc.arity.negative?

      # Equivalent to proc.call(*params.take(count)) without allocating the taken array
      count = parameter_count(proc)
      return proc.call(*params) if count >= params.length

      case count
      when 1 then proc.call(params[0])
      when 2 then proc.call(params[0], params[1])
      else proc.call(*params.take(count))
      end
    end

    def call_instance_exec(base, proc, *params)
      return base.instance_exec(params.first, &proc) if proc.arity.negative?

      count = parameter_count(proc)
      return base.instance_exec(*params, &proc) if count >= params.length

      case count
      when 1 then base.instance_exec(params[0], &proc)
      when 2 then base.instance_exec(params[0], params[1], &proc)
      else base.instance_exec(*params.take(count), &proc)
      end
    end

    private

    # Proc#parameters allocates an array per call, and procs are called once per record
    def parameter_count(proc)
      PROC_PARAMETER_COUNTS[proc] ||= proc.parameters.length
    end
  end
end
