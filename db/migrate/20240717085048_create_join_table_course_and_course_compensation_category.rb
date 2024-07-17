class CreateJoinTableCourseAndCourseCompensationCategory < ActiveRecord::Migration[6.1]
  def change
    create_join_table :courses, :course_compensation_categories do |t|
      t.index [:course_id, :course_compensation_category_id], name: "unique_index_course_and_course_compensation_category", unique: true
    end
  end
end
