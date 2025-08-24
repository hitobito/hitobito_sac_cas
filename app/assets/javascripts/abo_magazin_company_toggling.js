(function () {
  const firstName = "label[for=wizards_signup_abo_magazin_wizard_person_fields_first_name]";
  const lastName = "label[for=wizards_signup_abo_magazin_wizard_person_fields_last_name]";
  const birthday = "label[for=wizards_signup_abo_magazin_wizard_person_fields_birthday]";
  const companyName = "label[for=wizards_signup_abo_magazin_wizard_person_fields_company_name]";

  const toggleRequired = function(checked) {
    if (checked) {
      $(firstName).removeClass("required")
      $(lastName).removeClass("required")
      $(birthday).removeClass("required")
      $(companyName).addClass("required")
    } else {
      $(firstName).addClass("required")
      $(lastName).addClass("required")
      $(birthday).addClass("required")
      $(companyName).removeClass("required")
    }
  }

  // as forms are submitted as streams we listen on turbo:render instead of turbo:load
  $(document).on("turbo:render", function () {
    const elem = $("#wizards_signup_abo_magazin_wizard_person_fields_company");
    if(elem) {
      toggleRequired(elem[0].checked);

      elem.on("change", function() {
        toggleRequired(elem[0].checked);
      });
    }
  })
}).call(this);
