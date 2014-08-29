/*******************************************************************************
* ALMA - Atacama Large Millimiter Array
* Copyright (c) European Southern Observatory, 2014 
* 
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version.
* 
* This library is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* Lesser General Public License for more details.
* 
* You should have received a copy of the GNU Lesser General Public
* License along with this library; if not, write to the Free Software
* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
*
*
* who       when      what
* --------  --------  ----------------------------------------------
* almadev  2014-08-28  created 
*/

#include <orbsvcs/CosEventCommS.h>
#include <orbsvcs/CosEventChannelAdminC.h>

int main(int argc, char *argv[])
{
 // Initialize the ORB.
  CORBA::ORB_var orb = CORBA::ORB_init(argc, argv, "whatever");

  CORBA::Object_var poa_object = orb->resolve_initial_references ("RootPOA");

  orb->destroy ();
   return EXIT_SUCCESS;
 }
