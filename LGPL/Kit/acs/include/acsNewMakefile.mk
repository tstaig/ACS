DIST:=$(shell lsb_release -i |awk '{print $$3}')
ARCH:=$(if $(findstring $(DIST),Fedora),-m64,-m32)
VLTFLAG:=$(if $(findstring $(DIST),Fedora),,-DVLT)
VLTGNUPATH:=$(if $(findstring $(DIST),Fedora),,/diska/vlt/VLT2014/gnu)
STDCPP:=$(if $(findstring $(DIST),Fedora),-std=c++11,-std=c++0x)
CPPFLAGS:=$(STDCPP) -fPIC -ggdb $(ARCH) $(VLTFLAG) -I../include $(if $(VLTGNUPATH),-I$(VLTGNUPATH)/include,)
LDFLAGS:=-L. -L../lib $(if $(VLTGNUPATH),-L$(VLTGNUPATH)/lib,) $(ARCH)

BRANCH:=$(shell git rev-parse --abbrev-ref HEAD)
REVISION:=$(shell git rev-parse HEAD)
SHORT_REVISION:=$(shell git rev-parse --short HEAD)
INSTDIR:=$(if $(wildcard $(INTROOT)),$(INTROOT),$(if $(wildcard $(FIDEOS_HOME)),$(FIDEOS_HOME)/$(BRANCH)_$(SHORT_REVISION),))
GITSTATUS:=$(shell git status)
GITDIFF:=$(shell git diff)

AT:=@

vpath  %.so ../lib $(INTROOT)/lib $(FIDEOS_HOME)/lib $(VLTGNUPATH)/lib

#makeLibraries: Makes targets for c++ libraries, both local and installable.
#1: Library Name
#2: List of Library Dependencies
#3: List of Objects
#4: List of CFLAGS
#5: List of LDLAGS
#6: Bool to Install or Not
#7: Module to Make
#8: Module Full Name
#9: Module Relative Path
define makeLibraries
ALL_TARGETS=$(ALL_TARGETS) $9/lib/lib$1.so
$(eval $1_libs:=$2)
$(eval $1_objs:=$3)
$(foreach obj,$3,$(eval $(obj)_cflags:=$4))
$(eval $1_ldflags:=$5)
$(eval $1_target:=$8_$1)
$(eval $1_path:=$9/lib/lib$1.so)
.PHONY: $8_$1
$8_$1: $9/lib/lib$1.so
	$(AT)
$9/lib/lib$1.so: $(foreach obj,$3,$9/object/$(obj).o) $(foreach lib,$2,$(if $($(lib)_target),$($(lib)_path),-l$(lib))) | $9/lib
	$(AT)g++ $(LDFLAGS) $5 -L $9/lib -shared $(foreach lib,$2,$(if $($(lib)_target),$($(lib)_path),-l$(lib))) $(foreach obj,$3,$9/object/$(obj).o) -o $9/lib/lib$1.so
$(eval $(call genTargets,$8_$1,$9/lib/lib$1.so,lib,lib$1.so,$6,$(foreach obj,$3,$8_$1_$(obj)),,$8_$1))
$(foreach obj,$3,$(eval $(call cleanFiles,$8_$1_$(obj),$9/object/$(obj).o,object,$(obj).o)))
endef

#makeExecutables: Makes targets for c++ executables, both local and installable.
#1: Executable Name
#2: List of Library Dependencies
#3: List of Objects
#4: List of CFLAGS
#5: List of LDLAGS
#6: Bool to Install or Not
#7: Module to Make
#8: Module Full Name
#9: Module Relative Path
define makeExecutables
ALL_TARGETS=$(ALL_TARGETS) $9/bin/$1
$(foreach obj,$3,$(eval $(obj)_cflags:=$4))
.PHONY: $7_$1
$8_$1: $9/bin/$1
	$(AT)
