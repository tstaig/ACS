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
WISH:=/alma/ACS-2015.8/tcltk/bin/wish -f
TCL_CHECKER:=/alma/ACS-2015.8/tcltk/bin/tclCheck
PRJTOP:=$(INSTDIR)

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
#ALL_TARGETS=$(ALL_TARGETS) $9/lib/lib$1.so
$(eval $1_libs:=$2)
$(eval $1_objs:=$3)
$(foreach obj,$3,$(eval $(obj)_cflags:=$4))
$(eval $1_ldflags:=$5)
$(eval $1_target:=$8_$1_lib)
$(eval $1_path:=$9/lib/lib$1.so)
.PHONY: $8_$1_lib
$8_$1_lib: $9/lib/lib$1.so
	$(AT)
$9/lib/lib$1.so: $(foreach obj,$3,$9/object/$(obj).o) $(foreach lib,$2,$(if $($(lib)_target),$($(lib)_path),-l$(lib))) | $9/lib
	$(AT)g++ $(LDFLAGS) $5 -L $9/lib -shared $(foreach lib,$2,$(if $($(lib)_target),$($(lib)_path),-l$(lib))) $(foreach obj,$3,$9/object/$(obj).o) -o $9/lib/lib$1.so
$(eval $(call genTargets,$8_$1_lib,$9/lib/lib$1.so,lib,lib$1.so,$6,$(foreach obj,$3,$8_$1_$(obj)_obj),,$8_$1_lib))
$(foreach obj,$3,$(eval $(call cleanFiles,$8_$1_$(obj)_obj,$9/object/$(obj).o,object,$(obj).o)))
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
#ALL_TARGETS=$(ALL_TARGETS) $9/bin/$1
$(foreach obj,$3,$(eval $(obj)_cflags:=$4))
.PHONY: $7_$1_exe
$8_$1_exe: $9/bin/$1
	$(AT)
$9/bin/$1: $(foreach obj,$3,$9/object/$(obj).o) $(foreach lib,$2,$(if $($(lib)_target),$($(lib)_path),-l$(lib))) | $9/bin
	$(AT)g++ $(LDFLAGS) $5 -L $7/lib -o $9/bin/$1 $(foreach obj,$3,$9/object/$(obj).o) $(foreach lib,$2,$(if $($(lib)_target),$($(lib)_path),-l$(lib)))
$(eval $(call genTargets,$8_$1_exe,$9/bin/$1,bin,$1,$6,$(foreach obj,$3,$8_$1_$(obj)_obj),,$8_$1_exe))
$(foreach obj,$3,$(eval $(call cleanFiles,$8_$1_$(obj)_obj,$9/object/$(obj).o,object,$(obj).o)))
endef

#makeScripts: Makes targets for scripts, both local and installable.
#1: Script Name
#2: Bool to Install or Not
#3: Module to Make
#4: Module Full Name
#5: Module Relative Path
define makeScripts
$(eval $1_target:=$4_$1_scr)
$(eval $1_path:=$5/bin/$1)
#ALL_TARGETS=$(ALL_TARGETS) $5/bin/$1
$4_$1_scr: $5/bin/$1
	$(AT)
$5/bin/$1: $5/src/$1 | $5/bin
	$(AT)cp $5/src/$1 $5/bin/$1
	$(AT)chmod +x $5/bin/$1
$(eval $(call genTargets,$4_$1_scr,$5/bin/$1,bin,$1,$2,,,$4_$1_scr))
endef

#makePyScripts: Makes targets for Python scripts, both local and installable.
#1: Python Script Name
#2: Bool to Install or Not
#3: Module to Make
#4: Module Full Name
#5: Module Relative Path
define makePyScripts
#ALL_TARGETS=$(ALL_TARGETS) $5/bin/$1
$4_$1_pys: $5/bin/$1
	$(AT)
$5/bin/$1: $5/src/$1.py | $5/bin
	$(AT)cp $5/src/$1.py $5/bin/$1
	$(AT)chmod +x $5/bin/$1
$(eval $(call genTargets,$4_$1_pys,$5/bin/$1,bin,$1,$2,,,$4_$1_pys))
endef

