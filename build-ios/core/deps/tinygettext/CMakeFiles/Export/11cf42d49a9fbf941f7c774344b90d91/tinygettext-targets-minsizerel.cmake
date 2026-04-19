#----------------------------------------------------------------
# Generated CMake target import file for configuration "MinSizeRel".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "tinygettext::tinygettext" for configuration "MinSizeRel"
set_property(TARGET tinygettext::tinygettext APPEND PROPERTY IMPORTED_CONFIGURATIONS MINSIZEREL)
set_target_properties(tinygettext::tinygettext PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_MINSIZEREL "CXX"
  IMPORTED_LOCATION_MINSIZEREL "${_IMPORT_PREFIX}/lib/libtinygettext.a"
  )

list(APPEND _cmake_import_check_targets tinygettext::tinygettext )
list(APPEND _cmake_import_check_files_for_tinygettext::tinygettext "${_IMPORT_PREFIX}/lib/libtinygettext.a" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