$9/bin/$1: $(foreach obj,$3,$9/object/$(obj).o) $(foreach lib,$2,$(if $($(lib)_target),$($(lib)_path),-l$(lib))) | $9/bin
	$(AT)g++ $(LDFLAGS) $5 -L $7/lib -o $9/bin/$1 $(foreach obj,$3,$9/object/$(obj).o) $(foreach lib,$2,$(if $($(lib)_target),$($(lib)_path),-l$(lib)))
$(eval $(call genTargets,$8_$1,$9/bin/$1,bin,$1,$6,$(foreach obj,$3,$8_$1_$(obj)),,$8_$1))
$(foreach obj,$3,$(eval $(call cleanFiles,$8_$1_$(obj),$9/object/$(obj).o,object,$(obj).o)))
endef

#makeScripts: Makes targets for scripts, both local and installable.
#1: Script Name
#2: Bool to Install or Not
#3: Module to Make
#4: Module Full Name
#5: Module Relative Path
define makeScripts
ALL_TARGETS=$(ALL_TARGETS) $5/bin/$1
$4_$1: $5/bin/$1
	$(AT)
$5/bin/$1: $5/src/$1 | $5/bin
	$(AT)cp $5/src/$1 $5/bin/$1
	$(AT)chmod +x $5/bin/$1
$(eval $(call genTargets,$4_$1,$5/bin/$1,bin,$1,$2,,,$4_$1))
endef

#genTargets: Generates clean, install and clean_dist targets.
#1: Target Name
#2: Associated File
#3: Associated Directory
#4: File Name
#5: Bool to Install or Not
#6: List of Target's Dependencies
#7: Bool to Install Dependencies or Not
#8: Install dependency to all
define genTargets
$(eval $(call cleanFiles,$1,$2,$3,$4,$6))
$(if $(findstring true,$5),$(eval $(call installFiles,$1,$2,$3,$4,$6,$7,$8)),)
$(if $(findstring true,$5),$(eval $(call cleanDistFiles,$1,$2,$3,$4,$6,$7)),)
endef

#installFiles: Generates targets to install in installation areas.
#1: Target Name
#2: File to Install
#3: Directory
#4: File Name
#5: Dependencies
#6: Bool to Install Dependencies or Not
#7: Install dependency to all
define installFiles
INSTALL_TARGETS=$(INSTALL_TARGETS) install_$1
.PHONY: install_$1
install_$1: $7 $(INSTDIR)/$3/$4 $(if $(findstring true,$6),$(foreach e,$5,install_$e),)
	$(AT)
$(INSTDIR)/$3/$4: $2 | $(INSTDIR)/$3
	$(AT)cp -r $2 $(INSTDIR)/$3/$4
endef

#cleanFiles: Generates targets to clean from local areas.
#1: Target Name
#2: File to Clean
#3: Directory
#4: File Name
#5: Dependencies
#6: Bool to Install Dependencies or Not.
define cleanFiles
CLEAN_TARGETS=$(CLEAN_TARGETS) clean_$1
.PHONY: clean_$1
clean_$1: $(foreach f,$5,clean_$(f))
	$(AT)$(if $(wildcard $2),rm -rf $2,)
endef

#cleanDistFiles: Generates targets to clean from installation areas.
#1: Target Name
#2: File to Clean
#3: Directory
#4: File Name
#5: Dependencies
#6: Bool to Install Dependencies or Not.
define cleanDistFiles
CLEANDIST_TARGETS=$(CLEANDIST_TARGETS) clean_dist_$1
.PHONY: clean_dist_$1
clean_dist_$1: clean_$1 $(if $(findstring true,$6),$(foreach e,$5,clean_dist_$e),)
	$(AT)$(if $(wildcard $(INSTDIR)/$3/$4),rm -rf $(INSTDIR)/$3/$4,)
endef

#1: Python Module Name
#2: Bool to Install or Not
#3: Module to Make
#4: Module Full Name
#5: Module Relative Path
define makePyModules
$4_$1: $5/lib/python/site-packages/$1.pyc
	$(AT)
