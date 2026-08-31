// Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito_sac_cas.

// Sweeps this wagon's own app/assets/images into the webpack build (under
// the generic media/images/ manifest namespace, same as core's own images -
// see the file-loader naming rule in hitobito/config/webpack/loaders/
// wagon-file.js), so files like Settings.application.logo's sac_logo_*.svg
// resolve via wagon_image_pack_tag/wagon_favicon_pack_tag and
// current_webpacker_instance.manifest.lookup! (see layouts/agenda.html.haml).
// Core's own equivalent sweep, javascripts/wagons.js.erb, only runs for
// packs that import "javascripts/wagons" (application.js) - agenda pages
// load their own, independent "agenda" pack instead, so without this they'd
// never be swept up at all.
require.context("../../assets/images", true);
