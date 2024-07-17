class CreateJoinTableCourseAndCourseCompensationCategory < ActiveRecord::Migration[6.1]
  def change
    create_join_table :courses, :course_compensation_categories do |t|
      t.index [:course_id, :course_compensation_category_id], unique: true
    end
  end
end
