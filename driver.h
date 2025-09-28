// driver.h (updated)
#ifndef INITIATOR_H
#define INITIATOR_H

#include <systemc>
#include <tlm>
#include <tlm_utils/simple_initiator_socket.h>
#include "custom_data.h"
#include "debug.h"
#include <iostream>

SC_MODULE(Driver)
{
    // Two initiator sockets: one for RM, one for Transactor
    tlm_utils::simple_initiator_socket<Driver> socket_rm;
    tlm_utils::simple_initiator_socket<Driver> socket_transactor;

    sc_core::sc_fifo_in<CustomData> in;

    SC_CTOR(Driver) : socket_rm("socket_rm"), socket_transactor("socket_transactor")
    {
        SC_THREAD(process);
    }

    void process()
    {
        while (true)
        {
            CustomData data = in.read();
            auto buffer = data.serialize();

            // Prepare transaction (we'll reuse the same payload for both)
            tlm::tlm_generic_payload trans;
            trans.set_data_ptr(buffer.data());
            trans.set_data_length(buffer.size());
            trans.set_command(tlm::TLM_WRITE_COMMAND);
            trans.set_streaming_width(buffer.size());
            trans.set_byte_enable_ptr(nullptr);
            trans.set_dmi_allowed(false);
            trans.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

            sc_core::sc_time delay_rm = sc_core::SC_ZERO_TIME;
            sc_core::sc_time delay_trans = sc_core::SC_ZERO_TIME;

            if constexpr (DEBUG_TLM)
            {
                std::cout << sc_core::sc_time_stamp() << " |   Driver   | TLM | Driving:  " << data << std::endl;
            }

            // Send to RM
            socket_rm->b_transport(trans, delay_rm);
            if (trans.is_response_error())
            {
                SC_REPORT_ERROR("Driver", "Write to RM failed");
            }

            // Reset response status for second transaction (good practice)
            trans.set_response_status(tlm::TLM_INCOMPLETE_RESPONSE);

            // Send to Transactor
            socket_transactor->b_transport(trans, delay_trans);
            if (trans.is_response_error())
            {
                SC_REPORT_ERROR("Driver", "Write to Transactor failed");
            }

            std::cout << "\033[1;32m=======================\033[0m" << "\033[1;34m Test Finished \033[0m" << "\033[1;32m========================\033[0m" << std::endl;

        }
    }
};

#endif // INITIATOR_H