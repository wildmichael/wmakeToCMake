#------------------------------------------------------------------------------
# =========                 |
# \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox
#  \\    /   O peration     |
#   \\  /    A nd           | Copyright (C) 1991-2009 OpenCFD Ltd.
#    \\/     M anipulation  |
#------------------------------------------------------------------------------
# License
#     This file is part of OpenFOAM.
#
#     OpenFOAM is free software; you can redistribute it and/or modify it
#     under the terms of the GNU General Public License as published by the
#     Free Software Foundation; either version 2 of the License, or (at your
#     option) any later version.
#
#     OpenFOAM is distributed in the hope that it will be useful, but WITHOUT
#     ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#     FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#     for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with OpenFOAM; if not, write to the Free Software Foundation,
#     Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
#
# Script
#     Makefile
#
# Description
#     Generic Makefile used by wmakeToCMake
#
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# "Argument" variable
#------------------------------------------------------------------------------

TARGET_CLASS ?= app

#------------------------------------------------------------------------------
# The Makefile use a POSIX shell
#------------------------------------------------------------------------------

SHELL      = /bin/sh


#------------------------------------------------------------------------------
# declare default paths
#------------------------------------------------------------------------------

LIB_SRC            = LIB_SRC
LIB_DIR            = LIB_DIR
FOAM_SOLVERS       := "CMAKE_SOURCE_DIR/applications/solvers"
OBJECTS_DIR        = $(MAKE_DIR)/$(WM_OPTIONS)

SYS_INC            =
SYS_LIBS           =

PROJECT_INC        = -I$(LIB_SRC)/$(WM_PROJECT)/lnInclude -I$(LIB_SRC)/OSspecific/$(WM_OSTYPE)/lnInclude
PROJECT_LIBS       = -l$(WM_PROJECT)

EXE_INC            =
EXE_LIBS           =

LIB_LIBS           =


#------------------------------------------------------------------------------
# declare default name of libraries and executables
#------------------------------------------------------------------------------

# Library
LIB             = libNULL

# Shared library extension
SO              = so

# Project executable
EXE             = $(WM_PROJECT).out

# Standalone executable
SEXE            = a.out


#------------------------------------------------------------------------------
# set compilation and dependency building rules
#------------------------------------------------------------------------------

GFLAGS     = -xc++ -D$(WM_ARCH) -DWM_$(WM_PRECISION_OPTION)
CPP        = cpp $(GFLAGS)
RULES      = $(WM_DIR)

#------------------------------------------------------------------------------
# Include PROJECT directory tree file and
# source, object and dependency list files.
# These are constructed by wmakeDerivedFiles
#------------------------------------------------------------------------------

include $(OBJECTS_DIR)/options
include $(OBJECTS_DIR)/filesMacros
include $(OBJECTS_DIR)/sourceFiles
include $(OBJECTS_DIR)/objectFiles
include $(OBJECTS_DIR)/localObjectFiles
include $(OBJECTS_DIR)/dependencyFiles
include $(OBJECTS_DIR)/targetType

#------------------------------------------------------------------------------
# set header file include paths
#------------------------------------------------------------------------------

LIB_HEADER_DIRS = \
        $(EXE_INC) \
        -IlnInclude \
        -I. \
        $(PROJECT_INC) \
        $(GINC) \
        $(SYS_INC)

#------------------------------------------------------------------------------
# convert to cmake
#------------------------------------------------------------------------------

#
# useful variables
#
CMAKELISTS_TXT = $(OBJECTS_DIR)/CMakeLists.txt
FILES_CMAKE = $(OBJECTS_DIR)/files.cmake
OUTPUT_FILES = $(CMAKELISTS_TXT) $(FILES_CMAKE)

# set the variables depending on the target (VERY USEFUL!)
app      :  TARGET         = app
lib      :  TARGET         = lib
test     :  TARGET         = test
tutorial :  TARGET         = tutorial
tutorial :  CMAKELISTS_TXT = $(OBJECTS_DIR)/CMakeLists.txt.in
tutorial :  OUTPUT_FILES   = $(CMAKELISTS_TXT)

# all -I flags
ALL_INCLUDES = $(patsubst -I%,%,$(filter -I%,$(EXE_INC)))
# filter out all -D flags
ALL_DEFINES = $(filter -D%,$(EXE_INC))
# get rid of all -I and -D flags
OTHER_COMPILE_FLAGS = $(filter-out -I% -D%,$(EXE_INC))
# get rid of anything beginning with LIB_SRC or ending on lnInclude (handled differently)
FILTERED_INCLUDES = $(filter-out $(LIB_SRC)/% %/lnInclude,$(ALL_INCLUDES))
# target name from LIB or EXE
TARGET_NAME = $(patsubst lib%,%,$(notdir $($(TARGET_TYPE))))
# libraries to link against for LIB or EXE
LINK_LIBS = $(patsubst -l%,%,$(filter -l%,$($(TARGET_TYPE)_LIBS)))
# linker flags (except -l and -L) for LIB or EXE
LIB_LINK_FLAGS = $(patsubst -l%,%,$(filter-out -L% -l%,$($(TARGET_TYPE)_LIBS)))

#
# targets
#

# declare toplevel targets phony
.PHONY: app lib test tutorial

# have the targets depend on the output
app lib test tutorial: $(OUTPUT_FILES)

# here's where the magic happens
$(OUTPUT_FILES): $(MAKE_DIR)/files $(MAKE_DIR)/options
	@echo "Converting wmake to cmake in $(abspath $(dir $(MAKE_DIR)))"
	@echo $(TARGET_NAME) > $(OBJECTS_DIR)/targetName.txt
	@echo $(TARGET_TYPE) > $(OBJECTS_DIR)/targetType.txt
	@printf '%s\n' $(SOURCE) > $(OBJECTS_DIR)/sourceFiles.txt
	@printf '%s\n' $(FILTERED_INCLUDES) | sed 's|CMAKE_SOURCE_DIR|$${&}|g' > $(OBJECTS_DIR)/includeDirs.txt
	@printf '%s\n' $(ALL_DEFINES) > $(OBJECTS_DIR)/defines.txt
	@printf '%s\n' $(OTHER_COMPILE_FLAGS) > $(OBJECTS_DIR)/compileFlags.txt
	@printf '%s\n' $(LINK_LIBS) > $(OBJECTS_DIR)/linkLibraries.txt
	@printf '%s\n' $(LINK_FLAGS) > $(OBJECTS_DIR)/linkFlags.txt
	@$(WM_DIR)/createCMakeCode $(TARGET) $(OBJECTS_DIR)