#makeTclScripts: Makes targets for TCL scripts, both local and installable.
#1: TCL Script Name
#2: Bool to Install or Not
#3: Module to Make
#4: Module Full Name
#5: Module Relative Path
define makeTclScripts
#ALL_TARGETS=$(ALL_TARGETS) $5/bin/$1
$4_$1_tsc: $5/bin/$1
	$(AT)
$5/bin/$1: $(addsuffix .tcl,$($1_OBJECTS)) $(if $(acsMakeTclScript_target),$(acsMakeTclScript_path),) | $5/bin
	$(AT)$(if $(acsMakeTclScript_target),$(acsMakeTclScript_path),acsMakeTclScript) "$(TCL_CHECKER)" "$(WISH)" "$($1_TCLSH)" "$1" "$($1_OBJECTS)" "$($1_LIBS)"
	$(AT)chmod +x $5/bin/$1
$(eval $(call genTargets,$4_$1_tsc,$5/bin/$1,bin,$1,$2,,,$4_$1_tsc))
endef

#makeTclLibraries: Makes targets for TCL libraries, both local and installable.
#1: TCL Library Name
#2: Bool to Install or Not
#3: Module to Make
#4: Module Full Name
#5: Module Relative Path
define makeTclLibraries
#ALL_TARGETS=$(ALL_TARGETS) $5/lib/$1
$4_$1_tlb: $5/lib/$1.tcl
	$(AT)
$5/lib/$1.tcl: $(addsuffix .tcl,$($1_OBJECTS)) $(if $(acsMakeTclLib_target),$(acsMakeTclScript_path),) | $5/bin
	$(AT)$(if $(acsMakeTclLib_target),$(acsMakeTclScript_path),acsMakeTclLib) "$(TCL_CHECKER)"  "$1" "$($1_OBJECTS)" 
$(eval $(call genTargets,$4_$1_tlb,$5/lib/$1.tcl,lib,$1.tcl,$2,,,$4_$1_tlb))
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
#INSTALL_TARGETS=$(INSTALL_TARGETS) install_$1
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
#CLEAN_TARGETS=$(CLEAN_TARGETS) clean_$1
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
#CLEANDIST_TARGETS=$(CLEANDIST_TARGETS) clean_dist_$1
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
$4_$1_pym: $5/lib/python/site-packages/$1.pyc
	$(AT)
$5/lib/python/site-packages/$1.pyc: $5/lib/python/site-packages/$1.py
	$(AT)python -m compileall $5/lib/python/site-packages/$1.py
$5/lib/python/site-packages/$1.py: $5/src/$1.py | $5/lib/python/site-packages
	$(AT)cp $5/src/$1.py $5/lib/python/site-packages/$1.py
$(eval $(call genTargets,$4_$1_pym,$5/lib/python/site-packages/$1.py,lib/python/site-packages,$1.py,$2,$4_$1_pym_pyc,true,$4_$1_pym))
$(eval $(call genTargets,$4_$1_pym_pyc,$5/lib/python/site-packages/$1.pyc,lib/python/site-packages,$1.pyc,$2))
endef

