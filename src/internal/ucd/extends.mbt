///|
pub extend Gcb with Eq::{equal}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend Gcb with Eq::{not_equal}

///|
#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend Gcb with @debug.Debug::{to_repr}

///|
pub extend Incb with Eq::{equal}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend Incb with Eq::{not_equal}

///|
#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend Incb with @debug.Debug::{to_repr}
