# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:items) do
      primary_key :id
      String :slug, null: false, unique: true
      String :language, null: false
      String :topic, null: false
      String :kind, null: false
      String :difficulty, null: false
      String :title, null: false
      String :body, text: true, null: false
      column :choices, :jsonb
      String :answer, text: true
      String :explanation, text: true
      String :starter_code, text: true
      String :tests, text: true
      String :solution, text: true
      column :tags, "text[]"
      String :source, text: true
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      index %i[language topic]
    end

    create_table(:attempts) do
      primary_key :id
      foreign_key :item_id, :items, null: false, on_delete: :cascade
      TrueClass :correct, null: false
      String :response, text: true
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      index :item_id
      index :created_at
    end

    create_table(:reviews) do
      foreign_key :item_id, :items, primary_key: true, on_delete: :cascade
      Float :ease, null: false, default: 2.5
      Integer :interval_days, null: false, default: 0
      Integer :reps, null: false, default: 0
      Date :due_on, null: false
      index :due_on
    end
  end
end
