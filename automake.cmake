set(automake_version   1.16.1)
set(automake_name      automake-${automake_version}.tar.gz)
set(automake_prefix_url https://ftp.gnu.org/gnu/automake)
set(automake_url       ${automake_prefix_url}/${automake_name})
set(automake_md5       83cc2463a4080efd46a72ba2c9f6b8f5)

ExternalProject_Add(automake
  INSTALL_DIR         ${CMAKE_INSTALL_PREFIX}/automake
  DOWNLOAD_DIR        ${CMAKE_CURRENT_SOURCE_DIR}/data
  TMP_DIR             ${CMAKE_CURRENT_SOURCE_DIR}/tmp
  STAMP_DIR           ${CMAKE_CURRENT_SOURCE_DIR}/stamp/automake-stamp
  SOURCE_DIR          ${CMAKE_CURRENT_SOURCE_DIR}/sources/automake
  URL                 ${automake_url}
  URL_MD5             ${automake_md5}
  BUILD_IN_SOURCE     1
  CONFIGURE_COMMAND   ${CMAKE_COMMAND} -E env "PATH=$ENV{PATH}:${autoconf_install_dir}/bin" <SOURCE_DIR>/configure "CC=${CMAKE_C_COMPILER}" "CXX=${CMAKE_CXX_COMPILER}" --prefix=<INSTALL_DIR>
  BUILD_COMMAND       make -j ${NUMBER_OF_PROCESSORS}
  )