LIBRARIES:=
LIBRARIES_L:=
EXECUTABLES:=
EXECUTABLES_L:=
SCRIPTS:= acsMakeTclScript	acsMakeTclLib acsMan doxygenize acsChangeEnv \
		acsSwitchEnv instAlmaTarball JacPrep acsCheckGroupPermissions \
      cvs2cl acsUserConfig acsMakeCheckUnresolvedSymbols acsMakeJavaClasspath \
		acsMakeCopySources acsMakeLogInstallation acsMakeInstallFiles searchFile
SCRIPTS_L:=
PY_SCRIPTS:= acsConfigReport acsGetAllJars acsGetSpecificJars acsSearchPath
PY_SCRIPTS_L:=
PY_MODULES:= acsSearchPath
PY_MODULES_L:=
PY_PACKAGES:=
PY_PACKAGES_L:=
TCL_SCRIPTS:=acsReplace
acsReplace_OBJECTS:=acsReplace
acsReplace_TCLSH:=tcl
TCL_SCRIPTS_L:=
INCLUDES:=acsPort.h
CONFIGS:=
INSTALL_FILES:= ../include/acsMakefile ../include/acsNewMakefile.mk \
      ../include/acsMakefileDefinitions.mk ../include/acsMakefileCore.mk \
      ../include/Makefile_LCU.template ../include/Makefile_WS.template \
      ../include/Makefile_PACKAGE.template $(wildcard ../config/acsPackageInfo*.rpmref) \
		../config/XSDIncludeDependencies.xml


###############
###############
#Unsupported!
###############
###############

#PY_PACKAGES        =    acsConfigReportModule
#PY_PACKAGES_L      =
#pppppp_MODULES     =

MANSECTIONS = 1 5 n
MAN1 = acsMan acsConfigReport.py
MAN5 = ../include/acsMakefile Makefile.doc
MANn = acsReplace.tcl
MANl = $(SCRIPTS)

$(MODRULE)all: $(MODDEP) do_acsPort
	$(AT)echo " . . . $(MODRULE)all done"

$(MODRULE)install: install_$(MODDEP)
	$(AT)cp ../include/Makefile_PACKAGE.template \
           ../include/Makefile_LCU.template \
           ../include/Makefile_WS.template    $(PRJTOP)/include
	$(AT)(cd $(PRJTOP)/include; rm -f vltPort.h; ln -s acsPort.h vltPort.h)
	$(AT)echo " . . . $(MODRULE)install done"

$(MODRULE)clean: clean_$(MODDEP)
	-$(AT) cp ../include/acsPort.h.DUMMY ../include/acsPort.h
	$(AT)echo " . . . $(MODRULE)clean done"

$(MODRULE)clean_dist: clean_dist_$(MODDEP)
	$(AT)echo " . . . $(MODRULE)clean_dist done"

man   : do_man
	@echo " . . . man page(s) done"

do_acsPort:
	-$(AT) chmod 666   ../include/acsPort.h; cp ../include/acsPort.h.UNSUPPORTED ../include/acsPort.h; chmod 666   ../include/acsPort.h
	-$(AT) if [ "`uname`" = "Linux" ]; then cp ../include/acsPort.h.Linux ../include/acsPort.h; chmod 666 ../include/acsPort.h; fi
	-$(AT) if [ "`uname`" = "$(CYGWIN_VER)" ]; then cp ../include/acsPort.h.Cygwin ../include/acsPort.h; chmod 666 ../include/acsPort.h; fi
