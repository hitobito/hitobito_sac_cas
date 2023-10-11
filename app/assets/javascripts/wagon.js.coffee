- #  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
- #  hitobito_sac_cas and licensed under the Affero General Public License version 3
- #  or later. See the COPYING file at the top-level directory or at
- #  https://github.com/hitobito/hitobito_sac_cas.

`import { Application, Controller, definitionsFromContext, stimulus } from "controllers";`
compContext = require.context('../../components', true, /\_controller.js$/)
stimulus.load definitionsFromContext(compContext)
