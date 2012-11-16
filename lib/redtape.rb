require "redtape/version"

require 'active_model'
require 'active_support/core_ext/class/attribute'

module Redtape
  class Form
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

    ATTRIBUTES_KEY_REGEXP = /^(.+)_attributes$/

    class_attribute :model_accessor
    attr_reader     :params

    validate        :models_correct

    def self.validates_and_saves(accessor)
      attr_reader accessor
      self.model_accessor = accessor
    end

    def self.nested_accessible_attrs(attrs = {})
    end

    def initialize(attrs = {})
      @params = attrs
      @updated_records = []
      @new_records = []
    end

    def models_correct
      model_class = self.class.model_accessor.to_s.camelize.constantize
      model =
        if params[:id]
          model_class.send(:find, params[:id])
        else
          model_class.new
        end
      @updated_records.clear
      @new_records.clear
      populate(params, model)

      instance_variable_set("@#{self.class.model_accessor}", model)

      begin
        if model.invalid?
          own_your_errors_in(model)
        end
      rescue NoMethodError => e
        fail NoMethodError, "#{self.class} is missing 'validates_and_saves :#{model_accessor}': #{e}"
      end
    end

    # Forms are never themselves persisted
    def persisted?
      false
    end

    def save
      if valid?
        begin
          ActiveRecord::Base.transaction do
            persist!
            @updated_records.each(&:save!)
          end
        rescue
          # TODO: This feels so wrong...
        end
      else
        false
      end
    end

    def persist!
      model = send(self.class.model_accessor)
      model.save
    end

    def populate(params_subset, model)
      # #merge! didn't work here....
      model.attributes = model.attributes.merge(
        params_for_current_nesting_level_only(params_subset)
      )

      params_subset.each do |key, value|
        next unless key =~ ATTRIBUTES_KEY_REGEXP
        nested_association_name = $1
        # TODO: handle has_one
        # TODO :handle belongs_to

        if value.keys.all? { |k| k =~ /^\d+$/ }
          association = model.send(nested_association_name)

          record_attrs_array = value.map { |_, v| v }

          children = association.map do |child_model|
            update_attrs = record_attrs_array.find { |a| a[:id] == child_model.id }
            record_attrs_array.delete(update_attrs)
            populate(update_attrs, child_model)
            @updated_records << child_model
          end

          record_attrs_array.each do |new_record_attrs|
            new_nested_model = populate(new_record_attrs, association.build)
            @new_records << new_nested_model
            association.send("<<", new_nested_model)
          end
        end
      end

      model
    end

    private

    def params_for_current_nesting_level_only(params_subset)
      params_subset.dup.reject { |_, v| v.is_a? Hash }
    end

    def own_your_errors_in(model)
      model.errors.each do |k, v|
        errors.add(k, v)
      end
    end

    def nested_model_instance_given(args = {})
      params_subset, association_name = args.values_at(:params, :association_name)

      model_class = association_name.to_s.singularize.camelize.constantize
      if params_subset[:id]
        model_class.send(:find, params_subset[:id])
      else
        model_class.new
      end


    end
  end
end
