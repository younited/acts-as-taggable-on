module ActsAsTaggableOn
  class Tag < ::ActiveRecord::Base
    include ActsAsTaggableOn::Utils

    attr_accessible :name if defined?(ActiveModel::MassAssignmentSecurity)

    ### ASSOCIATIONS:

    has_many :taggings, :dependent => :destroy, :class_name => 'ActsAsTaggableOn::Tagging'

    ### ALIAS SUPPORT (provided by Brad Phelan => rocket_tag gem)

    has_and_belongs_to_many :alias, :class_name => "ActsAsTaggableOn::Tag",
                :join_table => "alias_tags",
                :foreign_key => "tag_id",
                :association_foreign_key => "alias_id",
                :uniq => true,
                :after_add => :add_reverse_alias,
                :after_remove => :remove_reverse_alias

    def add_reverse_alias(tag)
      [self.alias, self].flatten.each do |t|
        tag.alias << t if !tag.alias.include?(t) && t != tag
      end
    end

    def remove_reverse_alias(tag)
      tag.alias.delete(self) if tag.alias.include?(self)
    end

    def alias?(that)
      return self.alias.include?(that)
    end

    ### VALIDATIONS:

    validates_presence_of :name
    validates_uniqueness_of :name, :if => :validates_name_uniqueness?
    validates_length_of :name, :maximum => 255

    # monkey patch this method if don't need name uniqueness validation
    def validates_name_uniqueness?
      true
    end

    ### SCOPES:

    def self.named(name)
      if ActsAsTaggableOn.strict_case_match
        where(["name = #{binary}?", name])
      else
        where(["lower(name) = ?", name.downcase])
      end
    end

    def self.named_any(list)
      if ActsAsTaggableOn.strict_case_match
        where(list.map { |tag| sanitize_sql(["name = #{binary}?", tag.to_s.mb_chars]) }.join(" OR "))
      else
        where(list.map { |tag| sanitize_sql(["lower(name) = ?", tag.to_s.mb_chars.downcase]) }.join(" OR "))
      end
    end

    def self.named_like(name)
      where(["name #{like_operator} ? ESCAPE '!'", "%#{escape_like(name)}%"])
    end

    def self.named_like_any(list)
      where(list.map { |tag| sanitize_sql(["name #{like_operator} ? ESCAPE '!'", "%#{escape_like(tag.to_s)}%"]) }.join(" OR "))
    end

    ### CLASS METHODS:

    def self.find_or_create_with_like_by_name(name)
      if (ActsAsTaggableOn.strict_case_match)
        self.find_or_create_all_with_like_by_name([name]).first
      else
        named_like(name).first || create(:name => name)
      end
    end

    def self.find_or_create_all_with_like_by_name(*list)
      list = [list].flatten

      return [] if list.empty?

      existing_tags = Tag.named_any(list)

      list.map do |tag_name|
        comparable_tag_name = comparable_name(tag_name)
        existing_tag = existing_tags.find { |tag| comparable_name(tag.name) == comparable_tag_name }

        existing_tag || Tag.create(:name => tag_name)
      end
    end

    ### INSTANCE METHODS:

    def ==(object)
      super || (object.is_a?(Tag) && name == object.name)
    end

    def to_s
      name
    end

    def count
      read_attribute(:count).to_i
    end

    class << self
      private

      def comparable_name(str)
        str.mb_chars.downcase.to_s
      end

      def binary
        /mysql/ === ActiveRecord::Base.connection_config[:adapter] ? "BINARY " : nil
      end
    end
  end
end
