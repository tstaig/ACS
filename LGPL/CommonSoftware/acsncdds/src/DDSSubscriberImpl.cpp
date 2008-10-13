#include <DDSSubscriber.h>
#include <iostream>

using namespace ddsnc;

int DDSSubscriber::createSubscriber()
{
	std::cerr << "DDSSubscriber::createSubscriber" << std::endl;
	
	if(partitionName==NULL){
		sub=participant->create_subscriber(SUBSCRIBER_QOS_DEFAULT,
				DDS::SubscriberListener::_nil());
		std::cerr << "Creating Subscriber with default Qos" << std::endl;
	}

	else{
		 sub = participant->create_subscriber(sub_qos,
				 DDS::SubscriberListener::_nil());
		 std::cerr << "Creating Subscriber with partition: " << partitionName
			 << std::endl;
	}

	if ((CORBA::is_nil (sub.in ()))) {
		std::cerr << "create_subscriber failed." << std::endl;
		return 1;
	}
	
	sub_impl=dynamic_cast<OpenDDS::DCPS::SubscriberImpl*>(sub.in());
	if (0 == sub_impl) {
		std::cerr << "Failed to obtain publisher servant" << std::endl;
		return 1;
	}
	return attachToTransport();
}


int DDSSubscriber::attachToTransport()
{
	OpenDDS::DCPS::AttachStatus status = 
		sub_impl->attach_transport(transport_impl.in());
      if (status != OpenDDS::DCPS::ATTACH_OK) {
        std::string status_str;
        switch (status) {
        case OpenDDS::DCPS::ATTACH_BAD_TRANSPORT:
          status_str = "ATTACH_BAD_TRANSPORT";
          break;
        case OpenDDS::DCPS::ATTACH_ERROR:
          status_str = "ATTACH_ERROR";
          break;
        case OpenDDS::DCPS::ATTACH_INCOMPATIBLE_QOS:
          status_str = "ATTACH_INCOMPATIBLE_QOS";
          break;
        default:
          status_str = "Unknown Status";
          break;
        }
		  std::cerr << "Failed to attach to the transport. Status == "
          << status_str.c_str() << std::endl;
        return 1;
      }
	return 0;
}

