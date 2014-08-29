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

#include "corbaNotifyTest_ifC.h"

#include "pDataSupplier.h"


void printUsage() {
	std::cout  << "USAGE: pDataSupplier sendInterval nItems channelName IOR" << std::endl;
	std::cout << "\tsendInterval: interval of time (msec) between 2 sends of a pData" << std::endl;
	std::cout << "\tnItems: number of items to send (0 means forever)" << std::endl;
	std::cout << "\tchannelName: the name of the notification channel" << std::endl;
	std::cout << "\tIOR: the IOR of the notify service" << std::endl << std::endl;
}

/**
 * TODOs:
 *    * Add the shutdown hook for a clean exit when CTRL+C is pressed
 */
int main(int argc, char *argv[])
{
	if (argc!=5) {
		std::cout << "Wrong command line!" <<std::endl;
		printUsage();
		exit(1);
	}
}

void DataSupplier::init_ORB (int argc,
                      char *argv []
                      )
{
  this->orb = CORBA::ORB_init (argc,  argv, "");


  CORBA::Object_ptr poa_object  =
    this->orb->resolve_initial_references("RootPOA");


  if (CORBA::is_nil (poa_object))
    {
      ACE_ERROR ((LM_ERROR, " (%P|%t) Unable to initialize the POA.\n"));
      return;
    }
  this->root_poa_ =
    PortableServer::POA::_narrow (poa_object);

  PortableServer::POAManager_var poa_manager =
    root_poa_->the_POAManager ();

  poa_manager->activate ();

}

void DataSupplier::shutdown () {
   // shutdown the ORB.
  if (!CORBA::is_nil (this->orb.in ()))
    {
      this->orb->shutdown(true);
      this->orb->destroy();
    }
}