$5/lib/python/site-packages/$1.pyc: $5/lib/python/site-packages/$1.py
	$(AT)python -m compileall $5/lib/python/site-packages/$1.py
$5/lib/python/site-packages/$1.py: $5/src/$1.py | $5/lib/python/site-packages
	$(AT)cp $5/src/$1.py $5/lib/python/site-packages/$1.py
$(eval $(call genTargets,$4_$1,$5/lib/python/site-packages/$1.py,lib/python/site-packages,$1.py,$2,$4_$1_pyc,true,$4_$1))
$(eval $(call genTargets,$4_$1_pyc,$5/lib/python/site-packages/$1.pyc,lib/python/site-packages,$1.pyc,$2))
endef

#1: Python Package Name
#2: Bool to Install or Not
#3: Module to Make
#4: Module Full Name
#5: Module Relative Path
define makePyPackages
$4_$1: $(patsubst %.py,%.pyc,$(subst $5/src/$1,$5/lib/python/site-packages/$1,$(wildcard $5/src/$1/*.py)))
	$(AT)
$5/lib/python/site-packages/$1/%.pyc: $5/lib/python/site-packages/$1/%.py
	$(AT)python -m compileall $$?
$5/lib/python/site-packages/$1/%.py: $5/src/$1/%.py | $5/lib/python/site-packages/$1
	$(AT)cp $$? $$@
$5/lib/python/site-packages/$1: $5/src/$1 | $5/lib/python/site-packages
	$(AT)$(if $(wildcard $5/lib/python/site-packages/$1),,mkdir $5/lib/python/site-packages/$1)
.PHONY: clean_$4_$1 install_$4_$1 clean_dist_$4_$1
clean_$4_$1: $(foreach py,$(subst $5/src/,,$(wildcard $5/src/$1/*.py)),clean_$4_$1_$(subst $1/,_,$(py)))
	$(AT)
clean_dist_$4_$1: $(foreach py,$(subst $5/src/,,$(wildcard $5/src/$1/*.py)),clean_dist_$4_$1_$(subst $1/,_,$(py)))
	$(AT)
install_$4_$1: $4_$1 | $(INSTDIR)/lib/python/site-packages/$1 $(foreach py,$(subst $5/src/,,$(wildcard $5/src/$1/*.py)),install_$4_$1_$(subst $1/,_,$(py)))
	$(AT)
$(INSTDIR)/lib/python/site-packages/$1: | $(INSTDIR)/lib/python/site-packages
	$(AT)$(if $(wildcard $(INSTDIR)/lib/python/site-packages/$1),,mkdir $(INSTDIR)/lib/python/site-packages/$1)
$(foreach py,$(subst $5/src/,,$(wildcard $5/src/$1/*.py)),$(eval $(call genTargets,$4_$1_$(subst $1/,_,$(py)),$5/lib/python/site-packages/$(py),lib/python/site-packages,$(py),$2)))
endef

#1: Include File Name
#2: Bool to Install or Not
#3: Module to Make
#4: Module Full Name
#5: Module Relative Path
define makeIncludes
$4_$1: $5/include/$1
	$(AT)
clean_$4_$1: $5/include/$1
	$(AT)
$(eval $(call installFiles,$4_$1,$5/include/$1,include,$1))
$(eval $(call cleanDistFiles,$4_$1,$5/include/$1,include,$1))
endef

#1: Config File Name
#2: Bool to Install or Not
#3: Module to Make
#4: Module Full Name
#5: Module Relative Path
define makeConfigs
$4_$1: $5/config/$1
	$(AT)
clean_$4_$1: $5/config/$1
	$(AT)
$(eval $(call installFiles,$4_$1,$5/config/$1,config,$1))
$(eval $(call cleanDistFiles,$4_$1,$5/config/$1,config,$1))
endef

#makeModule: Iterates over the lists of targets to make local and installable libraries, executables, scripts, etc. to create build, install and clean targets.
#1: Module to Make
#2: Module Full Name
#3: Module Relative Path
#4: List of Libraries
#5: List of Executables
#6: List of Scripts
#7: List of Python Modules
#8: List of Python Packages
#9: List of Local Libraries
#10: List of Local Executables
#11: List of Local Scripts
#12: List of Local Python Modules
#13: List of Local Python Packages
#14: List of Include Files to Install
#15: List of Configuration Files to Install
define makeModule
$(foreach lib,$4,$(eval $(call makeLibraries,$(lib),$($(lib)_LIBS),$($(lib)_OBJECTS),$($(lib)_CFLAGS),$($(lib)_LDFLAGS),true,$1,$2,$3)))
$(foreach exe,$5,$(eval $(call makeExecutables,$(exe),$($(exe)_LIBS),$($(exe)_OBJECTS),$($(exe)_CFLAGS),$($(exe)_LDFLAGS),true,$1,$2,$3)))
$(foreach scr,$6,$(eval $(call makeScripts,$(scr),true,$1,$2,$3)))
$(foreach pym,$7,$(eval $(call makePyModules,$(pym),true,$1,$2,$3)))
$(foreach pyp,$8,$(eval $(call makePyPackages,$(pyp),true,$1,$2,$3)))
$(foreach lib,$9,$(eval $(call makeLibraries,$(lib),$($(lib)_LIBS),$($(lib)_OBJECTS),$($(lib)_CFLAGS),$($(lib)_LDFLAGS),false,$1,$2,$3)))
$(foreach exe,$(10),$(eval $(call makeExecutables,$(exe),$($(exe)_LIBS),$($(exe)_OBJECTS),$($(exe)_CFLAGS),$($(exe)_LDFLAGS),false,$1,$2,$3)))
$(foreach scr,$(11),$(eval $(call makeScripts,$(scr),false,$1,$2,$3)))
$(foreach pym,$(12),$(eval $(call makePyModules,$(pym),false,$1,$2,$3)))
$(foreach pyp,$(13),$(eval $(call makePyPackages,$(pyp),false,$1,$2,$3)))
$(foreach inc,$(14),$(eval $(call makeIncludes,$(inc),true,$1,$2,$3)))
$(foreach cfg,$(15),$(eval $(call makeConfigs,$(cfg),true,$1,$2,$3)))
$2: $(foreach e,$4,$2_$e) $(foreach e,$5,$2_$e) $(foreach e,$6,$2_$e) $(foreach e,$7,$2_$e) $(foreach e,$8,$2_$e) $(foreach e,$9,$2_$e) $(foreach e,$(10),$2_$e) $(foreach e,$(11),$2_$e) $(foreach e,$(12),$2_$e) $(foreach e,$(13),$2_$e) $(foreach e,$(14),$2_$e) $(foreach e,$(15),$2_$e)
clean_$2: $(foreach e,$4,clean_$2_$e) $(foreach e,$5,clean_$2_$e) $(foreach e,$6,clean_$2_$e) $(foreach e,$7,clean_$2_$e) $(foreach e,$8,clean_$2_$e) $(foreach e,$9,clean_$2_$e) $(foreach e,$(10),clean_$2_$e) $(foreach e,$(11),clean_$2_$e) $(foreach e,$(12),clean_$2_$e) $(foreach e,$(13),clean_$2_$e) $(foreach e,$(14),clean_$2_$e) $(foreach e,$(15),clean_$2_$e)
	$(AT)
install_$2: $(foreach e,$4,install_$2_$e) $(foreach e,$5,install_$2_$e) $(foreach e,$6,install_$2_$e) $(foreach e,$7,install_$2_$e) $(foreach e,$8,install_$2_$e) $(foreach e,$(14),install_$2_$e) $(foreach e,$(15),install_$2_$e)
	$(AT)
clean_dist_$2: $(foreach e,$4,clean_dist_$2_$e) $(foreach e,$5,clean_dist_$2_$e) $(foreach e,$6,clean_dist_$2_$e) $(foreach e,$7,clean_dist_$2_$e) $(foreach e,$8,clean_dist_$2_$e) $(foreach e,$(14),clean_dist_$2_$e) $(foreach e,$(15),clean_dist_$2_$e)
	$(AT)
$3/object/%.o: $3/src/%.cpp | $3/object
	$(AT)g++ $(CPPFLAGS) $$($$(patsubst %.o,%,$$(lastword $$(subst /, ,$$@)))_cflags) -I $3/include -c $$? -o $$@
$3/object:
	$(AT)$(if $(wildcard $3/object),,mkdir $3/object)
$3/bin:
	$(AT)$(if $(wildcard $3/bin),,mkdir $3/bin)
$3/lib:
	$(AT)$(if $(wildcard $3/lib),,mkdir $3/lib)
$3/lib/python: | $3/lib
	$(AT)$(if $(wildcard $3/lib/python),,mkdir $3/lib/python)
$3/lib/python/site-packages: | $3/lib/python
	$(AT)$(if $(wildcard $3/lib/python/site-packages),,mkdir $3/lib/python/site-packages)
endef

#genModules: Includes the module Makefile with the list of libraries, executables, scripts, etc. to build. Calls makeModule.
#1: Module to Generate
#2: Parent Group Name
#3: Module Relative path
#4: Module Absolute path
define genModules
$(eval MODRULE:=$2_$1_)
$(eval MODDEP:=$2_$1)
$(eval include $3/$1/src/module.mk)
$(eval MODRULE:=)
$(eval MODDEP:=)
$(eval $(call storeModuleVars,$2_$1))
$(eval $(call cleanModuleIncludeVars))
$(eval $(call makeModule,$1,$2_$1,$3/$1,$($2_$1_LIBRARIES),$($2_$1_EXECUTABLES),$($2_$1_SCRIPTS),$($2_$1_PY_MODULES),$($2_$1_PY_PACKAGES),$($2_$1_LIBRARIES_L),$($2_$1_EXECUTABLES_L),$($2_$1_SCRIPTS_L),$($2_$1_PY_MODULES_L),$($2_$1_PY_PACKAGES_L),$($2_$1_INCLUDES),$($2_$1_CONFIGS)))
$(eval $(call cleanModuleVars,$2_$1))
endef

#genModule: Includes the module Makefile with the list of libraries, executables, scripts, etc. to build. Calls makeModule.
#1: Module to Generate
#2: Module Relative path
define genModule
$(eval MODRULE:=$1_)
$(eval MODDEP:=$1)
$(eval include module.mk)
all: $1_all
install: $1_install
clean: $1_clean
clean_dist: $1_clean_dist
$(eval MODRULE:=)
$(eval MODDEP:=)
$(eval $(call storeModuleVars,$1))
$(eval $(call cleanModuleIncludeVars))
$(eval $(call makeModule,$1,$1,..,$($1_LIBRARIES),$($1_EXECUTABLES),$($1_SCRIPTS),$($1_PY_MODULES),$($1_PY_PACKAGES),$($1_LIBRARIES_L),$($1_EXECUTABLES_L),$($1_SCRIPTS_L),$($1_PY_MODULES_L),$($1_PY_PACKAGES_L),$($1_INCLUDES),$($1_CONFIGS)))
$(eval $(call cleanModuleVars,$1))
endef

#1: Module Target
define storeModuleVars
$(eval $1_LIBRARIES:=$(LIBRARIES))
$(eval $1_EXECUTABLES:=$(EXECUTABLES))
$(eval $1_SCRIPTS:=$(SCRIPTS))
$(eval $1_PY_MODULES:=$(PY_MODULES))
$(eval $1_PY_PACKAGES:=$(PY_PACKAGES))
$(eval $1_LIBRARIES_L:=$(LIBRARIES_L))
$(eval $1_EXECUTABLES_L:=$(EXECUTABLES_L))
$(eval $1_SCRIPTS_L:=$(SCRIPTS_L))
$(eval $1_PY_MODULES_L:=$(PY_MODULES_L))
$(eval $1_PY_PACKAGES_L:=$(PY_PACKAGES_L))
$(eval $1_INCLUDES:=$(INCLUDES))
$(eval $1_CONFIGS:=$(CONFIGS))
endef

#1: Module Target
define cleanModuleVars
$(eval $1_LIBRARIES:=)
$(eval $1_EXECUTABLES:=)
$(eval $1_SCRIPTS:=)
$(eval $1_PY_MODULES:=)
$(eval $1_PY_PACKAGES:=)
$(eval $1_LIBRARIES_L:=)
$(eval $1_EXECUTABLES_L:=)
$(eval $1_SCRIPTS_L:=)
$(eval $1_PY_MODULES_L:=)
$(eval $1_PY_PACKAGES_L:=)
$(eval $1_INCLUDES:=)
$(eval $1_CONFIGS:=)
endef

define cleanModuleIncludeVars
$(eval LIBRARIES:=)
$(eval EXECUTABLES:=)
$(eval SCRIPTS:=)
$(eval PY_MODULES:=)
$(eval PY_PACKAGES:=)
$(eval LIBRARIES_L:=)
$(eval EXECUTABLES_L:=)
$(eval SCRIPTS_L:=)
$(eval PY_MODULES_L:=)
$(eval PY_PACKAGES_L:=)
$(eval INCLUDES:=)
$(eval CONFIGS:=)
endef

#genGroups: Includes the group Makefile with the list of subgroups and submodules. Calls makeGroup.
#1: Group to generate
#2: Parent group name
#3: Group Relative path
#4: Group Absolute path
define genGroups
$(eval GRPRULE:=$2_$1_)
$(eval GRPDEP:=$2_$1)
$(eval include $3/$1/group.mk)
$(eval GRPRULE:=)
$(eval GRPDEP:=)
$(eval $(call storeGroupVars,$2_$1))
$(eval $(call cleanGroupIncludeVars))
$(eval $(call makeGroup,$($2_$1_MODULES),$($2_$1_GROUPS),$2_$1,$3/$1))
$(eval $(call cleanGroupVars,$2_$1))
endef

#genGroup: Includes the group Makefile with the list of subgroups and submodules. Calls makeGroup.
#1: Group to generate
#2: Group Absolute path
define genGroup
$(eval GRPRULE:=$1_)
$(eval GRPDEP:=$1)
$(eval include group.mk)
build: $1_build
all: $1_all
install: $1_install
clean: $1_clean
clean_dist: $1_clean_dist
$(eval GRPRULE:=)
$(eval GRPDEP:=)
$(eval $(call storeGroupVars,$1))
$(eval $(call cleanGroupIncludeVars))
$(eval $(call makeGroup,$($1_MODULES),$($1_GROUPS),$1,.,$2))
$(eval $(call cleanGroupVars,$1))
endef

#1: Module Target
define storeGroupVars
$(eval $1_MODULES:=$(MODULES))
$(eval $1_GROUPS:=$(GROUPS))
endef

#1: Module Target
define cleanGroupVars
$(eval $1_MODULES:=)
$(eval $1_GROUPS:=)
endef

define cleanGroupIncludeVars
$(eval MODULES:=)
$(eval GROUPS:=)
endef

#makeGroup: Makes the group targets(all, install, clean, clean_dist. Calls genModules and genTargets.
#1: List of modules
#2: List of groups
#3: Group Name
#4: Group Relative path
#5: Group Absolute path
define makeGroup
$(foreach mod,$1,$(if $(wildcard $4/$(mod)/src/module.mk),$(eval $(call genModules,$(mod),$3,$4,$5)),$(error File $4/$(mod)/src/module.mk does not exist)))
$(foreach grp,$2,$(if $(wildcard $4/$(grp)/group.mk),$(eval $(call genGroups,$(grp),$3,$4,$5)),$(error File $4/$(grp)/group.mk does not exist)))
$3: $(foreach mod,$1,$4/$(mod)) $(foreach grp,$2,$4/$(grp)) $(foreach mod,$1,$3_$(mod)_all) $(foreach grp,$2,$3_$(grp)_all)
	$(AT)
clean_$3: $(foreach mod,$1,$4/$(mod)) $(foreach grp,$2,$4/$(grp)) $(foreach mod,$1,$3_$(mod)_clean) $(foreach grp,$2,$3_$(grp)_clean)
	$(AT)
install_$3: $(foreach mod,$1,$4/$(mod)) $(foreach grp,$2,$4/$(grp)) $(foreach mod,$1,$3_$(mod)_install) $(foreach grp,$2,$3_$(grp)_install)
	$(AT)
clean_dist_$3: $(foreach mod,$1,$4/$(mod)) $(foreach grp,$2,$4/$(grp)) $(foreach mod,$1,$3_$(mod)_clean_dist) $(foreach grp,$2,$3_$(grp)_clean_dist)
	$(AT)
endef

.PHONY: do_build
do_build: do_clean do_all do_install
	$(AT)echo "Branch: $(BRANCH)" > $(INSTDIR)/.version
	$(AT)echo "Revision: $(REVISION)" >> $(INSTDIR)/.version
	$(AT)echo "Status: " >> $(INSTDIR)/.version
	$(AT)echo "`git status`" >> $(INSTDIR)/.version
	$(AT)echo "Diff: " >> $(INSTDIR)/.version
	$(AT)echo "`git diff`" >> $(INSTDIR)/.version

.PHONY: do_clean
do_clean: clean_$(if $(GRP_NAME),$(GRP_NAME),$(MOD_NAME))
	$(AT)

.PHONY: do_clean_dist
do_clean_dist: clean_dist_$(if $(GRP_NAME),$(GRP_NAME),$(MOD_NAME))
	$(AT)

.PHONY: do_all
do_all: $(if $(GRP_NAME),$(GRP_NAME),$(MOD_NAME))
	$(AT)

.PHONY: do_install
do_install: prepare install_$(if $(GRP_NAME),$(GRP_NAME),$(MOD_NAME))
	$(AT)

.PHONY: build-update
build-update: build update-version
	$(AT)

.PHONY: prepare
prepare: | $(if $(INSTDIR),$(INSTDIR) $(INSTDIR)/bin $(INSTDIR)/lib $(INSTDIR)/lib/python/site-packages $(INSTDIR)/config $(INSTDIR)/include,)
	$(AT)$(if $(INSTDIR),,false)

.PHONY: update-version
update-version: prepare | $(FIDEOS_HOME) $(INSTDIR)
	$(AT)$(if $(wildcard $(FIDEOS_HOME)/current),rm -f $(FIDEOS_HOME)/current,)
	$(AT)ln -s $(INSTDIR) $(FIDEOS_HOME)/current

$(INSTDIR):
	$(AT)$(if $(wildcard $(INSTDIR)),,mkdir $(INSTDIR))
$(INSTDIR)/bin: | $(INSTDIR)
	$(AT)$(if $(wildcard $(INSTDIR)/bin),,mkdir $(INSTDIR)/bin)
$(INSTDIR)/lib: | $(INSTDIR)
	$(AT)$(if $(wildcard $(INSTDIR)/lib),,mkdir $(INSTDIR)/lib)
$(INSTDIR)/lib/python: | $(INSTDIR)/lib
	$(AT)$(if $(wildcard $(INSTDIR)lib/python),,mkdir $(INSTDIR)/lib/python)
$(INSTDIR)/lib/python/site-packages: | $(INSTDIR)/lib/python
	$(AT)$(if $(wildcard $(INSTDIR)/lib/python/site-packages),,mkdir $(INSTDIR)/lib/python/site-packages)
$(INSTDIR)/config: | $(INSTDIR)
	$(AT)$(if $(wildcard $(INSTDIR)/config),,mkdir $(INSTDIR)/config)
$(INSTDIR)/include: | $(INSTDIR)
	$(AT)$(if $(wildcard $(INSTDIR)/include),,mkdir $(INSTDIR)/include)
