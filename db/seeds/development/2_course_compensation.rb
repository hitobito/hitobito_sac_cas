CourseCompensationCategory.seed_once(
  :id,
  {id: 1,
   short_name: "HO-KAT-I",
   kind: :day,
   description: "Basiskurse Sommer/Winter",
   name_leader: "Tageshonorar - Kursleitung/Kurskategorie I",
   name_assistant_leader: "Tageshonorar - Klassenleitung/Kurskategorie I"},
  {id: 2,
   short_name: "KP-REISE/MATERIAL",
   kind: :flat,
   description: "An- und Rückreise (unabhängig von Transportmittel und Strecke), Transportkosten während dem Kurs (Bergbahn, Alpentaxi etc.)",
   name_leader: "Kurspauschale - Kursleitung/Reise & Material",
   name_assistant_leader: "Kurspauschale - Klassenleitung/Reise & Material"},
  {id: 3,
   short_name: "UB-HUETTE",
   kind: :budget,
   description: "Budgetvorgabe für SAC Hütte",
   name_leader: "SAC Hütte",
   name_assistant_leader: "SAC Hütte"}
)

CourseCompensationRate.seed_once(:course_compensation_category_id,
  {course_compensation_category_id: 1, valid_from: "2023-01-01", rate_leader: 550, rate_assistant_leader: 540},
  {course_compensation_category_id: 2, valid_from: "2023-01-01", rate_leader: 150, rate_assistant_leader: 0},
  {course_compensation_category_id: 3, valid_from: "2023-01-01", rate_leader: 80, rate_assistant_leader: 80})
