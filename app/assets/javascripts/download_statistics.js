(function () {
  $(document).on("turbo:load", function () {
    $("#download_statistics").on("click", function (e) {
      const toggler = $(e.target).closest('[data-bs-toggle="popover"]')[0];
      const popover = document.querySelector(toggler.dataset["anchor"]) || toggler;

      $(popover).on("shown.bs.popover", function (e) {
        downloadLink = document.getElementById("download_statistics_link")
        from = document.getElementById("download_statistics_from")
        to = document.getElementById("download_statistics_to");

        refreshDownloadLink = function() {
          url = new URL(downloadLink.href)
          var search_params = url.searchParams;

          search_params.set("from_date", from.value);
          search_params.set("to_date", to.value);

          downloadLink.href = url.toString()
        }

        from.addEventListener("change", refreshDownloadLink);
        to.addEventListener("change", refreshDownloadLink);
      });
    })
  })
}).call(this);
