# frozen_string_literal: true

# Represents an administrative level: country, state, province, township
class Location < ApplicationRecord
  include LocalizableJsonProperty
  include ConfigurationRecord

  ADMIN_LEVELS = [0, 1, 2, 3, 4, 5].freeze
  ADMIN_LEVEL_OUT_OF_RANGE = 100
  LIMIT_FOR_API = 200

  attr_writer :parent
  localize_properties :name, :placename

  self.unique_id_attribute = 'location_code'

  validates :admin_level, presence: { message: I18n.t('errors.models.location.admin_level_present') },
                          if: :top_level?
  validates :location_code, presence: { message: I18n.t('errors.models.location.code_present') },
                            uniqueness: { message: I18n.t('errors.models.location.unique_location_code') }
  validate :validate_placename_in_english

  before_validation :generate_hierarchy
  before_validation :set_name_from_hierarchy_placenames

  # Only top level locations' admin levels are editable
  # All other locations' admin levels are calculated based on their parent's admin level
  before_save :calculate_admin_level, unless: :skip_calculate_admin_level?
  after_save :update_descendants
  after_save :generate_location_files

  scope :enabled, ->(is_enabled = true) { where.not(disabled: is_enabled) }
  scope :by_ancestor, ->(parent_path) { where('hierarchy_path <@ ?', parent_path) }
  scope :by_parent, ->(parent_path) { where('hierarchy_path ~ ?', "#{parent_path}.*{1}") }

  def generate_location_files
    return if ENV['PRIMERO_BOOTSTRAP']

    GenerateLocationFilesJob.set(wait_until: 5.minutes.from_now).perform_later unless OptionsQueueStats.jobs?
  end

  class << self
    # This class variables should only be set when loading location information in bulk
    #   Location.locations_by_code = Locations.all.map{|l|[l.location_code, l]}.to_h
    attr_accessor :locations_by_code

    alias list_by_all all

    def get_by_location_code(location_code)
      if @locations_by_code.present?
        @locations_by_code[location_code]
      elsif location_code.present?
        Location.find_by(location_code: location_code)
      end
    end

    def fetch_by_location_codes(location_codes)
      if @locations_by_code.present?
        location_codes.map { |l| @locations_by_code[l] }
      else
        Location.where(location_code: location_codes).order(:admin_level)
      end.compact
    end

    def find_types_in_hierarchy(location_code, location_types)
      hierarchy = [location_code]
      hierarchy << Location.find_by(location_code: location_code)&.hierarchy_path&.split('.')
      Location.find_by(type: location_types, location_code: hierarchy.flatten.compact)
    end

    # TODO: Used by select fields when you want to make a lookup out of all the agencies,
    #       but that functionality is probably deprecated. Review and delete.
    # This method returns a list of id / display_text value pairs
    # It is used to create the select options list for location fields
    def all_names(opts = {})
      locale = opts[:locale].presence || I18n.locale
      enabled.map { |r| { id: r.location_code, display_text: r.name(locale) }.with_indifferent_access }
    end

    def value_for_index(value, admin_level)
      # TODO: Possible refactor to make more efficient.
      # Consider storing locations as a full hierarchy:
      # eg. 'SO.SO22.SO2254' instead of 'SO2254'
      return unless value

      location = Location.find_by_location_code(value)
      return unless location && (location.admin_level >= admin_level)

      if admin_level == location&.admin_level
        location.location_code
      else
        # find the ancestor with the current admin_level
        ancestor = location.ancestors.find { |l| l.admin_level == admin_level }
        ancestor&.location_code
      end
    end

    def type_by_admin_level(admin_level = ADMIN_LEVELS.first)
      Location.where(admin_level: admin_level).pluck(:type).uniq
    end

    def find_by_admin_level_enabled(admin_level = ReportingLocation::DEFAULT_ADMIN_LEVEL)
      Location.enabled.where(admin_level: admin_level)
    end

    def find_names_by_admin_level_enabled(admin_level = ReportingLocation::DEFAULT_ADMIN_LEVEL, hierarchy_filter = nil,
                                          opts = {})
      locale = opts[:locale].presence || I18n.locale
      location_names = Location.find_by_admin_level_enabled(admin_level)
                               .map { |r| { id: r.location_code, hierarchy_path: r.hierarchy_path, display_text: r.placename(locale) }.with_indifferent_access }
                               .sort_by! { |l| l['display_text'] }
      return location_names if hierarchy_filter.blank? || !hierarchy_filter.is_a?(Array)

      location_names.select { |l| l['hierarchy_path'].present? && hierarchy_filter.any? { |f| l['hierarchy_path'].include?(f) } }
    end

    def ancestor_placename_by_name_and_admin_level(location_code, admin_level)
      return '' if location_code.blank? || ADMIN_LEVELS.exclude?(admin_level)

      lct = Location.find_by(location_code: location_code)
      if lct.present?
        lct.admin_level == admin_level ? lct.placename : lct.ancestor_by_admin_level(admin_level).try(:placename)
      else
        ''
      end
    end

    def display_text(location_code, opts = {})
      locale = opts[:locale].presence || I18n.locale
      lct = (location_code.present? ? Location.find_by(location_code: location_code) : '')
      lct.present? ? lct.name(locale) : ''
    end

    # This allows us to use the property 'type' on Location, normally reserved by ActiveRecord
    def inheritance_column
      'type_inheritance'
    end

    def each_slice(size = 500)
      all_locations = all
      pages = (all_locations.count / size.to_f).ceil
      (1..pages).each do |page|
        # this can be change to use `limit` and `offset`
        yield(all_locations.paginate(page: page, per_page: size))
      end
    end

    def list_by_enabled
      enabled(true)
    end

    def list_by_disabled
      enabled(false)
    end

    def hierarchy_path_from_parent_code(parent_code, curret_code)
      parent_location = Location.get_by_location_code(parent_code)
      parent_location.present? ? "#{parent_location.hierarchy_path}.#{curret_code}" : curret_code
    end

    def new_with_properties(location_properties)
      Location.new(
        location_code: location_properties[:code],
        admin_level: location_properties[:admin_level],
        type: location_properties[:type],
        placename_i18n: location_properties[:placename],
        hierarchy_path: hierarchy_path_from_parent_code(location_properties[:parent_code], location_properties[:code])
      )
    end

    def reporting_locations_for_hierarchies(hierarchies)
      admin_level = SystemSettings.current&.reporting_location_config&.admin_level ||
                    ReportingLocation::DEFAULT_ADMIN_LEVEL
      Location.where('hierarchy_path @> ARRAY[:ltrees]::ltree[]', ltrees: hierarchies.compact.uniq)
              .where(admin_level: admin_level)
    end

    def list(params = {})
      return all if params.blank?

      where(params)
    end
  end

  def generate_hierarchy_placenames(locales)
    hierarchical_name = {}.with_indifferent_access
    locales.each { |locale| hierarchical_name[locale] = [] }
    if hierarchy_path.present?
      locations = Location.fetch_by_location_codes(hierarchy_path.split('.')[0..-2])
      if locations.present?
        locations.each do |lct|
          locales.each { |locale| hierarchical_name[locale] << lct.send("placename_#{locale}") }
        end
      end
    end
    locales.each { |locale| hierarchical_name[locale] << send("placename_#{locale}") }
    hierarchical_name
  end

  def set_name_from_hierarchy_placenames
    locales = I18n.available_locales
    name_hash = generate_hierarchy_placenames(locales)
    return unless name_hash.present?

    locales.each { |locale| send("name_#{locale}=", name_hash[locale].reject(&:blank?).join('::')) }
  end

  def calculate_admin_level
    parent_location = parent
    return unless parent_location.present?

    new_admin_level = ((parent_location.admin_level || 0) + 1)
    self.admin_level = ADMIN_LEVELS.include?(new_admin_level) ? new_admin_level : ADMIN_LEVEL_OUT_OF_RANGE
  end

  def descendants
    descendants = Location.by_ancestor(hierarchy_path)
    descendants.present? ? descendants.reject { |d| d == self } : []
  end

  def direct_descendants
    # search for the old value of "hierarchy" because the "location_code" can change
    # if we search with the new value(of "hierarchy") will not return any child.
    hierarchy = attribute_before_last_save('hierarchy_path')
    hierarchy.present? ? Location.by_parent(hierarchy) : []
  end

  def location_codes_and_placenames
    ancestors.map { |lct| [lct.location_code, lct.placename] } << [location_code, placename]
  end

  def ancestors
    Location.where(location_code: hierarchy_path.split('.'))
  end

  def ancestor_by_admin_level(admin_level)
    Location.find_by(admin_level: admin_level, location_code: hierarchy_path.split('.'))
  end

  def ancestor_by_type(type)
    return self if self.type == type

    ancestors.find { |lct| lct.type == type }
  end

  def hierarchy_from_parent(parent)
    self.hierarchy_path = parent&.hierarchy_path.present? ? "#{parent.hierarchy_path}." : ''
    # TODO: Use  self.location_code.underscore
    hierarchy_path << location_code.to_s
  end

  def parent
    if hierarchy_path.present?
      # TODO: use self.hierarchy_path.split('.')[-2].upcase.dasherize
      @parent ||= Location.get_by_location_code(hierarchy_path.split('.')[-2])
    end
    @parent
  end

  def generate_hierarchy
    parent = self.parent
    a_parent = Location.find_by(id: parent)
    hierarchy_from_parent(a_parent)
  end

  def top_level?
    size_hierarchy = hierarchy_path.split('.').size
    size_hierarchy == 1
  end

  def admin_level_required?
    top_level? || new_record?
  end

  def skip_calculate_admin_level?
    top_level?
  end

  # HANDLE WITH CARE
  # If a top level location's admin level changes,
  # the admin level of all of its descendants must be recalculated
  # TODO this method should be refactor again when we will decide the way of hierachy should be done
  def update_descendants(is_parent = true)
    # Use a flag to avoid infinite loop
    unless is_parent
      calculate_admin_level unless top_level?
      set_name_from_hierarchy_placenames
      generate_hierarchy
      save! if has_changes_to_save?
    end
    # Here be dragons...Beware... recursion!!!
    direct_descendants.map do |lct|
      lct.parent = self
      lct.update_descendants(false)
    end
  end

  def validate_placename_in_english
    return true if placename_en.present?

    errors.add(:placename, I18n.t('errors.models.location.name_present')) && false
  end

  def update_properties(location_properties)
    location_properties = location_properties.with_indifferent_access if location_properties.is_a?(Hash)
    self.location_code = location_properties[:code] if location_properties[:code].present?
    if location_properties[:parent_code].present?
      self.hierarchy_path = Location.hierarchy_path_from_parent_code(location_properties[:parent_code], location_code)
    end
    self.placename_i18n = placename_from_params(location_properties)
    self.attributes = location_properties.except(:code, :parent_code, :placename)
  end

  def placename_from_params(params)
    FieldI18nService.merge_i18n_properties(
      { placename_i18n: placename_i18n },
      placename_i18n: params[:placename]
    )[:placename_i18n]
  end

  def hierarchy
    @hierarchy = hierarchy_path.split('.')[0...-1]
  end

  def hierarchy=(hierarchy)
    self.parent = Location.get_by_location_code(hierarchy.last)
    @hierarchy = hierarchy
  end
end
