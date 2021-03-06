#! /usr/bin/env python
#*******************************************************************************
# ALMA - Atacama Large Millimiter Array
# (c) National Research Council of Canada, 2007 
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
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
#
# "@(#) $Id: acspyTestUnitBaciHelper.py,v 1.1.1.1 2012/03/07 17:40:45 acaproni Exp $"
#
# who       when      what
# --------  --------  ----------------------------------------------
# agrimstr  2007-08-28  created
#

#------------------------------------------------------------------------------
__revision__ = "$Id: acspyTestUnitBaciHelper.py,v 1.1.1.1 2012/03/07 17:40:45 acaproni Exp $"
#--REGULAR IMPORTS-------------------------------------------------------------
import unittest
import mock
#--ACS IMPORTS____-------------------------------------------------------------
import Acspy.Util.BaciHelper as BaciHelper
from acspytest__POA import PyBaciTest
from maciErrTypeImpl import CannotGetComponentExImpl
from Acspy.Servants.CharacteristicComponent import CharacteristicComponent as cc
from Acspy.Servants.ContainerServices import ContainerServices as services
from Acspy.Servants.ComponentLifecycle import ComponentLifecycle as lcycle
from ACSImpl.DevIO import DevIO


#------------------------------------------------------------------------------

class AddPropertyCheck(unittest.TestCase):
    """Tests of the addProperty() method."""

    def setUp(self):
        mockIFR = mock.Mock({"lookup_id" : None })
        self.IFR = BaciHelper.IFR
        BaciHelper.IFR = mockIFR
        self.victim = PyBaciTestImpl()

    def tearDown(self):
        BaciHelper.IFR = self.IFR

    def testMockIFR(self):
        """Ensure that the mock interface repository is working correctly."""
        self.assertEqual(None, BaciHelper.IFR.lookup_id("Foo"))

    def testFailedIFRLookup(self):
        """Raise CannotGetComponentExImpl if it cannot get the property type"""
        self.assertRaises(CannotGetComponentExImpl, BaciHelper.addProperty, 
                          self.victim, "Foo")

    def testAddIDLDefinedProperty(self):
        """Ensure it adds a property defined in the IDL interface"""
        BaciHelper.addProperty(self.victim, 'doubleROProp')

    def testAddUserDefinedEnumProperty(self):
        """Ensure it adds a defined enum property"""
        BaciHelper.addProperty(self.victim, 'blarROProp')

    def testInheritedProperty(self):
        """Ensure it can look-up a property inherited from a base class"""
        # The property commonProp is defined in the PyCommonBaciTest IDL 
        # interface, and PyBaciTest interface inherits from PyCommonBaciTest
        BaciHelper.addProperty(self.victim, 'commonProp')


class PyBaciTestImpl(PyBaciTest, cc, services, lcycle):

    def __init__(self):
        cc.__init__(self)
        services.__init__(self)


class DummyDevIO(DevIO):

    def __init__(self, device, value=0):
        DevIO.__init__(self, value)

    def read(self):
        return self.value

    def write(self, value):
        self.value = value 


if __name__ == "__main__":
    unittest.main()


#
# ___oOo___
