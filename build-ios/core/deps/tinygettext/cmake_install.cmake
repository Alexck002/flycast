# Install script for directory: /Users/alexmatos/flycast/core/deps/tinygettext

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/usr/local")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "TRUE")
endif()

# Set path to fallback-tool for dependency-resolution.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/Applications/Xcode-16.2.0.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/objdump")
endif()

set(CMAKE_BINARY_DIR "/Users/alexmatos/flycast/build-ios")

if(NOT PLATFORM_NAME)
  if(NOT "$ENV{PLATFORM_NAME}" STREQUAL "")
    set(PLATFORM_NAME "$ENV{PLATFORM_NAME}")
  endif()
  if(NOT PLATFORM_NAME)
    set(PLATFORM_NAME iphoneos)
  endif()
endif()

if(NOT EFFECTIVE_PLATFORM_NAME)
  if(NOT "$ENV{EFFECTIVE_PLATFORM_NAME}" STREQUAL "")
    set(EFFECTIVE_PLATFORM_NAME "$ENV{EFFECTIVE_PLATFORM_NAME}")
  endif()
  if(NOT EFFECTIVE_PLATFORM_NAME)
    set(EFFECTIVE_PLATFORM_NAME -iphoneos)
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/alexmatos/flycast/build-ios/core/deps/tinygettext/Debug${EFFECTIVE_PLATFORM_NAME}/libtinygettext.a")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a")
      execute_process(COMMAND "/Applications/Xcode-16.2.0.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a")
    endif()
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/alexmatos/flycast/build-ios/core/deps/tinygettext/Release${EFFECTIVE_PLATFORM_NAME}/libtinygettext.a")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a")
      execute_process(COMMAND "/Applications/Xcode-16.2.0.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a")
    endif()
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/alexmatos/flycast/build-ios/core/deps/tinygettext/MinSizeRel${EFFECTIVE_PLATFORM_NAME}/libtinygettext.a")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a")
      execute_process(COMMAND "/Applications/Xcode-16.2.0.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a")
    endif()
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/alexmatos/flycast/build-ios/core/deps/tinygettext/RelWithDebInfo${EFFECTIVE_PLATFORM_NAME}/libtinygettext.a")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a")
      execute_process(COMMAND "/Applications/Xcode-16.2.0.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a")
    endif()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/tinygettext" TYPE FILE FILES
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/dictionary.hpp"
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/dictionary_manager.hpp"
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/file_system.hpp"
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/iconv.hpp"
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/language.hpp"
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/log.hpp"
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/log_stream.hpp"
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/plural_forms.hpp"
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/po_parser.hpp"
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/tinygettext.hpp"
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/unix_file_system.hpp"
    )
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/pkgconfig" TYPE FILE FILES "/Users/alexmatos/flycast/build-ios/core/deps/tinygettext/tinygettext.pc")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/alexmatos/flycast/build-ios/core/deps/tinygettext/Debug${EFFECTIVE_PLATFORM_NAME}/libtinygettext.a")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a")
      execute_process(COMMAND "/Applications/Xcode-16.2.0.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a")
    endif()
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/alexmatos/flycast/build-ios/core/deps/tinygettext/Release${EFFECTIVE_PLATFORM_NAME}/libtinygettext.a")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a")
      execute_process(COMMAND "/Applications/Xcode-16.2.0.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a")
    endif()
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/alexmatos/flycast/build-ios/core/deps/tinygettext/MinSizeRel${EFFECTIVE_PLATFORM_NAME}/libtinygettext.a")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a")
      execute_process(COMMAND "/Applications/Xcode-16.2.0.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a")
    endif()
  elseif(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/alexmatos/flycast/build-ios/core/deps/tinygettext/RelWithDebInfo${EFFECTIVE_PLATFORM_NAME}/libtinygettext.a")
    if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a" AND
       NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a")
      execute_process(COMMAND "/Applications/Xcode-16.2.0.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libtinygettext.a")
    endif()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/tinygettext" TYPE FILE FILES
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/dictionary.hpp"
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/dictionary_manager.hpp"
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/file_system.hpp"
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/iconv.hpp"
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/language.hpp"
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/log.hpp"
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/log_stream.hpp"
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/plural_forms.hpp"
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/po_parser.hpp"
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/tinygettext.hpp"
    "/Users/alexmatos/flycast/core/deps/tinygettext/include/tinygettext/unix_file_system.hpp"
    )
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/tinygettext/tinygettext-targets.cmake")
    file(DIFFERENT _cmake_export_file_changed FILES
         "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/tinygettext/tinygettext-targets.cmake"
         "/Users/alexmatos/flycast/build-ios/core/deps/tinygettext/CMakeFiles/Export/11cf42d49a9fbf941f7c774344b90d91/tinygettext-targets.cmake")
    if(_cmake_export_file_changed)
      file(GLOB _cmake_old_config_files "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/tinygettext/tinygettext-targets-*.cmake")
      if(_cmake_old_config_files)
        string(REPLACE ";" ", " _cmake_old_config_files_text "${_cmake_old_config_files}")
        message(STATUS "Old export file \"$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/tinygettext/tinygettext-targets.cmake\" will be replaced.  Removing files [${_cmake_old_config_files_text}].")
        unset(_cmake_old_config_files_text)
        file(REMOVE ${_cmake_old_config_files})
      endif()
      unset(_cmake_old_config_files)
    endif()
    unset(_cmake_export_file_changed)
  endif()
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/tinygettext" TYPE FILE FILES "/Users/alexmatos/flycast/build-ios/core/deps/tinygettext/CMakeFiles/Export/11cf42d49a9fbf941f7c774344b90d91/tinygettext-targets.cmake")
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/tinygettext" TYPE FILE FILES "/Users/alexmatos/flycast/build-ios/core/deps/tinygettext/CMakeFiles/Export/11cf42d49a9fbf941f7c774344b90d91/tinygettext-targets-debug.cmake")
  endif()
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Mm][Ii][Nn][Ss][Ii][Zz][Ee][Rr][Ee][Ll])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/tinygettext" TYPE FILE FILES "/Users/alexmatos/flycast/build-ios/core/deps/tinygettext/CMakeFiles/Export/11cf42d49a9fbf941f7c774344b90d91/tinygettext-targets-minsizerel.cmake")
  endif()
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/tinygettext" TYPE FILE FILES "/Users/alexmatos/flycast/build-ios/core/deps/tinygettext/CMakeFiles/Export/11cf42d49a9fbf941f7c774344b90d91/tinygettext-targets-relwithdebinfo.cmake")
  endif()
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/tinygettext" TYPE FILE FILES "/Users/alexmatos/flycast/build-ios/core/deps/tinygettext/CMakeFiles/Export/11cf42d49a9fbf941f7c774344b90d91/tinygettext-targets-release.cmake")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/tinygettext" TYPE FILE FILES
    "/Users/alexmatos/flycast/build-ios/core/deps/tinygettext/tinygettext-config-version.cmake"
    "/Users/alexmatos/flycast/build-ios/core/deps/tinygettext/tinygettext-config.cmake"
    )
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
if(CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "/Users/alexmatos/flycast/build-ios/core/deps/tinygettext/install_local_manifest.txt"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
