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
#include "TimespecUtils.h"

#include <stdint.h>
#include <stdexcept>
#include <sstream>
#include <syslog.h>

#include "corbaNotifyTest_ifC.h"

void printUsage(const std::string &errMsg="") 
{

	if(errMsg.size() > 0)
	{
		std::cout << std::endl << "\tERROR: " << errMsg << std::endl << std::endl;
	}

	std::cout << "\tUSAGE: pDataConsummer -c channel -r IOR -d maxDelaySec" << std::endl;
	std::cout << "\t\tchannel: the ID of the notification channel or the path where the channel ID is stored" << std::endl;
	std::cout << "\t\tIOR: the IOR of the Notify Service" << std::endl;
	std::cout << "\t\tmaxDelaySec: maximum delay allowed in seconds" << std::endl << std::endl;
	exit(1);
}

void getParams(int argc,char *argv[],CosNotifyChannelAdmin::ChannelID &channelID,std::string &iorNS,double &maxDelaySec)
	 
{
	int c;
	std::string channel;
	std::string sdelay;

	channelID = -1;
	iorNS = "";
	maxDelaySec = 0;

	while((c = getopt(argc, argv, "c:r:d:")) != -1)
	{
		switch(c)
		{
		case 'c':
			channel = optarg;

			if(channel.find_first_not_of("0123456789") != std::string::npos)
			{
				std::ifstream f(channel.c_str());
				if(f.is_open() == true)
				{
					std::string sch;
					std::getline(f, sch);
					f.close();
					try {
						channelID = atoi(sch.c_str());

					} catch(...) {
						printUsage("Wrong channel ID: " + sch);
					}
				} else {
					printUsage("Wrong channel ID file: " + channel);
				}
			} else {
				channelID = atoi(channel.c_str());
			}
			break;
		case 'r':
			iorNS = optarg;
			break;
		case 'd':
			sdelay = optarg;
			if(sdelay.find_first_not_of("0123456789.") != std::string::npos)
			{
				printUsage("Wrong delay. Must be a number");
			} else {
				maxDelaySec = atof(sdelay.c_str());
			}
			break;
		default:
			printUsage("Unknown option: " + std::string(1, c));
			break;
		}
	}

	if(channelID == -1)
	{
		printUsage("A channel ID is required");
	}

	if(iorNS.size() <= 0)
	{
		printUsage("IOR of the Notify Service is required");
	}
}


int main(int argc, char *argv[])
{
	CosNotifyChannelAdmin::ChannelID channelID;
	std::string iorNS;
	double maxDelaySec;
	getParams(argc, argv, channelID, iorNS, maxDelaySec);

	Consumer consumer(maxDelaySec);
	consumer.run(argc, argv, channelID, iorNS);

	ACE_DEBUG((LM_INFO, "Consumer ends ...\n"));
	return EXIT_SUCCESS;
 }

Consumer::Consumer()
{
	TimespecUtils::set_timespec(m_tLastEvent, 0, 0);
	TimespecUtils::set_timespec(m_maxDelay, 0, 0);
	m_lastEventTimestamp = 0;
}

Consumer::Consumer(double maxDelaySec)
{
	TimespecUtils::set_timespec(m_tLastEvent, 0, 0);
	TimespecUtils::double_2_timespec(maxDelaySec, m_maxDelay);
	ACE_DEBUG((LM_INFO, "Max delay: %s s\n", TimespecUtils::timespec_2_str(m_maxDelay).c_str()));
	m_lastEventTimestamp = 0;
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
			ACE_DEBUG((LM_ERROR, "Error: %s", errMsg.c_str()));
			return false;
		}

		consumer_admin = channel->for_consumers ();
		supplier = consumer_admin->obtain_push_supplier ();
		consumer = this->_this ();
		supplier->connect_push_consumer (consumer.in ());

		// Wait for events, using work_pending()/perform_work() may help
		// or using another thread, this example is too simple for that.
		ACE_DEBUG((LM_INFO, "Waiting for events in channel %d ...\n", channelID));
		m_orb->run ();

	} catch(CORBA::Exception &ex) {
		ex._tao_print_exception ("Consumer::run");
	} catch(std::exception &stdEx) {
		ACE_ERROR((LM_ERROR, (std::string("Consumer::run exception: ") + stdEx.what() + "\n").c_str()));
	} catch(...) {
		ACE_ERROR((LM_ERROR, "Unknown exception in Consumer::run\n"));
	}

	return true;
}

void Consumer::push (const CORBA::Any &event)
{
	ACS::Time tsDiff;
	timespec tConsumerDiff;
	timespec tSupplierDiff;
	timespec tEvent;

	benchmark::MountStatusData *data;
	if(event >>= data)
	{
		// Calculate current event time
		TimespecUtils::get_current_timespec(tEvent);

		// Check the delay of the current event
		if(m_tLastEvent.tv_sec > 0 || m_tLastEvent.tv_nsec > 0)
		{
			tConsumerDiff = TimespecUtils::diff_timespec(tEvent, m_tLastEvent);
			tsDiff = data->timestamp - m_lastEventTimestamp;
			TimespecUtils::ns100_2_timespec(tsDiff, tSupplierDiff);

			if(m_maxDelay.tv_sec > 0 || m_maxDelay.tv_nsec > 0)
			{
				//uint64_t maxDelay100ns = TimespecUtils::timespec_2_100ns(m_maxDelay);
				if(m_maxDelay < tSupplierDiff)
				{
					//std::cout << "tSupplierDiff: " << tSupplierDiff.tv_sec << " " << tSupplierDiff.tv_nsec << std::endl;
					ACE_DEBUG((LM_NOTICE, "%T Event received %s with supplier delay %s but maximum allowed is %s s\n", 
						data->antennaName.in(), TimespecUtils::timespec_2_str(tSupplierDiff).c_str(), 
						TimespecUtils::timespec_2_str(m_maxDelay).c_str()));
				}

				if(m_maxDelay < tConsumerDiff)
				{
					ACE_DEBUG((LM_NOTICE, "%T Event received %s with consumer delay %s but maximum allowed is %s s\n", 
						data->antennaName.in(), TimespecUtils::timespec_2_str(tConsumerDiff).c_str(), 
						TimespecUtils::timespec_2_str(m_maxDelay).c_str()));
				}
			} else {
				ACE_DEBUG((LM_INFO, "%T Event received: %s with supplier delay %s s and consumer delay %s s\n", 
					data->antennaName.in(), 
					TimespecUtils::timespec_2_str(tSupplierDiff).c_str(),
					TimespecUtils::timespec_2_str(tConsumerDiff).c_str()));
			}
		}

		// Update last event received time
		TimespecUtils::set_timespec(m_tLastEvent, tEvent.tv_sec, tEvent.tv_nsec);
		m_lastEventTimestamp = data->timestamp;

	} else {
		ACE_DEBUG((LM_WARNING, "Event received but it's not of type MountStatusData\n"));
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
