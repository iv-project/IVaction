cmake_minimum_required (VERSION 3.14)
project("CPM_CHECK_VERSION" DESCRIPTION "checks if any CPM packages can be updated")

add_subdirectory(../repo cpm_check_version)
add_custom_target(CPM_CHECK_NEWER_PACKAGES)
foreach(package ${CPM_PACKAGES})
    add_custom_target(CPM_CHECK_NEWER_PACKAGES_${package}
        COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/isNewestVersion.sh
                      ${package}
                      ${CPM_PACKAGE_${package}_SOURCE_DIR}
                      ${CPM_PACKAGE_${package}_VERSION}
    )
    add_dependencies(CPM_CHECK_NEWER_PACKAGES CPM_CHECK_NEWER_PACKAGES_${package})
endforeach()
