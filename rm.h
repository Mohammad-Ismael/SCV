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
        int32_t y = calculate_y(data.rst_n, data.en, data.op, data.a, data.b, data.carry_in, data.sat_enable, data.cmp_mode, data.shift_amt);
        bool carry_out = calculate_carry_out(data.rst_n, data.en, data.op, data.a, data.b, data.carry_in, data.sat_enable, data.cmp_mode, data.shift_amt);
        bool zero = calculate_zero(data.rst_n, data.en, data.op, data.a, data.b, data.carry_in, data.sat_enable, data.cmp_mode, data.shift_amt);
        bool negative = calculate_negative(data.rst_n, data.en, data.op, data.a, data.b, data.carry_in, data.sat_enable, data.cmp_mode, data.shift_amt);
        bool cmp_out = calculate_cmp_out(data.rst_n, data.en, data.op, data.a, data.b, data.carry_in, data.sat_enable, data.cmp_mode, data.shift_amt);

        OutputStruct output;
        output.y = static_cast<int32_t>(y);
        output.carry_out = static_cast<bool>(carry_out);
        output.zero = static_cast<bool>(zero);
        output.negative = static_cast<bool>(negative);
        output.cmp_out = static_cast<bool>(cmp_out);
        send_to_comparator(output);
    } 
    int32_t calculate_y(bool rst_n, bool en, int32_t op, int32_t a, int32_t b, bool carry_in, bool sat_enable, int32_t cmp_mode, int32_t shift_amt);
    int32_t calculate_carry_out(bool rst_n, bool en, int32_t op, int32_t a, int32_t b, bool carry_in, bool sat_enable, int32_t cmp_mode, int32_t shift_amt);
    int32_t calculate_zero(bool rst_n, bool en, int32_t op, int32_t a, int32_t b, bool carry_in, bool sat_enable, int32_t cmp_mode, int32_t shift_amt);
    int32_t calculate_negative(bool rst_n, bool en, int32_t op, int32_t a, int32_t b, bool carry_in, bool sat_enable, int32_t cmp_mode, int32_t shift_amt);
    int32_t calculate_cmp_out(bool rst_n, bool en, int32_t op, int32_t a, int32_t b, bool carry_in, bool sat_enable, int32_t cmp_mode, int32_t shift_amt);
    void send_to_comparator(const OutputStruct &output);
};

#endif