#1: Python Package Name
#2: Bool to Install or Not
#3: Module to Make
#4: Module Full Name
#5: Module Relative Path
define makePyPackages
$4_$1_pyp: $(patsubst %.py,%.pyc,$(subst $5/src/$1,$5/lib/python/site-packages/$1,$(wildcard $5/src/$1/*.py)))
	$(AT)
$5/lib/python/site-packages/$1/%.pyc: $5/lib/python/site-packages/$1/%.py
	$(AT)python -m compileall $$?
$5/lib/python/site-packages/$1/%.py: $5/src/$1/%.py | $5/lib/python/site-packages/$1
	$(AT)cp $$? $$@
$5/lib/python/site-packages/$1: $5/src/$1 | $5/lib/python/site-packages
	$(AT)$(if $(wildcard $5/lib/python/site-packages/$1),,mkdir $5/lib/python/site-packages/$1)
.PHONY: clean_$4_$1_pyp install_$4_$1_pyp clean_dist_$4_$1_pyp
clean_$4_$1_pyp: $(foreach py,$(subst $5/src/,,$(wildcard $5/src/$1/*.py)),clean_$4_$1_$(subst $1/,_,$(py)))
	$(AT)
clean_dist_$4_$1_pyp: $(foreach py,$(subst $5/src/,,$(wildcard $5/src/$1/*.py)),clean_dist_$4_$1_$(subst $1/,_,$(py)))
	$(AT)
install_$4_$1_pyp: $4_$1 | $(INSTDIR)/lib/python/site-packages/$1 $(foreach py,$(subst $5/src/,,$(wildcard $5/src/$1/*.py)),install_$4_$1_$(subst $1/,_,$(py)))
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
$4_$1_inc: $5/include/$1
	$(AT)
clean_$4_$1_inc: $5/include/$1
	$(AT)
$(eval $(call installFiles,$4_$1_inc,$5/include/$1,include,$1))
$(eval $(call cleanDistFiles,$4_$1_inc,$5/include/$1,include,$1))
endef

#1: Install File Name
#2: Bool to Install or Not
#3: Module to Make
#4: Module Full Name
#5: Module Relative Path
define makeInstallFiles
$(eval ins_path:=$(patsubst ../%/,%,$(dir $1)))
$(eval ins_file:=$(notdir $1))
$(warning XXXXXXXXXXXXXXXXXX: $4_$1_ins)
$4_$1_ins: $5/$(ins_path)/$(ins_file)
	$(AT)
clean_$4_$1_ins: $5/$(ins_path)/$(ins_file)
	$(AT)
$(eval $(call installFiles,$4_$1_ins,$5/$(ins_path)/$(ins_file),$(ins_path),$(ins_file)))
$(eval $(call cleanDistFiles,$4_$1_ins,$5/$(ins_file)/$(ins_path),$(ins_path),$(ins_file)))
endef

#1: Config File Name
#2: Bool to Install or Not
#3: Module to Make
#4: Module Full Name
#5: Module Relative Path
define makeConfigs
$4_$1_cfg: $5/config/$1
	$(AT)
clean_$4_$1_cfg: $5/config/$1
	$(AT)
$(eval $(call installFiles,$4_$1_cfg,$5/config/$1,config,$1))
$(eval $(call cleanDistFiles,$4_$1_cfg,$5/config/$1,config,$1))
endef

#1: List of targets
#2: Module Full Name
#3: All/Clean
#4: Install/Clean_Dist
#5: Suffix for targets
define addTargets
$(if $3,$(if $1,$(eval ALL_TARGETS+=$(addsuffix _$5,$(addprefix $2_,$1)))$(eval CLEAN_TARGETS+=$(addsuffix _$5,$(addprefix clean_$2_,$1))),),)
$(if $4,$(if $1,$(eval INSTALL_TARGETS+=$(addsuffix _$5,$(addprefix install_$2_,$1)))$(eval CLEAN_DIST_TARGETS+=$(addsuffix _$5,$(addprefix clean_dist_$2_,$1))),),)
endef

#makeModule: Iterates over the lists of targets to make local and installable libraries, executables, scripts, etc. to create build, install and clean targets.
#1: Module to Make
#2: Module Full Name
#3: Module Relative Path
define makeModule
$(eval ALL_TARGETS:=)
$(eval CLEAN_TARGETS:=)
$(eval INSTALL_TARGETS:=)
$(eval CLEAN_DIST_TARGETS:=)
$(foreach lib,$($2_LIBRARIES),$(eval $(call makeLibraries,$(lib),$($(lib)_LIBS),$($(lib)_OBJECTS),$($(lib)_CFLAGS),$($(lib)_LDFLAGS),true,$1,$2,$3)))
$(eval $(call addTargets,$($2_LIBRARIES),$2,true,true,lib))
$(foreach lib,$($2_LIBRARIES_L),$(eval $(call makeLibraries,$(lib),$($(lib)_LIBS),$($(lib)_OBJECTS),$($(lib)_CFLAGS),$($(lib)_LDFLAGS),false,$1,$2,$3)))
$(eval $(call addTargets,$($2_LIBRARIES_L),$2,true,false,lib))
$(foreach exe,$($2_EXECUTABLES),$(eval $(call makeExecutables,$(exe),$($(exe)_LIBS),$($(exe)_OBJECTS),$($(exe)_CFLAGS),$($(exe)_LDFLAGS),true,$1,$2,$3)))
$(eval $(call addTargets,$($2_EXECUTABLES),$2,true,true,exe))
$(foreach exe,$($2_EXECUTABLES_L),$(eval $(call makeExecutables,$(exe),$($(exe)_LIBS),$($(exe)_OBJECTS),$($(exe)_CFLAGS),$($(exe)_LDFLAGS),false,$1,$2,$3)))
$(eval $(call addTargets,$($2_EXECUTABLES_L),$2,true,false,exe))
$(foreach scr,$($2_SCRIPTS),$(eval $(call makeScripts,$(scr),true,$1,$2,$3)))
$(eval $(call addTargets,$($2_SCRIPTS),$2,true,true,scr))
$(foreach scr,$($2_SCRIPTS_L),$(eval $(call makeScripts,$(scr),false,$1,$2,$3)))
$(eval $(call addTargets,$($2_SCRIPTS_L),$2,true,false,scr))
$(foreach pys,$($2_PY_SCRIPTS),$(eval $(call makePyScripts,$(pys),true,$1,$2,$3)))
$(eval $(call addTargets,$($2_PY_SCRIPTS),$2,true,true,pys))
$(foreach pys,$($2_PY_SCRIPTS_L),$(eval $(call makePyScripts,$(pys),false,$1,$2,$3)))
$(eval $(call addTargets,$($2_PY_SCRIPTS_L),$2,true,false,pys))
$(foreach pym,$($2_PY_MODULES),$(eval $(call makePyModules,$(pym),true,$1,$2,$3)))
$(eval $(call addTargets,$($2_PY_MODULES),$2,true,true,pym))
$(foreach pym,$($2_PY_MODULES_L),$(eval $(call makePyModules,$(pym),false,$1,$2,$3)))
$(eval $(call addTargets,$($2_PY_MODULES_L),$2,true,false,pym))
$(foreach pyp,$($2_PY_PACKAGES),$(eval $(call makePyPackages,$(pyp),true,$1,$2,$3)))
$(eval $(call addTargets,$($2_PY_PACKAGES),$2,true,true,pyp))
$(foreach pyp,$($2_PY_PACKAGES_L),$(eval $(call makePyPackages,$(pyp),false,$1,$2,$3)))
$(eval $(call addTargets,$($2_PY_PACKAGES_L),$2,true,false,pyp))
$(foreach tsc,$($2_TCL_SCRIPTS),$(eval $(call makeTclScripts,$(tsc),true,$1,$2,$3)))
$(eval $(call addTargets,$($2_TCL_SCRIPTS),$2,true,true,tsc))
$(foreach tsc,$($2_TCL_SCRIPTS_L),$(eval $(call makeTclScripts,$(tsc),false,$1,$2,$3)))
$(eval $(call addTargets,$($2_TCL_SCRIPTS_L),$2,true,false,tsc))
$(foreach tlb,$($2_TCL_LIBRARIES),$(eval $(call makeTclLibraries,$(tlb),true,$1,$2,$3)))
$(eval $(call addTargets,$($2_TCL_LIBRARIES),$2,true,true,tlb))
$(foreach tlb,$($2_TCL_LIBRARIES_L),$(eval $(call makeTclLibraries,$(tlb),false,$1,$2,$3)))
$(eval $(call addTargets,$($2_TCL_LIBRARIES_L),$2,true,false,tlb))
$(foreach inc,$($2_INCLUDES),$(eval $(call makeIncludes,$(inc),true,$1,$2,$3)))
$(eval $(call addTargets,$($2_INCLUDES),$2,false,true,inc))
$(foreach cfg,$($2_CONFIGS),$(eval $(call makeConfigs,$(cfg),true,$1,$2,$3)))
$(eval $(call addTargets,$($2_CONFIGS),$2,false,true,cfg))
$(foreach ins,$($2_INSTALL_FILES),$(eval $(call makeInstallFiles,$(ins),true,$1,$2,$3)))
$(eval $(call addTargets,$($2_INSTALL_FILES),$2,false,true,ins))
#(warning ALL_TARGETS: $(ALL_TARGETS))
#(warning CLEAN_TARGETS: $(CLEAN_TARGETS))
#(warning INSTALL_TARGETS: $(INSTALL_TARGETS))
#(warning CLEAN_DIST_TARGETS: $(CLEAN_DIST_TARGETS))

$2: $(ALL_TARGETS)
clean_$2: $(CLEAN_TARGETS)
install_$2: $(INSTALL_TARGETS)
clean_dist_$2: $(CLEAN_DIST_TARGETS)


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
$(eval ALL_TARGETS:=)
$(eval CLEAN_TARGETS:=)
$(eval INSTALL_TARGETS:=)
$(eval CLEAN_DIST_TARGETS:=)
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
$(eval $(call makeModule,$1,$2_$1,$3/$1))
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
$(eval $(call makeModule,$1,$1,..,))
$(eval $(call cleanModuleVars,$1))
endef

#1: Module Target
define storeModuleVars
$(eval $1_LIBRARIES:=$(strip $(LIBRARIES)))
$(eval $1_LIBRARIES_L:=$(strip $(LIBRARIES_L)))
$(eval $1_EXECUTABLES:=$(strip $(EXECUTABLES)))
$(eval $1_EXECUTABLES_L:=$(strip $(EXECUTABLES_L)))
$(eval $1_SCRIPTS:=$(strip $(SCRIPTS)))
$(eval $1_SCRIPTS_L:=$(strip $(SCRIPTS_L)))
$(eval $1_PY_SCRIPTS:=$(strip $(PY_SCRIPTS)))
$(eval $1_PY_SCRIPTS_L:=$(strip $(PY_SCRIPTS_L)))
$(eval $1_PY_MODULES:=$(strip $(PY_MODULES)))
$(eval $1_PY_MODULES_L:=$(strip $(PY_MODULES_L)))
$(eval $1_PY_PACKAGES:=$(strip $(PY_PACKAGES)))
$(eval $1_PY_PACKAGES_L:=$(strip $(PY_PACKAGES_L)))
$(eval $1_TCL_SCRIPTS:=$(strip $(TCL_SCRIPTS)))
$(eval $1_TCL_SCRIPTS_L:=$(strip $(TCL_SCRIPTS_L)))
$(eval $1_INCLUDES:=$(strip $(INCLUDES)))
$(eval $1_CONFIGS:=$(strip $(CONFIGS)))
$(eval $1_INSTALL_FILES:=$(strip $(INSTALL_FILES)))
endef

#1: Module Target
define cleanModuleVars
$(eval $1_LIBRARIES:=)
$(eval $1_LIBRARIES_L:=)
$(eval $1_EXECUTABLES:=)
$(eval $1_EXECUTABLES_L:=)
$(eval $1_SCRIPTS:=)
$(eval $1_SCRIPTS_L:=)
$(eval $1_PY_SCRIPTS:=)
$(eval $1_PY_SCRIPTS_L:=)
$(eval $1_PY_MODULES:=)
$(eval $1_PY_MODULES_L:=)
$(eval $1_PY_PACKAGES:=)
$(eval $1_PY_PACKAGES_L:=)
$(eval $1_TCL_SCRIPTS:=)
$(eval $1_TCL_SCRIPTS_L:=)
$(eval $1_INCLUDES:=)
$(eval $1_CONFIGS:=)
$(eval $1_INSTALL_FILES:=)
endef

define cleanModuleIncludeVars
$(eval LIBRARIES:=)
$(eval LIBRARIES_L:=)
$(eval EXECUTABLES:=)
$(eval EXECUTABLES_L:=)
$(eval SCRIPTS:=)
$(eval SCRIPTS_L:=)
$(eval PY_SCRIPTS:=)
$(eval PY_SCRIPTS_L:=)
$(eval PY_MODULES:=)
$(eval PY_MODULES_L:=)
$(eval PY_PACKAGES:=)
$(eval PY_PACKAGES_L:=)
$(eval TCL_SCRIPTS:=)
$(eval TCL_SCRIPTS_L:=)
$(eval INCLUDES:=)
$(eval CONFIGS:=)
$(eval INSTALL_FILES:=)
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
