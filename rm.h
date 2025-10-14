#ifndef TARGET_H
#define TARGET_H

#include <systemc>
#include <tlm>
#include <tlm_utils/simple_initiator_socket.h>
#include <tlm_utils/simple_target_socket.h>
#include "custom_data.h"
#include "output_struct.h"
#include "debug.h"

#include <iostream> // for coloring

using namespace tlm_utils;
using namespace tlm;
using namespace sc_core;
using namespace std;

SC_MODULE(RM)
{
    simple_target_socket<RM> socket;
    simple_initiator_socket<RM> socket_comparator; // New socket

    SC_CTOR(RM) : socket("socket"), socket_comparator("socket_comparator")
    {
        socket.register_b_transport(this, &RM::b_transport);
    }

    void b_transport(tlm_generic_payload & trans, sc_time & delay)
    {
        if (trans.get_command() == tlm::TLM_IGNORE_COMMAND)
        {
            trans.set_response_status(tlm::TLM_OK_RESPONSE);
            return;
        }
        auto *buffer = trans.get_data_ptr();
        auto data = CustomData::deserialize(buffer);

        if constexpr (DEBUG_TLM)
        {
            std::cout << sc_time_stamp() << " |     RM     | TLM | Received: " << data << std::endl;
        }

        trans.set_response_status(tlm::TLM_OK_RESPONSE);
        
        // 🔴 DUMMY REFERENCE MODEL - AUTO-GENERATED 🔴
        // This is a placeholder RM. Replace with actual logic!
        
        // Initialize dummy outputs (dynamically generated from OutputStruct)
        int32_t value = 0;

        OutputStruct output;
        output.value = value;
        send_to_comparator(output);
    } 

    void send_to_comparator(const OutputStruct &output);
};

#endif
