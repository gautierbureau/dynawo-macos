set(autoconf_version   2.69)
set(autoconf_name      autoconf-${autoconf_version}.tar.gz)
set(autoconf_prefix_url https://ftp.gnu.org/gnu/autoconf)
set(autoconf_url       ${autoconf_prefix_url}/${autoconf_name})
set(autoconf_md5       82d05e03b93e45f5a39b828dc9c6c29b)

ExternalProject_Add(autoconf
  INSTALL_DIR         ${CMAKE_INSTALL_PREFIX}/autoconf
  DOWNLOAD_DIR        ${CMAKE_CURRENT_SOURCE_DIR}/data
  TMP_DIR             ${CMAKE_CURRENT_SOURCE_DIR}/tmp
  STAMP_DIR           ${CMAKE_CURRENT_SOURCE_DIR}/stamp/autoconf-stamp
  SOURCE_DIR          ${CMAKE_CURRENT_SOURCE_DIR}/sources/autoconf
  URL                 ${autoconf_url}
  URL_MD5             ${autoconf_md5}
  BUILD_IN_SOURCE     1
  CONFIGURE_COMMAND   <SOURCE_DIR>/configure "CC=${CMAKE_C_COMPILER}" "CXX=${CMAKE_CXX_COMPILER}" --prefix=<INSTALL_DIR>
  BUILD_COMMAND       make -j ${NUMBER_OF_PROCESSORS}
  )

ExternalProject_Get_Property(autoconf install_dir)
set(autoconf_install_dir ${install_dir})