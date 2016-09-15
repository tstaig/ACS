MOD_NAME:=acs
MOD_PATH:=..
include ../include/acsNewMakefile.mk
$(eval $(call genModule,$(MOD_NAME),$(MOD_PATH)))
