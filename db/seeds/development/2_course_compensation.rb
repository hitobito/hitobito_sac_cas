CourseCompensationCategory.seed_once(
  :id,
  id: 1,
  short_name: "HO-KAT-I",
  kind: :day,
  description: "Basiskurse Sommer/Winter"
)

CourseCompensationCategory.seed_once(
  :id,
  id: 2,
  short_name: "KP-REISE/MATERIAL",
  kind: :flat,
  description: "An- und Rückreise (unabhängig von Transportmittel und Strecke), Transportkosten während dem Kurs (Bergbahn, Alpentaxi etc.)"
)

CourseCompensationCategory.seed_once(
  :id,
  id: 3,
  short_name: "UB-HUETTE",
  kind: :budget,
  description: "Budgetvorgabe für SAC Hütte"
)
