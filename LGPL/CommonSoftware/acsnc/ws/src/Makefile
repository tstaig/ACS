#*************************************************************************
# ALMA - Atacama Large Millimiter Array
# (c) Associated Universities Inc., 2002  
# (c) European Southern Observatory, 2002
# Copyright by ESO (in the framework of the ALMA collaboration),
# All rights reserved
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, 
# MA 02111-1307  USA
#
#*******************************************************************************
# "@(#) $Id: Makefile,v 1.70 2012/01/21 22:48:11 tstaig Exp $"
#------------------------------------------------------------------------
#
# Makefile for acsnc/ws/src

# user definable C-compilation flags
USER_CFLAGS =
USER_LIB    =

DEBUG=on

# C programs (public and local)
# -----------------------------
EXECUTABLES     = 
EXECUTABLES_L   = 

# Includes (.h) files (public only)
# ---------------------------------
INCLUDES = 	acsncHelper.h acsncSupplier.h acsncConsumer.h \
            acsncORBHelper.h \
            acsncSimpleSupplier.i acsncSimpleSupplier.h \
            acsncSimpleConsumer.i acsncSimpleConsumer.h \
            acsncRTSupplier.i acsncRTSupplier.h \
            acsncArchiveConsumer.h \
            acsncCDBProperties.h \
            acsncReconnectionCallback.h \
            acsncCircularQueue.h acsncBlockingQueue.h acsncBlockingQueue.i

INCLUDES_L	= 

# Libraries (public and local)
# ----------------------------
LIBRARIES       = acsnc
LIBRARIES_L     =

acsnc_OBJECTS  = acsncCDBProperties \
                 acsncArchiveConsumer \
                 acsncORBHelperImpl acsncHelperImpl \
                 acsncConsumerImpl acsncSimpleConsumerImpl \
                 acsncSupplierImpl acsncSimpleSupplierImpl acsncRTSupplierImpl \
                 acsncReconnectionCallback acsncCircularQueue

acsnc_LIBS     = pthread rt ACSErrTypeCommon acsncStubs acsncErrType AcsNCTraceLogLTS logging RepeatGuard acstime maci maciClient basenc TAO_CosNotification_MC_Ext


# list of all possible C-sources (used to create automatic dependencies)
# ------------------------------
CSOURCENAMES = \
	$(foreach exe, $(EXECUTABLES) $(EXECUTABLES_L), $($(exe)_OBJECTS)) \
	$(foreach lib, $(LIBRARIES) $(LIBRARIES_L), $($(lib)_OBJECTS))



# IDL Files
IDL_FILES = 
USER_IDL  = 

#
# On-Line Database Files
# ----------------------
CDB_SCHEMAS = Channels EventChannel

#
# Java Entity Classes generation on/off
#
XSDBIND = acsncSchemaBindings


#>>>>> END OF standard rules

#
# INCLUDE STANDARDS
# -----------------
MAKEDIRTMP := $(shell searchFile include/acsMakefile)
ifneq ($(MAKEDIRTMP),\#error\#)
   MAKEDIR := $(MAKEDIRTMP)/include
   include $(MAKEDIR)/acsMakefile
endif


#
# TARGETS
# -------
all:	do_all
	@echo " . . . 'all' done" 

clean : clean_all 
	$(RM) *~ ../include/*~ ../idl/*~ ../*~ ../../*~ core*
	@echo " . . . clean done"

clean_dist : clean clean_dist_all 
	@echo " . . . clean done"

man   : do_man 
	@echo " . . . man page(s) done"

install : install_all
	@echo " . . . installation done"
