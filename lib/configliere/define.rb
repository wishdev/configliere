module Configliere
  module Define
    # Definitions for params: :description, :type, :encrypted, etc.
    attr_accessor :param_definitions

    def initialize *args, &block
      super *args, &block
      # an auto-vivifying hash
      self.param_definitions = Hash.new{|hsh, key| hsh[key] = {} }
    end

    # @params param the setting to describe. Either a simple symbol or a dotted param string.
    # @params definitions the defineables to set (:description, :type, :encrypted, etc.)
    #
    # @example
    #   Config.define :dest_time, :type => Date, :description => 'Arrival time. If only a date is given, the current time of day on that date is assumed.'
    #   Config.define 'delorean.power_source', :description => 'Delorean subsytem supplying power to the Flux Capacitor.'
    #   Config.define :password, :required => true, :obscure => true
    #
    def define param, definitions={}
      self.param_definitions[param].merge! definitions
    end

    protected
    # all params with a value for the definable aspect
    #
    # @param definable the aspect to list (:description, :type, :encrypted, etc.)
    def params_with defineable
      param_definitions.keys.find_all{|param| param_definitions[param][defineable] } || []
    end

    def definitions_for defineable
      hsh = {}
      param_definitions.each do |param, defs|
        hsh[param] = defs[defineable] if defs[defineable]
      end
      hsh
    end
    public

    def resolve!
      resolve_types!
      self
    end

    def validate!
      validate_requireds!
      true
    end

    # ===========================================================================
    #
    # Describe params with
    #
    #   Config.define :param, :description => '...'
    #

    # gets the description (if any) for the param
    # @params param the setting to describe. Either a simple symbol or a dotted param string.
    def description_for param
      param_definitions[param][:description]
    end

    # All described params with their descriptions
    def descriptions
      definitions_for(:description)
    end

    # List of params that have descriptions
    def described_params
      params_with(:description)
    end

    # ===========================================================================
    #
    # Type coercion
    #
    # Define types with
    #
    #   Config.define :param, :type => Date
    #

    def type_for param
      param_definitions[param][:type]
    end

    # All described params with their descriptions
    def types
      definitions_for(:type)
    end

    # List of params that have descriptions
    def typed_params
      params_with(:type)
    end

    def resolve_types!
      types.each do |param, type|
        val = self[param]
        case
        when (type == Float)    then val = val.to_f
        when (type == Integer)  then val = val.to_i
        when (type == nil)      then val = nil   if val.blank?
        when (type == false)    then val = false if val.blank? && (! val.nil?)
        when (type == :boolean) then
          if ['false', 0, '0', nil, '', false].include?(val) then val = false else val = true end
        when (type == Date)     then val = Date.parse(val)     rescue nil
        when (type == DateTime) then val = DateTime.parse(val) rescue nil
        when (type == Time)     then
          require 'time'
          val = Time.parse(val) rescue nil
        when (type == Symbol)   then val = val.to_s.to_sym
        end
        self[param] = val
      end
    end

    # ===========================================================================
    #
    # Required params
    #
    # Define requireds with
    #
    #   Config.define :param, :required => true
    #

    # List of params that are required
    # @return [Array] list of required params
    def required_params
      params_with(:required)
    end

    # Check that all required params are present.
    def validate_requireds!
      missing = []
      required_params.each do |param|
        missing << param if self[param].nil?
      end
      raise "Missing values for #{missing.join(", ")}" if (! missing.empty?)
    end

  end

  Param.class_eval do
    include Configliere::Define
  end
end
