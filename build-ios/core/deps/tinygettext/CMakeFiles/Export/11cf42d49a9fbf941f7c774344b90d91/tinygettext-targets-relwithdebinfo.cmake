#----------------------------------------------------------------
# Generated CMake target import file for configuration "RelWithDebInfo".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "tinygettext::tinygettext" for configuration "RelWithDebInfo"
set_property(TARGET tinygettext::tinygettext APPEND PROPERTY IMPORTED_CONFIGURATIONS RELWITHDEBINFO)
set_target_properties(tinygettext::tinygettext PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELWITHDEBINFO "CXX"
  IMPORTED_LOCATION_RELWITHDEBINFO "${_IMPORT_PREFIX}/lib/libtinygettext.a"
  )

list(APPEND _cmake_import_check_targets tinygettext::tinygettext )
list(APPEND _cmake_import_check_files_for_tinygettext::tinygettext "${_IMPORT_PREFIX}/lib/libtinygettext.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
