class CreateJoinTableEventKindAndCourseCompensationCategory < ActiveRecord::Migration[6.1]
  def change
    create_join_table :event_kinds, :course_compensation_categories do |t|
      t.index [:event_kind_id, :course_compensation_category_id], name: "unique_index_event_kind_and_course_compensation_category", unique: true
      t.index [:course_compensation_category_id, :event_kind_id], name: "index_course_compensation_category_and_event_kind"
    end
  end
end
