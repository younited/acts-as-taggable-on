class ActsAsTaggableOnMigration < ActiveRecord::Migration
  def self.up
    create_table :tags do |t|
      t.string :name
    end

    create_table :taggings do |t|
      t.references :tag

      # You should make sure that the column created is
      # long enough to store the required class names.
      t.references :taggable, :polymorphic => true
      t.references :tagger, :polymorphic => true

      # Limit is created to prevent MySQL error on index
      # length for MyISAM table type: http://bit.ly/vgW2Ql
      t.string :context, :limit => 128

      t.datetime :created_at
    end

    add_index :taggings, :tag_id
    add_index :taggings, [:taggable_id, :taggable_type, :context]

    # ALIAS SUPPORT: (provided by Brad Phelan => rocket_tag gem)
    create_table :alias_tags, :id => false do |t|
      t.integer :tag_id
      t.integer :alias_id
    end

    add_index :alias_tags, :tag_id
    add_index :alias_tags, :alias_id
  end

  def self.down
    drop_table :taggings
    drop_table :tags
    drop_table :alias_tags
  end
end
