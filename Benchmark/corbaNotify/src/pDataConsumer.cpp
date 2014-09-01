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
#include "pDataConsumer.h"

#include <stdint.h>
#include <stdexcept>
#include <sstream>

#include "corbaNotifyTest_ifC.h"

void printUsage() {
	std::cout  << "USAGE: pDataConsummer channelID IOR" << std::endl;
	std::cout << "\tchannelID: the number id of the notification channel" << std::endl;
	std::cout << "\tIOR: the IOR of the notify service" << std::endl << std::endl;
	exit(1);
}

void getParams(int argc,char *argv[],CosNotifyChannelAdmin::ChannelID &channelID,std::string &iorNS)
	 
{
	if (argc!=3) {
		std::cout << "Wrong command line!" <<std::endl;
		printUsage();
	}

	try {
		channelID = atoi(argv[1]);
	} catch(...) {
		std::cout << "Wrong channelID value" << std::endl;
		printUsage();
	}

	iorNS = argv[2];
}


int main(int argc, char *argv[])
{
	CosNotifyChannelAdmin::ChannelID channelID;
	std::string iorNS;
	getParams(argc, argv, channelID, iorNS);

	Consumer consumer;
	consumer.run(argc, argv, channelID, iorNS);

	std::cout << "The consumer ends ..." << std::endl;
	return EXIT_SUCCESS;
 }

Consumer::Consumer()
{
}

bool Consumer::run (int argc, ACE_TCHAR* argv[],CosNotifyChannelAdmin::ChannelID channelID,
		    const std::string &iorNS)
{
	try {
		std::string errMsg;
		if(init_ORB(argc, argv) == false)
		{
			return false;	
		}

		CosNotifyChannelAdmin::EventChannel_var channel;
		CosEventChannelAdmin::ConsumerAdmin_var consumer_admin;
		CosEventChannelAdmin::ProxyPushSupplier_var supplier;
		CosEventComm::PushConsumer_var consumer;

		if(getNotificationChannel(iorNS,channelID,channel,errMsg) == false)
		{
			ACE_DEBUG((LM_DEBUG, "Error: %s", errMsg.c_str()));
			return false;
		}

		consumer_admin = channel->for_consumers ();
		supplier = consumer_admin->obtain_push_supplier ();
		consumer = this->_this ();
		supplier->connect_push_consumer (consumer.in ());

		// Wait for events, using work_pending()/perform_work() may help
		// or using another thread, this example is too simple for that.
		std::cout << "Waiting for events in channel " << channelID 
			  << " ..." << std::endl;
		m_orb->run ();

	} catch(CORBA::Exception &ex) {
		ex._tao_print_exception ("Consumer::run");
	} catch(std::exception &stdEx) {
		ACE_ERROR((LM_ERROR, (std::string("Consumer::run exception: ") + stdEx.what()).c_str()));
	} catch(...) {
		ACE_ERROR((LM_ERROR, "Unknown exception in Consumer::run\n"));
	}

	return true;
}

void Consumer::push (const CORBA::Any &event)
{
	benchmark::MountStatusData *data;
	if(event >>= data)
	{
		ACE_DEBUG((LM_DEBUG, "Event received: %s\n", data->antennaName.in()));
	} else {
		ACE_DEBUG((LM_DEBUG, "Event received but it's not of type MountStatusData\n"));
	}
}

void Consumer::offer_change(const CosNotification::EventTypeSeq&, const CosNotification::EventTypeSeq&)
{
}

void Consumer::disconnect_push_consumer (void)
{
	m_orb->shutdown(0);
}

bool Consumer::init_ORB(int argc, ACE_TCHAR* argv[])
{
	m_orb = CORBA::ORB_init(argc, argv, "");

	CORBA::Object_var poa_object = m_orb->resolve_initial_references ("RootPOA");

	if (CORBA::is_nil (poa_object))
	{
		ACE_ERROR ((LM_ERROR, " (%P|%t) Unable to initialize the POA.\n"));
		return false;
	}

	PortableServer::POA_var root_poa = PortableServer::POA::_narrow (poa_object);

	PortableServer::POAManager_var poa_manager = root_poa->the_POAManager ();
	poa_manager->activate ();

	return true;
}


bool Consumer::getNotificationChannel(const std::string &iorNS,
		CosNotifyChannelAdmin::ChannelID channelID,
		CosNotifyChannelAdmin::EventChannel_var &channel,
		std::string &errMsg)
{
	try {
// Get the Notification Channel Factory
		CORBA::Object_var obj = m_orb->string_to_object(iorNS.c_str());

		CosNotifyChannelAdmin::EventChannelFactory_var ecf
		  = CosNotifyChannelAdmin::EventChannelFactory::_narrow(obj.in());

		if (CORBA::is_nil(ecf.in()))
		{
			errMsg = "Unable to get the Notification Channel Factory";
			return false;
		}

// Get the channel
		channel = ecf->get_event_channel(channelID);
		if(CORBA::is_nil(channel.in()))
		{
			std::ostringstream oss;
			oss << "Unable to get the channel " << channelID;
			errMsg = oss.str();
			return false;
		}

	} catch(CosNotifyChannelAdmin::ChannelNotFound &ex) {
		std::ostringstream oss;
		oss << "Unable to get the channel " << channelID;
		errMsg = oss.str();
		return false;
	}	

	errMsg = "";
	return true;
}
